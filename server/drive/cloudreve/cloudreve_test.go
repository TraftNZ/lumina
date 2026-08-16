package cloudreve

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"
)

// receivedChunk is one byte range as the external storage server saw it.
type receivedChunk struct {
	url          string
	contentRange string
	body         []byte
}

// externalStorage stands in for the OneDrive upload session endpoint: it accepts
// sequential byte ranges and answers 202 until the final one, exactly as the
// resumable upload contract specifies.
type externalStorage struct {
	mu     sync.Mutex
	chunks []receivedChunk
}

func (e *externalStorage) handler(totalSize int64) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		body, _ := io.ReadAll(r.Body)
		e.mu.Lock()
		e.chunks = append(e.chunks, receivedChunk{
			url:          r.URL.Path,
			contentRange: r.Header.Get("Content-Range"),
			body:         body,
		})
		received := int64(0)
		for _, c := range e.chunks {
			received += int64(len(c.body))
		}
		e.mu.Unlock()

		if received >= totalSize {
			w.WriteHeader(http.StatusCreated)
			fmt.Fprint(w, `{"id":"1","name":"f","size":1,"file":{}}`)
			return
		}
		w.WriteHeader(http.StatusAccepted)
		fmt.Fprint(w, `{"nextExpectedRanges":["`+fmt.Sprint(received)+`-"]}`)
	}
}

func (e *externalStorage) assembled() []byte {
	e.mu.Lock()
	defer e.mu.Unlock()
	var out []byte
	for _, c := range e.chunks {
		out = append(out, c.body...)
	}
	return out
}

// newTestDrive wires a Cloudreve client to a stub API that issues the given
// upload URLs, and pre-seeds a token so requests skip the login flow.
func newTestDrive(t *testing.T, chunkSize int64, uploadURLs []string) *Cloudreve {
	t.Helper()

	api := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		if r.Method == "PUT" && strings.HasSuffix(r.URL.Path, "/api/v4/file/upload") {
			urls := ""
			for i, u := range uploadURLs {
				if i > 0 {
					urls += ","
				}
				urls += `"` + u + `"`
			}
			fmt.Fprintf(w, `{"code":0,"data":{"session_id":"sess","chunk_size":%d,`+
				`"upload_urls":[%s],"callback_secret":"secret",`+
				`"storage_policy":{"type":"onedrive"}}}`, chunkSize, urls)
			return
		}
		fmt.Fprint(w, `{"code":0,"data":{}}`)
	}))
	t.Cleanup(api.Close)

	d := NewCloudreveDrive(api.URL, "user@example.com", "pw")
	d.accessToken = "token"
	d.accessExp = time.Now().Add(time.Hour)
	d.refreshExp = time.Now().Add(24 * time.Hour)
	return d
}

func payload(size int64) []byte {
	b := make([]byte, size)
	for i := range b {
		b[i] = byte(i % 251)
	}
	return b
}

// A resumable session returns a single URL for the whole file. Every byte range
// has to go back to that same URL; indexing past it once dropped later chunks
// onto a different endpoint, which reported success for a truncated file.
func TestUploadReusesSingleURLForEveryChunk(t *testing.T) {
	const chunkSize = 1024
	const size = chunkSize*3 + 100 // 4 chunks, last one short

	ext := &externalStorage{}
	extSrv := httptest.NewServer(ext.handler(size))
	defer extSrv.Close()

	d := newTestDrive(t, chunkSize, []string{extSrv.URL + "/session"})

	src := payload(size)
	if err := d.Upload("2026/07/17/video.MOV", io.NopCloser(bytes.NewReader(src)), size, time.Now()); err != nil {
		t.Fatalf("Upload failed: %v", err)
	}

	if len(ext.chunks) != 4 {
		t.Fatalf("expected 4 chunks, got %d", len(ext.chunks))
	}
	for _, c := range ext.chunks {
		if c.url != "/session" {
			t.Errorf("chunk sent to %q, want the single session URL /session", c.url)
		}
	}

	wantRanges := []string{
		"bytes 0-1023/3172",
		"bytes 1024-2047/3172",
		"bytes 2048-3071/3172",
		"bytes 3072-3171/3172",
	}
	for i, want := range wantRanges {
		if ext.chunks[i].contentRange != want {
			t.Errorf("chunk %d Content-Range = %q, want %q", i, ext.chunks[i].contentRange, want)
		}
	}

	if got := ext.assembled(); !bytes.Equal(got, src) {
		t.Errorf("reassembled upload differs from source (%d bytes vs %d)", len(got), len(src))
	}
}

