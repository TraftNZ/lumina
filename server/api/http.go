package api

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"log"
	"mime"
	"net/http"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

func (a *api) SetHttpPort(port int) {
	a.httpPort = port
}

func (a *api) HttpHandler() http.Handler {
	return http.HandlerFunc(a.httpHandler)
}

func (a *api) httpHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		if strings.HasPrefix(r.URL.Path, "/trash/thumbnail/") {
			a.httpDownloadTrashThumbnail(w, r)
		} else if strings.HasPrefix(r.URL.Path, "/locked/thumbnail/") {
			a.httpDownloadLockedThumbnail(w, r)
		} else if strings.HasPrefix(r.URL.Path, "/thumbnail/") {
			a.httpDownloadThumbnail(w, r)
		} else {
			a.httpDownload(w, r)
		}
	case http.MethodPost:
		if strings.HasPrefix(r.URL.Path, "/thumbnail/") {
			a.httpUploadThumbnail(w, r)
		} else {
			a.httpUpload(w, r)
		}
	}
}

func (a *api) httpUpload(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path
	if path == "" {
		w.WriteHeader(http.StatusNotFound)
		return
	}
	if r.ContentLength == 0 {
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	date := r.Header.Get("Image-Date")
	dateTime, err := time.Parse("2006:01:02 15:04:05", date)
	if err != nil {
		dateTime = time.Now()
	}
	name := strings.TrimPrefix(path, "/")
	// Use client-provided hash or compute from body
	contentHash := r.Header.Get("Content-Hash")
	var body io.Reader = r.Body
	length := r.ContentLength
	if contentHash == "" {
		// Must buffer to compute hash
		data, readErr := io.ReadAll(r.Body)
		if readErr != nil {
			w.WriteHeader(http.StatusBadRequest)
			w.Write([]byte(readErr.Error()))
			return
		}
		h := sha256.Sum256(data)
		contentHash = hex.EncodeToString(h[:])
		body = bytes.NewReader(data)
		length = int64(len(data))
	}
	encoded := encodeName(dateTime, name, contentHash)
	if isVideo(path) {
		err = a.im.UploadVideo(body, nil, length, 0, encoded, dateTime)
	} else {
		err = a.im.UploadImg(body, nil, length, 0, encoded, dateTime)
	}
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(err.Error()))
		return
	}
	r.Body.Close()
	w.WriteHeader(http.StatusOK)
}

func (a *api) httpUploadThumbnail(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path
	if path == "" {
		w.WriteHeader(http.StatusNotFound)
		return
	}
	if r.ContentLength == 0 {
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	name := strings.TrimPrefix(path, "/thumbnail/")
	date := r.Header.Get("Image-Date")
	dateTime, err := time.Parse("2006:01:02 15:04:05", date)
	if err != nil {
		dateTime = time.Now()
	}
	thumbData, err := io.ReadAll(r.Body)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(err.Error()))
		return
	}
	r.Body.Close()
	// Use Content-Hash from original photo (passed by client)
	contentHash := r.Header.Get("Content-Hash")
	encodedName := encodeName(dateTime, name, contentHash)
	err = a.im.UploadImg(nil, bytes.NewReader(thumbData), 0, int64(len(thumbData)), encodedName, dateTime)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(err.Error()))
		return
	}
	if store := a.im.Store(); store != nil {
		thumbPath := filepath.Join(dateTime.Format("2006/01/02"), encodedName)
		go store.PutThumb(thumbPath, thumbData)
	}
	w.WriteHeader(http.StatusOK)
}

func (a *api) httpDownload(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path
	if path == "" {
		w.WriteHeader(http.StatusNotFound)
		return
	}
	contentType := mime.TypeByExtension(filepath.Ext(path))
	rangeHeader := r.Header.Get("Range")
	if rangeHeader != "" {
		rangeHeader = strings.TrimSpace(rangeHeader)
		kv := strings.Split(rangeHeader, "=")
		if len(kv) != 2 || kv[0] != "bytes" {
			http.Error(w, "bad range", http.StatusBadRequest)
			return
		}
		parts := strings.Split(kv[1], "-")
		if len(parts) == 0 {
			http.Error(w, "bad range", http.StatusBadRequest)
			return
		}
		start, err := strconv.ParseInt(parts[0], 10, 64)
		if err != nil {
			http.Error(w, "bad range", http.StatusBadRequest)
			return
		}
		img, err := a.im.GetOffset(path, start)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer img.Content.Close()
		var readLen int64 = img.Size - start
		end := img.Size - 1
		if len(parts) > 1 && parts[1] != "" {
			end, err = strconv.ParseInt(parts[1], 10, 64) // 解析 end 部分
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			if end > img.Size-1 {
				end = img.Size - 1
			}
			readLen = end - start + 1
		}
		w.Header().Add("Content-Type", contentType)
		w.Header().Add("Content-Length", strconv.FormatInt(readLen, 10))
		w.Header().Add("Content-Range", fmt.Sprintf("bytes %d-%d/%d", start, end, img.Size))
		w.WriteHeader(http.StatusPartialContent)
		_, err = io.CopyN(w, img.Content, readLen)
		if err != nil {
			log.Printf("Error copying image content: %v", err)
			return
		}
		return
	}

	img, err := a.im.GetImg(path)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(err.Error()))
		return
	}
	defer img.Content.Close()
	w.Header().Add("Content-Length", strconv.FormatInt(img.Size, 10))
	w.Header().Add("Content-Type", contentType)
	w.WriteHeader(http.StatusOK)
	_, err = io.Copy(w, img.Content)
	if err != nil {
		w.Write([]byte(err.Error()))
		return
	}
}

