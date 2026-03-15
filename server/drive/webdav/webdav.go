package webdav

import (
	"bytes"
	"crypto/tls"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"log"
	"math/rand/v2"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"syscall"
	"time"

	"github.com/studio-b12/gowebdav"
	"github.com/traftai/lumina/server/resolver"
)

const maxRetries = 5

type Webdav struct {
	url       string
	username  string
	password  string
	rootPath  string
	cli       *gowebdav.Client
	transport *http.Transport
	logger    *log.Logger
}

func NewWebdavDrive(url, username, password string) *Webdav {
	d := &Webdav{
		url:      url,
		username: username,
		password: password,
		logger:   log.New(os.Stdout, "[WebDAV] ", log.LstdFlags),
	}
	d.resetClient()
	return d
}

func (d *Webdav) newTransport() *http.Transport {
	return &http.Transport{
		TLSClientConfig:     &tls.Config{InsecureSkipVerify: true},
		MaxIdleConns:        10,
		MaxIdleConnsPerHost: 4,
		IdleConnTimeout:     30 * time.Second,
		DisableKeepAlives:   false,
		ForceAttemptHTTP2:   false,
		DialContext: resolver.NewDoHDialContext(&net.Dialer{
			Timeout:   15 * time.Second,
			KeepAlive: 30 * time.Second,
		}),
		TLSHandshakeTimeout:   10 * time.Second,
		ResponseHeaderTimeout: 5 * time.Minute,
	}
}

func (d *Webdav) resetClient() {
	if d.transport != nil {
		d.transport.CloseIdleConnections()
	}
	d.transport = d.newTransport()
	d.cli = gowebdav.NewClient(d.url, d.username, d.password)
	d.cli.SetTransport(d.transport)
}

// backoffWithJitter returns exponential backoff duration with ±25% random jitter.
// Base delays: 2s, 4s, 8s, 16s, 32s for attempts 1-5.
func backoffWithJitter(attempt int) time.Duration {
	base := time.Duration(1<<uint(attempt)) * 2 * time.Second
	jitter := time.Duration(float64(base) * (0.75 + rand.Float64()*0.5))
	return jitter
}

// isRetryable classifies whether an error is worth retrying.
func isRetryable(err error) bool {
	if err == nil {
		return false
	}
	msg := err.Error()

	// Non-retryable: configuration or auth errors
	if strings.Contains(msg, "root path is empty") ||
		strings.Contains(msg, "reader is nil") {
		return false
	}

	// Check for non-retryable HTTP status codes via gowebdav.StatusError
	var pathErr *os.PathError
	if errors.As(err, &pathErr) {
		var statusErr gowebdav.StatusError
		if errors.As(pathErr.Err, &statusErr) {
			switch statusErr.Status {
			case 401, 403, 404, 405, 409:
				return false
			case 423, 502, 503, 524:
				return true
			}
		}
	}

	// Retryable network errors
	var netErr net.Error
	if errors.As(err, &netErr) {
		return true
	}
	if errors.Is(err, syscall.ECONNRESET) || errors.Is(err, syscall.ECONNREFUSED) ||
		errors.Is(err, syscall.EPIPE) || errors.Is(err, io.EOF) ||
		errors.Is(err, io.ErrUnexpectedEOF) {
		return true
	}

	// Retryable string patterns for errors not wrapped properly
	retryablePatterns := []string{
		"connection reset",
		"broken pipe",
		"EOF",
		"timeout",
		"502",
		"524",
		"503",
		"423",
		"Locked",
		"Bad Gateway",
		"Gateway Timeout",
	}
	for _, p := range retryablePatterns {
		if strings.Contains(msg, p) {
			return true
		}
	}

	return false
}

func (d *Webdav) Cli() *gowebdav.Client {
	return d.cli
}

func (d *Webdav) IsRootPathSet() bool {
	return d.rootPath != ""
}

func (d *Webdav) SetRootPath(rootPath string) error {
	if rootPath == "" {
		return fmt.Errorf("root path is empty")
	}
	rootPath = filepath.ToSlash(rootPath)
	if rootPath[0] != '/' {
		rootPath = "/" + rootPath
	}
	if rootPath[len(rootPath)-1] != '/' {
		rootPath = rootPath + "/"
	}

	var lastErr error
	for attempt := 0; attempt < maxRetries; attempt++ {
		if attempt > 0 {
			if !isRetryable(lastErr) {
				return lastErr
			}
			d.resetClient()
			backoff := backoffWithJitter(attempt)
			d.logger.Printf("SetRootPath retry %d/%d after %v (last error: %v)", attempt, maxRetries-1, backoff, lastErr)
			time.Sleep(backoff)
		}
		info, err := d.cli.Stat(rootPath)
		if err != nil {
			if os.IsNotExist(err) {
				return fmt.Errorf("root path %s not exist", rootPath)
			}
			lastErr = err
			continue
		}
		if !info.IsDir() {
			return fmt.Errorf("root path %s is not a dir", rootPath)
		}
		d.rootPath = rootPath
		return nil
	}
	return lastErr
}

