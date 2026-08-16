package imgmanager

import (
	"bytes"
	"errors"
	"image"
	"image/color"
	"image/jpeg"
	"io"
	"io/fs"
	"testing"
	"time"

	"github.com/traftai/lumina/server/localstore"
)

type smartBackendStub struct {
	files          []localstore.RemoteFile
	err            error
	thumbnailData  []byte
	thumbnailErr   error
	thumbnailCalls int
	downloads      map[string][]byte
	downloadCalls  []string
}

func (s *smartBackendStub) Upload(string, io.ReadCloser, int64, time.Time) error {
	return nil
}

func (s *smartBackendStub) Download(path string) (io.ReadCloser, int64, error) {
	s.downloadCalls = append(s.downloadCalls, path)
	data, ok := s.downloads[path]
	if !ok {
		return nil, 0, errors.New("not found")
	}
	return io.NopCloser(bytes.NewReader(data)), int64(len(data)), nil
}

func (s *smartBackendStub) DownloadWithOffset(string, int64) (io.ReadCloser, int64, error) {
	return nil, 0, errors.New("unused")
}

func (s *smartBackendStub) Delete(string) error {
	return nil
}

func (s *smartBackendStub) Rename(string, string) error {
	return nil
}

func (s *smartBackendStub) Range(string, func(fs.FileInfo) bool) error {
	return nil
}

func (s *smartBackendStub) ListPhotos() ([]localstore.RemoteFile, error) {
	if s.err != nil {
		return nil, s.err
	}
	return append([]localstore.RemoteFile(nil), s.files...), nil
}

func (s *smartBackendStub) GetThumbnail(string) ([]byte, error) {
	s.thumbnailCalls++
	return s.thumbnailData, s.thumbnailErr
}

type rangeBackendStub struct{}

func (s *rangeBackendStub) Upload(string, io.ReadCloser, int64, time.Time) error {
	return nil
}

func (s *rangeBackendStub) Download(string) (io.ReadCloser, int64, error) {
	return nil, 0, errors.New("unused")
}

func (s *rangeBackendStub) DownloadWithOffset(string, int64) (io.ReadCloser, int64, error) {
	return nil, 0, errors.New("unused")
}

func (s *rangeBackendStub) Delete(string) error {
	return nil
}

func (s *rangeBackendStub) Rename(string, string) error {
	return nil
}

func (s *rangeBackendStub) Range(dir string, deal func(fs.FileInfo) bool) error {
	switch dir {
	case ".":
		deal(stubFileInfo{name: "2025", dir: true})
	case "2025":
		deal(stubFileInfo{name: "01", dir: true})
	case "2025/01":
		return errors.New("nested listing failed")
	}
	return nil
}

type stubFileInfo struct {
	name string
	dir  bool
}

func (s stubFileInfo) Name() string       { return s.name }
func (s stubFileInfo) Size() int64        { return 0 }
func (s stubFileInfo) Mode() fs.FileMode  { return 0 }
func (s stubFileInfo) ModTime() time.Time { return time.Time{} }
func (s stubFileInfo) IsDir() bool        { return s.dir }
func (s stubFileInfo) Sys() any           { return nil }

func newSmartBackendManager(t *testing.T, backend *smartBackendStub) *ImgManager {
	t.Helper()
	store, err := localstore.New(t.TempDir())
	if err != nil {
		t.Fatalf("create local store: %v", err)
	}
	t.Cleanup(func() { _ = store.Close() })

	manager := NewImgManager(Option{WorkerNum: 1, LocalStore: store})
	if err := manager.SwitchDrive(backend, "smart-backend-test"); err != nil {
		t.Fatalf("switch drive: %v", err)
	}
	return manager
}

func testJPEG(t *testing.T) []byte {
	t.Helper()
	img := image.NewRGBA(image.Rect(0, 0, 8, 8))
	for y := 0; y < 8; y++ {
		for x := 0; x < 8; x++ {
			img.Set(x, y, color.RGBA{R: uint8(x * 30), G: uint8(y * 30), B: 80, A: 255})
		}
	}
	var encoded bytes.Buffer
	if err := jpeg.Encode(&encoded, img, nil); err != nil {
		t.Fatalf("encode source jpeg: %v", err)
	}
	return encoded.Bytes()
}