// Presigned-part policies hand back one URL per chunk; those must still be used
// in order rather than collapsing onto the first.
func TestUploadUsesPerChunkURLsWhenSupplied(t *testing.T) {
	const chunkSize = 1024
	const size = chunkSize * 3

	ext := &externalStorage{}
	extSrv := httptest.NewServer(ext.handler(size))
	defer extSrv.Close()

	d := newTestDrive(t, chunkSize, []string{
		extSrv.URL + "/part0",
		extSrv.URL + "/part1",
		extSrv.URL + "/part2",
	})

	src := payload(size)
	if err := d.Upload("2026/07/17/video.MOV", io.NopCloser(bytes.NewReader(src)), size, time.Now()); err != nil {
		t.Fatalf("Upload failed: %v", err)
	}

	if len(ext.chunks) != 3 {
		t.Fatalf("expected 3 chunks, got %d", len(ext.chunks))
	}
	for i, c := range ext.chunks {
		if want := fmt.Sprintf("/part%d", i); c.url != want {
			t.Errorf("chunk %d sent to %q, want %q", i, c.url, want)
		}
	}
	if got := ext.assembled(); !bytes.Equal(got, src) {
		t.Errorf("reassembled upload differs from source")
	}
}

// Several URLs but fewer than there are chunks is a response we cannot address,
// and must fail loudly instead of uploading part of the file.
func TestUploadRejectsInsufficientPerChunkURLs(t *testing.T) {
	const chunkSize = 1024
	const size = chunkSize * 5

	ext := &externalStorage{}
	extSrv := httptest.NewServer(ext.handler(size))
	defer extSrv.Close()

	d := newTestDrive(t, chunkSize, []string{extSrv.URL + "/part0", extSrv.URL + "/part1"})

	err := d.Upload("2026/07/17/video.MOV", io.NopCloser(bytes.NewReader(payload(size))), size, time.Now())
	if err == nil {
		t.Fatal("expected an error when upload URLs are fewer than chunks")
	}
	if !strings.Contains(err.Error(), "less than chunk count") {
		t.Errorf("unexpected error: %v", err)
	}
	if len(ext.chunks) != 0 {
		t.Errorf("no bytes should have been sent, got %d chunks", len(ext.chunks))
	}
}

// A file that fits in one chunk is streamed rather than buffered, so it takes a
// different path through Upload than the multi-chunk case above.
func TestUploadSingleChunkStreamsWholeFile(t *testing.T) {
	const chunkSize = 4096
	const size = 1000

	ext := &externalStorage{}
	extSrv := httptest.NewServer(ext.handler(size))
	defer extSrv.Close()

	d := newTestDrive(t, chunkSize, []string{extSrv.URL + "/session"})

	src := payload(size)
	if err := d.Upload("2026/07/17/photo.HEIC", io.NopCloser(bytes.NewReader(src)), size, time.Now()); err != nil {
		t.Fatalf("Upload failed: %v", err)
	}
	if len(ext.chunks) != 1 {
		t.Fatalf("expected 1 chunk, got %d", len(ext.chunks))
	}
	if want := "bytes 0-999/1000"; ext.chunks[0].contentRange != want {
		t.Errorf("Content-Range = %q, want %q", ext.chunks[0].contentRange, want)
	}
	if !bytes.Equal(ext.assembled(), src) {
		t.Error("reassembled upload differs from source")
	}
}
