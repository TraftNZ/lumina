package main

import (
	"bytes"
	"context"
	"fmt"
	"image"
	"image/jpeg"
	"image/png"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/jdeng/goheif"
	"github.com/nfnt/resize"
	"github.com/studio-b12/gowebdav"

	_ "golang.org/x/image/webp"
)

const (
	thumbnailDir    = ".thumbnail"
	thumbnailWidth  = 500
	thumbnailHeight = 500
	jpegQuality     = 75
	concurrency     = 4
)

var yearPattern = regexp.MustCompile(`^\d{4}$`)
var monthPattern = regexp.MustCompile(`^\d{2}$`)

var (
	totalFound  atomic.Int64
	generated   atomic.Int64
	skipped     atomic.Int64
	failed      atomic.Int64
	unsupported atomic.Int64
)

var hasFfmpeg bool

func isSupportedMedia(name string) bool {
	ext := strings.ToLower(filepath.Ext(name))
	switch ext {
	case ".jpg", ".jpeg", ".png", ".webp", ".heic", ".heif":
		return true
	case ".mp4", ".mov", ".avi", ".mkv", ".3gp", ".flv", ".wmv",
		".mpg", ".mpeg", ".webm", ".mts", ".m2ts", ".ts", ".rmvb", ".rm":
		return hasFfmpeg
	}
	return false
}

func isVideoExt(ext string) bool {
	switch ext {
	case ".mp4", ".mov", ".avi", ".mkv", ".3gp", ".flv", ".wmv",
		".mpg", ".mpeg", ".webm", ".mts", ".m2ts", ".ts", ".rmvb", ".rm":
		return true
	}
	return false
}

func generateVideoThumbnail(data []byte, ext string) ([]byte, error) {
	tmp, err := os.CreateTemp("", "genthumb-*"+ext)
	if err != nil {
		return nil, fmt.Errorf("create temp: %w", err)
	}
	tmpPath := tmp.Name()
	defer os.Remove(tmpPath)

	if _, err := tmp.Write(data); err != nil {
		tmp.Close()
		return nil, fmt.Errorf("write temp: %w", err)
	}
	tmp.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "ffmpeg",
		"-ss", "00:00:01.00",
		"-i", tmpPath,
		"-vf", "scale=500:500:force_original_aspect_ratio=decrease",
		"-vframes", "1",
		"-f", "mjpeg",
		"-q:v", "5",
		"pipe:1",
	)
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("ffmpeg: %w", err)
	}
	if len(out) == 0 {
		return nil, fmt.Errorf("ffmpeg produced empty output")
	}
	return out, nil
}

func thumbnailExists(cli *gowebdav.Client, thumbPath string) bool {
	_, err := cli.Stat(thumbPath)
	return err == nil
}

func generateThumbnail(data []byte, ext string) ([]byte, error) {
	var img image.Image
	var err error

	switch strings.ToLower(ext) {
	case ".jpg", ".jpeg":
		img, err = jpeg.Decode(bytes.NewReader(data))
	case ".png":
		img, err = png.Decode(bytes.NewReader(data))
		if err != nil {
			// Some files have wrong extension — try JPEG fallback
			img, err = jpeg.Decode(bytes.NewReader(data))
		}
	case ".webp":
		img, _, err = image.Decode(bytes.NewReader(data))
	case ".heic", ".heif":
		img, err = goheif.Decode(bytes.NewReader(data))
		if err != nil {
			// iOS "-edited" HEIC files are often re-encoded as JPEG with wrong extension
			img, err = jpeg.Decode(bytes.NewReader(data))
		}
	default:
		return nil, fmt.Errorf("unsupported format: %s", ext)
	}
	if err != nil {
		return nil, fmt.Errorf("decode error: %w", err)
	}

	thumb := resize.Thumbnail(thumbnailWidth, thumbnailHeight, img, resize.Bilinear)
	var buf bytes.Buffer
	if err := jpeg.Encode(&buf, thumb, &jpeg.Options{Quality: jpegQuality}); err != nil {
		return nil, fmt.Errorf("encode error: %w", err)
	}
	return buf.Bytes(), nil
}