func TestSmartBackendThumbnailFailureFallsBackToOriginal(t *testing.T) {
	const path = "2020/01/12/old.jpg"
	backend := &smartBackendStub{
		thumbnailErr: errors.New("thumb API returned empty URL"),
		downloads:    map[string][]byte{path: testJPEG(t)},
	}
	manager := newSmartBackendManager(t, backend)

	got, err := manager.GetCachedThumbnail(path)
	if err != nil {
		t.Fatalf("generate fallback thumbnail: %v", err)
	}
	if len(got) == 0 {
		t.Fatal("fallback thumbnail is empty")
	}
	if backend.thumbnailCalls != 1 {
		t.Fatalf("smart thumbnail calls = %d, want 1", backend.thumbnailCalls)
	}
	if manager.Store().IsThumbFailed(path) {
		t.Fatal("successful fallback left a thumbnail failure row")
	}

	downloadsAfterFallback := len(backend.downloadCalls)
	if _, err := manager.GetCachedThumbnail(path); err != nil {
		t.Fatalf("read locally cached fallback thumbnail: %v", err)
	}
	if len(backend.downloadCalls) != downloadsAfterFallback {
		t.Fatal("cached fallback thumbnail downloaded the original again")
	}
}

func TestSmartBackendPoisonedThumbnailRecoversFromOriginal(t *testing.T) {
	const path = "2012/01/13/old.jpg"
	backend := &smartBackendStub{
		thumbnailErr: errors.New("must skip poisoned smart thumbnail"),
		downloads:    map[string][]byte{path: testJPEG(t)},
	}
	manager := newSmartBackendManager(t, backend)
	manager.Store().MarkThumbFailed(path)

	if _, err := manager.GetCachedThumbnail(path); err != nil {
		t.Fatalf("recover poisoned thumbnail: %v", err)
	}
	if backend.thumbnailCalls != 0 {
		t.Fatalf("poisoned path retried smart backend %d times", backend.thumbnailCalls)
	}
	if manager.Store().IsThumbFailed(path) {
		t.Fatal("successful recovery did not clear thumbnail failure")
	}
}

func TestSmartBackendSyncReplacesStaleRows(t *testing.T) {
	backend := &smartBackendStub{
		files: []localstore.RemoteFile{{Path: "2025/01/01/old.jpg"}},
	}
	manager := newSmartBackendManager(t, backend)

	if _, err := manager.SyncIndex(); err != nil {
		t.Fatalf("seed index: %v", err)
	}
	backend.files = []localstore.RemoteFile{{Path: "2026/02/03/new.jpg"}}
	if _, err := manager.SyncIndex(); err != nil {
		t.Fatalf("replace index: %v", err)
	}

	files := manager.ListFromIndex()
	if len(files) != 1 || files[0].Path != "2026/02/03/new.jpg" {
		t.Fatalf("expected only the new remote row, got %#v", files)
	}
}

func TestFullResyncPreservesCacheWhenListingFails(t *testing.T) {
	backend := &smartBackendStub{
		files: []localstore.RemoteFile{{Path: "2025/01/01/cached.jpg"}},
	}
	manager := newSmartBackendManager(t, backend)

	if _, err := manager.SyncIndex(); err != nil {
		t.Fatalf("seed index: %v", err)
	}
	backend.err = errors.New("remote unavailable")
	if _, err := manager.FullResyncIndex(); err == nil {
		t.Fatal("expected full resync to fail")
	}

	files := manager.ListFromIndex()
	if len(files) != 1 || files[0].Path != "2025/01/01/cached.jpg" {
		t.Fatalf("expected cached row to survive, got %#v", files)
	}
}

func TestFullResyncPreservesCacheOnNestedTraversalError(t *testing.T) {
	store, err := localstore.New(t.TempDir())
	if err != nil {
		t.Fatalf("create local store: %v", err)
	}
	t.Cleanup(func() { _ = store.Close() })
	if err := store.SwitchDrive("range-backend-test"); err != nil {
		t.Fatalf("switch store: %v", err)
	}
	store.UpsertRemoteFiles([]localstore.RemoteFile{{
		Path: "2024/12/31/cached.jpg",
	}})

	manager := NewImgManager(Option{WorkerNum: 1, LocalStore: store})
	manager.SetDrive(&rangeBackendStub{})
	if _, err := manager.FullResyncIndex(); err == nil {
		t.Fatal("expected full resync to fail")
	}

	files := manager.ListFromIndex()
	if len(files) != 1 || files[0].Path != "2024/12/31/cached.jpg" {
		t.Fatalf("expected cached row to survive, got %#v", files)
	}
}
