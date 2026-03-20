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
		if r.URL.Path == "/fix-dates" {
			a.httpFixDates(w, r)
		} else if strings.HasPrefix(r.URL.Path, "/thumbnail/") {
			a.httpDownloadThumbnail(w, r)
		} else {
			a.httpDownload(w, r)
		}
	case http.MethodPost:
		if r.URL.Path == "/fix-dates" {
			a.httpFixDates(w, r)
		} else if strings.HasPrefix(r.URL.Path, "/thumbnail/") {
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
		err = a.im.UploadVideo(body, length, encoded, dateTime)
	} else {
		err = a.im.UploadImg(body, length, encoded, dateTime)
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
	if path == "" || r.ContentLength == 0 {
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	name := strings.TrimPrefix(path, "/thumbnail/")
	date := r.Header.Get("Image-Date")
	dateTime, err := time.Parse("2006:01:02 15:04:05", date)
	if err != nil {
		dateTime = time.Now()
	}
	thumbPath := filepath.Join(".thumbnail", dateTime.Format("2006/01/02"), name)
	data, err := io.ReadAll(r.Body)
	r.Body.Close()
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(err.Error()))
		return
	}
	if err := a.im.Drive().Upload(thumbPath, io.NopCloser(bytes.NewReader(data)), int64(len(data)), time.Time{}); err != nil {
		log.Printf("upload thumbnail error: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(err.Error()))
		return
	}
	// Clear any failure record so the server uses this uploaded thumbnail
	if store := a.im.Store(); store != nil {
		store.ClearThumbFailure(filepath.Join(dateTime.Format("2006/01/02"), name))
	}
	w.WriteHeader(http.StatusOK)
}

func (a *api) httpDownload(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path
	if path == "" {
		w.WriteHeader(http.StatusNotFound)
		return
	}
	log.Printf("[httpDownload] path=%s", path)
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
		log.Printf("[httpDownload] GetImg error for %s: %v", path, err)
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(err.Error()))
		return
	}
	defer img.Content.Close()
	w.Header().Set("Content-Length", strconv.FormatInt(img.Size, 10))
	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Accept-Ranges", "bytes")
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
		log.Printf("thumbnail error for %s: %v", realPath, err)
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(err.Error()))
		return
	}
	w.Header().Set("Content-Length", strconv.Itoa(len(data)))
	w.Header().Set("Content-Type", "image/jpeg")
	w.Write(data)
}

func (a *api) httpFixDates(w http.ResponseWriter, r *http.Request) {
	dir := r.URL.Query().Get("dir")
	if dir == "" {
		dir = "2026/03/13"
	}
	debug := r.URL.Query().Get("debug") == "1"
	if debug {
		store := a.im.Store()
		if store == nil {
			w.Write([]byte("store is nil"))
			return
		}
		files := store.ListRemoteFiles()
		var sb strings.Builder
		count := 0
		for _, f := range files {
			if strings.HasPrefix(f.Path, dir+"/") {
				parts := strings.SplitN(f.Path, "/", 4)
				sb.WriteString(fmt.Sprintf("path=%s parts=%d dirPrefix=%s\n", f.Path, len(parts), strings.Join(parts[:3], "/")))
				count++
			}
		}
		sb.WriteString(fmt.Sprintf("\nTotal: %d in %s (store total: %d)\n", count, dir, len(files)))
		w.Write([]byte(sb.String()))
		return
	}
	// Move files matching pattern from one date dir to another
	// ?from=2026/03/13&to=2022/10/22&prefix=IMG_0&min=62&max=173
	from := r.URL.Query().Get("from")
	to := r.URL.Query().Get("to")
	prefix := r.URL.Query().Get("prefix")
	minStr := r.URL.Query().Get("min")
	maxStr := r.URL.Query().Get("max")
	if from == "" || to == "" {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("need from, to params"))
		return
	}
	w.Header().Set("Content-Type", "text/plain")
	w.WriteHeader(http.StatusOK)
	store := a.im.Store()
	if store == nil {
		w.Write([]byte("store not initialized"))
		return
	}
	minNum, _ := strconv.Atoi(minStr)
	maxNum, _ := strconv.Atoi(maxStr)
	moved := 0
	for _, f := range store.ListRemoteFiles() {
		if !strings.HasPrefix(f.Path, from+"/") {
			continue
		}
		fileName := f.Path[len(from)+1:]
		// Check prefix + number range filter
		if prefix != "" && minNum > 0 && maxNum > 0 {
			if !strings.HasPrefix(fileName, prefix) {
				continue
			}
			// Extract number after prefix
			rest := fileName[len(prefix):]
			dotIdx := strings.Index(rest, ".")
			if dotIdx < 0 {
				// Try underscore (e.g. IMG_0147_1.MP4)
				dotIdx = len(rest)
			}
			numPart := rest[:dotIdx]
			// Handle _1 suffix
			if usIdx := strings.Index(numPart, "_"); usIdx >= 0 {
				numPart = numPart[:usIdx]
			}
			num, err := strconv.Atoi(numPart)
			if err != nil {
				continue
			}
			if num < minNum || num > maxNum {
				continue
			}
		}
		newPath := to + "/" + fileName
		fmt.Fprintf(w, "MOVE %s -> %s\n", f.Path, newPath)
		if err := a.im.Drive().Rename(f.Path, newPath); err != nil {
			fmt.Fprintf(w, "  ERROR: %v\n", err)
			continue
		}
		store.RemoveRemoteFile(f.Path)
		store.UpsertRemoteFile(newPath, f.Size, f.ModTime)
		moved++
	}
	fmt.Fprintf(w, "\nMoved %d files\n", moved)
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

