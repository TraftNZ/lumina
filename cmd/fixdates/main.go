package main

import (
	"crypto/tls"
	"fmt"
	"io"
	"io/fs"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/dsoprea/go-exif/v3"
	exifcommon "github.com/dsoprea/go-exif/v3/common"
	"github.com/studio-b12/gowebdav"
)

func main() {
	url := os.Getenv("WEBDAV_URL")
	username := os.Getenv("WEBDAV_USERNAME")
	password := os.Getenv("WEBDAV_PASSWORD")

	if url == "" || username == "" || password == "" {
		log.Fatal("Set WEBDAV_URL, WEBDAV_USERNAME, WEBDAV_PASSWORD env vars")
	}

	dryRun := false
	for _, arg := range os.Args[1:] {
		if arg == "--dry-run" {
			dryRun = true
		}
	}

	cli := gowebdav.NewClient(url, username, password)
	cli.SetTransport(&http.Transport{
		TLSClientConfig:       &tls.Config{InsecureSkipVerify: true},
		MaxIdleConns:          10,
		MaxIdleConnsPerHost:   4,
		IdleConnTimeout:       30 * time.Second,
		ResponseHeaderTimeout: 5 * time.Minute,
		DialContext: (&net.Dialer{
			Timeout:   15 * time.Second,
			KeepAlive: 30 * time.Second,
		}).DialContext,
	})

	// Scan 2026/ directory for misplaced photos
	scanDir := "/2026"
	log.Printf("Scanning %s for photos with wrong dates (dry-run=%v)...", scanDir, dryRun)

	var moved, skipped, failed, noExif int
	walkDir(cli, scanDir, func(path string, info fs.FileInfo) {
		if info.IsDir() {
			return
		}
		name := strings.ToLower(info.Name())
		if !isPhoto(name) {
			skipped++
			return
		}

		// Download the photo to read EXIF
		data, err := downloadFile(cli, path)
		if err != nil {
			log.Printf("FAIL download %s: %v", path, err)
			failed++
			return
		}

		exifDate, err := extractExifDate(data)
		if err != nil || exifDate.IsZero() || exifDate.Year() < 1990 {
			log.Printf("NO_EXIF %s (err=%v)", path, err)
			noExif++
			return
		}

		// Build correct path
		correctDir := fmt.Sprintf("/%s", exifDate.Format("2006/01/02"))
		correctPath := filepath.Join(correctDir, info.Name())

		// Check if already in the right place
		currentDir := filepath.Dir(path)
		if currentDir == correctDir {
			skipped++
			return
		}

		log.Printf("MOVE %s -> %s (EXIF date: %s)", path, correctPath, exifDate.Format("2006-01-02 15:04:05"))

		if !dryRun {
			// Create target directory
			if err := cli.MkdirAll(correctDir, 0755); err != nil {
				log.Printf("FAIL mkdir %s: %v", correctDir, err)
				failed++
				return
			}

			// Check if target already exists
			if _, err := cli.Stat(correctPath); err == nil {
				// Target exists, add suffix
				ext := filepath.Ext(info.Name())
				base := strings.TrimSuffix(info.Name(), ext)
				correctPath = filepath.Join(correctDir, fmt.Sprintf("%s_%d%s", base, time.Now().UnixMilli(), ext))
				log.Printf("  target exists, using %s", correctPath)
			}

			if err := cli.Rename(path, correctPath, true); err != nil {
				log.Printf("FAIL rename %s -> %s: %v", path, correctPath, err)
				failed++
				return
			}
		}
		moved++
	})

	log.Printf("Done! moved=%d skipped=%d noExif=%d failed=%d", moved, skipped, noExif, failed)
}

func isPhoto(name string) bool {
	exts := []string{".jpg", ".jpeg", ".png", ".heic", ".heif", ".webp", ".tiff", ".tif", ".dng", ".cr2", ".nef", ".arw"}
	for _, ext := range exts {
		if strings.HasSuffix(name, ext) {
			return true
		}
	}
	return false
}

func downloadFile(cli *gowebdav.Client, path string) ([]byte, error) {
	reader, err := cli.ReadStream(path)
	if err != nil {
		return nil, err
	}
	defer reader.Close()
	return io.ReadAll(reader)
}

func extractExifDate(data []byte) (time.Time, error) {
	rawExif, err := exif.SearchAndExtractExif(data)
	if err != nil {
		return time.Time{}, err
	}
	ifdMapping, err := exifcommon.NewIfdMappingWithStandard()
	if err != nil {
		return time.Time{}, err
	}
	ti := exif.NewTagIndex()
	_, index, err := exif.Collect(ifdMapping, ti, rawExif)
	if err != nil {
		return time.Time{}, err
	}
	rootIfd := index.RootIfd

	// Try date fields in priority order
	for _, tagName := range []string{"DateTimeOriginal", "DateTime", "CreateDate", "ModifyDate"} {
		results, err := rootIfd.FindTagWithName(tagName)
		if err != nil || len(results) != 1 {
			continue
		}
		value, err := results[0].Value()
		if err != nil {
			continue
		}
		str, ok := value.(string)
		if !ok || str == "" {
			continue
		}
		t, err := time.Parse("2006:01:02 15:04:05", str)
		if err != nil {
			continue
		}
		if t.Year() >= 1990 && t.Year() <= 2025 {
			return t, nil
		}
	}
	return time.Time{}, fmt.Errorf("no valid EXIF date found")
}

func walkDir(cli *gowebdav.Client, dir string, fn func(string, fs.FileInfo)) {
	infos, err := cli.ReadDir(dir)
	if err != nil {
		log.Printf("Error reading dir %s: %v", dir, err)
		return
	}
	for _, info := range infos {
		path := filepath.Join(dir, info.Name())
		if info.IsDir() {
			walkDir(cli, path, fn)
		} else {
			fn(path, info)
		}
	}
}
