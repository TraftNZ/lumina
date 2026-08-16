package imgmanager

import (
	"errors"
	"io"
	"io/fs"
	"testing"
	"time"

	"github.com/traftai/lumina/server/localstore"
)

type smartBackendStub struct {
	files []localstore.RemoteFile
	err   error
}

func (s *smartBackendStub) Upload(string, io.ReadCloser, int64, time.Time) error {
	return nil
}

func (s *smartBackendStub) Download(string) (io.ReadCloser, int64, error) {
	return nil, 0, errors.New("unused")
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
	return nil, errors.New("unused")
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