func (a *api) httpDownloadThumbnail(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path
	if path == "" {
		w.WriteHeader(http.StatusNotFound)
		return
	}
	realPath := strings.TrimPrefix(path, "/thumbnail")
	data, err := a.im.GetCachedThumbnail(realPath)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(err.Error()))
		return
	}
	contentType := mime.TypeByExtension(filepath.Ext(realPath))
	w.Header().Set("Content-Length", strconv.Itoa(len(data)))
	w.Header().Set("Content-Type", contentType)
	w.Write(data)
}

func (a *api) httpDownloadTrashThumbnail(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path
	if path == "" {
		w.WriteHeader(http.StatusNotFound)
		return
	}
	realPath := strings.TrimPrefix(path, "/trash/thumbnail/")
	img, err := a.im.GetTrashThumbnail(realPath)
	if err != nil {
		// Fallback: try to get the full image from trash
		img, err = a.im.GetImg(filepath.Join(".trash", realPath))
		if err != nil {
			w.WriteHeader(http.StatusNotFound)
			w.Write([]byte(err.Error()))
			return
		}
	}
	contentType := mime.TypeByExtension(filepath.Ext(realPath))
	defer img.Content.Close()
	w.Header().Add("Content-Length", strconv.FormatInt(img.Size, 10))
	w.Header().Add("Content-Type", contentType)
	w.WriteHeader(http.StatusOK)
	_, err = io.Copy(w, img.Content)
	if err != nil {
		w.Write([]byte(err.Error()))
		return
	}
}

func (a *api) httpDownloadLockedThumbnail(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path
	if path == "" {
		w.WriteHeader(http.StatusNotFound)
		return
	}
	realPath := strings.TrimPrefix(path, "/locked/thumbnail/")
	img, err := a.im.GetLockedThumbnail(realPath)
	if err != nil {
		// Fallback: try to get the full image from locked
		img, err = a.im.GetImg(filepath.Join(".locked", realPath))
		if err != nil {
			w.WriteHeader(http.StatusNotFound)
			w.Write([]byte(err.Error()))
			return
		}
	}
	contentType := mime.TypeByExtension(filepath.Ext(realPath))
	defer img.Content.Close()
	w.Header().Add("Content-Length", strconv.FormatInt(img.Size, 10))
	w.Header().Add("Content-Type", contentType)
	w.WriteHeader(http.StatusOK)
	_, err = io.Copy(w, img.Content)
	if err != nil {
		w.Write([]byte(err.Error()))
		return
	}
}

// encodeName builds a filename with 24-hour timestamp + content hash prefix + original name.
// Format: YYYYMMDDHHmmss_<hash16>_<name>
func encodeName(t time.Time, name string, contentHash string) string {
	if contentHash != "" && len(contentHash) >= 16 {
		return fmt.Sprintf("%s_%s_%s", t.Format("20060102150405"), contentHash[:16], name)
	}
	// Fallback when no hash available: use 24-hour format without hash segment
	return fmt.Sprintf("%s_%s", t.Format("20060102150405"), name)
}

// legacyEncodeName preserves the old format (12-hour clock, no hash) for backwards compat lookups.
func legacyEncodeName(t time.Time, name string) string {
	return fmt.Sprintf("%s_%s", t.Format("20060102030405"), name)
}

func decodeName(encoded string) (time.Time, string, error) {
	parts := strings.SplitN(encoded, "_", 3)
	if len(parts) == 3 && len(parts[0]) == 14 && len(parts[1]) == 16 {
		// New format: timestamp_hash16_name
		t, err := time.Parse("20060102150405", parts[0])
		if err != nil {
			return time.Time{}, "", err
		}
		return t, parts[2], nil
	}
	// Legacy format: timestamp_name (12-hour or 24-hour)
	if len(encoded) < 15 {
		return time.Time{}, "", fmt.Errorf("invalid encoded name")
	}
	timeStr := encoded[:14]
	name := encoded[15:]
	t, err := time.Parse("20060102150405", timeStr)
	if err != nil {
		// Try legacy 12-hour format
		t, err = time.Parse("20060102030405", timeStr)
		if err != nil {
			return time.Time{}, "", err
		}
	}
	return t, name, nil
}