func (d *Webdav) IsExist(path string) (bool, error) {
	if d.rootPath == "" {
		return false, fmt.Errorf("root path is empty")
	}
	fullPath := filepath.Join(d.rootPath, path)
	_, err := d.cli.Stat(fullPath)
	if err != nil {
		if os.IsNotExist(err) {
			return false, nil
		}
		if pathErr, ok := err.(*os.PathError); ok {
			if statusErr, ok := pathErr.Err.(gowebdav.StatusError); ok && statusErr.Status == 404 {
				return false, nil
			}
		}
		return false, err
	}
	return true, nil
}

func (d *Webdav) Download(path string) (io.ReadCloser, int64, error) {
	if d.rootPath == "" {
		return nil, 0, fmt.Errorf("root path is empty")
	}
	fullPath := filepath.Join(d.rootPath, path)
	reader, err := d.cli.ReadStream(fullPath)
	if err != nil {
		return nil, 0, err
	}
	info, err := d.cli.Stat(fullPath)
	if err != nil {
		return nil, 0, err
	}
	return reader, info.Size(), nil
}

func (d *Webdav) Delete(path string) error {
	if d.rootPath == "" {
		return fmt.Errorf("root path is empty")
	}
	fullPath := filepath.Join(d.rootPath, path)
	err := d.cli.Remove(fullPath)
	if err != nil {
		return err
	}
	return nil
}

func (d *Webdav) DownloadWithOffset(path string, offset int64) (io.ReadCloser, int64, error) {
	if d.rootPath == "" {
		return nil, 0, fmt.Errorf("root path is empty")
	}
	fullPath := filepath.Join(d.rootPath, path)
	reader, err := d.cli.ReadStreamRange(fullPath, offset, -1)
	if err != nil {
		return nil, 0, err
	}
	info, err := d.cli.Stat(fullPath)
	if err != nil {
		return nil, 0, err
	}

	return reader, info.Size(), nil
}

func (d *Webdav) Upload(path string, reader io.ReadCloser, size int64, lastModified time.Time) error {
	if reader == nil {
		return fmt.Errorf("reader is nil")
	}
	defer reader.Close()
	if d.rootPath == "" {
		return fmt.Errorf("root path is empty")
	}

	data, err := io.ReadAll(reader)
	if err != nil {
		return fmt.Errorf("read upload data: %w", err)
	}

	fullPath := filepath.Join(d.rootPath, path)

	var lastErr error
	for attempt := 0; attempt < maxRetries; attempt++ {
		if attempt > 0 {
			if !isRetryable(lastErr) {
				return lastErr
			}
			d.resetClient()
			backoff := backoffWithJitter(attempt)
			d.logger.Printf("Upload retry %d/%d for %s (%d bytes) after %v (last error: %v)",
				attempt, maxRetries-1, path, len(data), backoff, lastErr)
			time.Sleep(backoff)
			_ = d.cli.Remove(fullPath)
		}

		if err := d.cli.MkdirAll(filepath.Dir(fullPath), 0755); err != nil {
			lastErr = err
			continue
		}
		if err := d.cli.WriteStream(fullPath, bytes.NewReader(data), 0666); err != nil {
			lastErr = err
			continue
		}

		// Verify upload by checking remote file size
		info, err := d.cli.Stat(fullPath)
		if err != nil {
			d.logger.Printf("Upload verify failed for %s: %v", path, err)
			lastErr = fmt.Errorf("upload verify stat: %w", err)
			continue
		}
		if info.Size() != int64(len(data)) {
			d.logger.Printf("Upload size mismatch for %s: expected %d, got %d", path, len(data), info.Size())
			lastErr = fmt.Errorf("upload size mismatch: expected %d, got %d", len(data), info.Size())
			_ = d.cli.Remove(fullPath)
			continue
		}

		return nil
	}
	return lastErr
}

func (d *Webdav) Rename(oldPath, newPath string) error {
	if d.rootPath == "" {
		return fmt.Errorf("root path is empty")
	}
	fullOld := filepath.Join(d.rootPath, oldPath)
	fullNew := filepath.Join(d.rootPath, newPath)
	if err := d.cli.MkdirAll(filepath.Dir(fullNew), 0755); err != nil {
		return err
	}
	return d.cli.Rename(fullOld, fullNew, true)
}

func (d *Webdav) Range(dir string, deal func(fs.FileInfo) bool) error {
	if d.rootPath == "" {
		return fmt.Errorf("root path is empty")
	}
	fullPath := filepath.Join(d.rootPath, dir)
	infos, err := d.cli.ReadDir(fullPath)
	if err != nil {
		return err
	}
	sort.Sort(desc(infos))
	for _, info := range infos {
		if !deal(info) {
			break
		}
	}
	return nil
}

type desc []fs.FileInfo

func (d desc) Len() int      { return len(d) }
func (d desc) Swap(i, j int) { d[i], d[j] = d[j], d[i] }
func (d desc) Less(i, j int) bool {
	return d[i].ModTime().After(d[j].ModTime())
}