func processPhoto(cli *gowebdav.Client, photoPath string) {
	thumbPath := filepath.Join(thumbnailDir, photoPath)

	if thumbnailExists(cli, thumbPath) {
		skipped.Add(1)
		return
	}

	if !isSupportedMedia(photoPath) {
		unsupported.Add(1)
		return
	}

	ext := strings.ToLower(filepath.Ext(photoPath))

	var data []byte
	for attempt := range 3 {
		reader, err := cli.ReadStream(photoPath)
		if err != nil {
			if attempt < 2 {
				time.Sleep(time.Duration(attempt+1) * 2 * time.Second)
				continue
			}
			log.Printf("  FAIL download %s: %v", photoPath, err)
			failed.Add(1)
			return
		}
		data, err = io.ReadAll(reader)
		reader.Close()
		if err != nil {
			if attempt < 2 {
				time.Sleep(time.Duration(attempt+1) * 2 * time.Second)
				continue
			}
			log.Printf("  FAIL read %s: %v", photoPath, err)
			failed.Add(1)
			return
		}
		break
	}

	var thumbData []byte
	var err error
	if isVideoExt(ext) {
		thumbData, err = generateVideoThumbnail(data, ext)
	} else {
		thumbData, err = generateThumbnail(data, ext)
	}
	if err != nil {
		log.Printf("  FAIL generate %s: %v", photoPath, err)
		failed.Add(1)
		return
	}

	// Ensure parent directory exists
	thumbDir := filepath.Dir(thumbPath)
	cli.MkdirAll(thumbDir, 0755)

	err = cli.Write(thumbPath, thumbData, 0644)
	if err != nil {
		log.Printf("  FAIL upload %s: %v", thumbPath, err)
		failed.Add(1)
		return
	}

	generated.Add(1)
	count := generated.Load()
	if count%50 == 0 {
		log.Printf("  Progress: %d generated, %d skipped, %d failed, %d unsupported",
			count, skipped.Load(), failed.Load(), unsupported.Load())
	}
}

func listPhotos(cli *gowebdav.Client) []string {
	var photos []string

	log.Println("Scanning WebDAV for photos...")

	years, err := cli.ReadDir("/")
	if err != nil {
		log.Fatalf("Failed to list root: %v", err)
	}

	for _, y := range years {
		if !y.IsDir() || !yearPattern.MatchString(y.Name()) {
			continue
		}
		yearPath := y.Name()

		months, err := cli.ReadDir(yearPath)
		if err != nil {
			log.Printf("Failed to list %s: %v", yearPath, err)
			continue
		}

		for _, m := range months {
			if !m.IsDir() || !monthPattern.MatchString(m.Name()) {
				continue
			}
			monthPath := filepath.Join(yearPath, m.Name())

			days, err := cli.ReadDir(monthPath)
			if err != nil {
				log.Printf("Failed to list %s: %v", monthPath, err)
				continue
			}

			for _, d := range days {
				if !d.IsDir() || !monthPattern.MatchString(d.Name()) {
					continue
				}
				dayPath := filepath.Join(monthPath, d.Name())

				files, err := cli.ReadDir(dayPath)
				if err != nil {
					log.Printf("Failed to list %s: %v", dayPath, err)
					continue
				}

				for _, f := range files {
					if f.IsDir() {
						continue
					}
					photos = append(photos, filepath.Join(dayPath, f.Name()))
				}
			}
		}
	}

	log.Printf("Found %d photos total", len(photos))
	return photos
}

func main() {
	url := os.Getenv("WEBDAV_URL")
	user := os.Getenv("WEBDAV_USERNAME")
	pass := os.Getenv("WEBDAV_PASSWORD")

	if url == "" || user == "" || pass == "" {
		log.Fatal("Set WEBDAV_URL, WEBDAV_USERNAME, WEBDAV_PASSWORD environment variables (or use .env)")
	}

	if _, err := exec.LookPath("ffmpeg"); err == nil {
		hasFfmpeg = true
		log.Println("ffmpeg found — video thumbnail generation enabled")
	} else {
		log.Println("WARNING: ffmpeg not found — video thumbnails will be skipped")
	}

	cli := gowebdav.NewClient(url, user, pass)

	if _, err := cli.ReadDir("/"); err != nil {
		log.Fatalf("Failed to connect to WebDAV: %v", err)
	}
	log.Printf("Connected to %s", url)

	photos := listPhotos(cli)
	totalFound.Store(int64(len(photos)))

	start := time.Now()

	sem := make(chan struct{}, concurrency)
	var wg sync.WaitGroup

	for _, photo := range photos {
		wg.Add(1)
		sem <- struct{}{}
		go func(p string) {
			defer wg.Done()
			defer func() { <-sem }()
			processPhoto(cli, p)
		}(photo)
	}

	wg.Wait()

	elapsed := time.Since(start)
	log.Printf("Done in %s", elapsed.Round(time.Second))
	log.Printf("  Total photos:  %d", totalFound.Load())
	log.Printf("  Generated:     %d", generated.Load())
	log.Printf("  Already exist: %d", skipped.Load())
	log.Printf("  Unsupported:   %d (DNG/video etc)", unsupported.Load())
	log.Printf("  Failed:        %d", failed.Load())
}
