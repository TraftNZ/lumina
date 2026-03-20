//go:build !mobile

package imgmanager

import (
	"context"
	"fmt"
	"io"
	"os"
	"os/exec"
	"time"
)

var videoExtensions = []string{
	".mp4", ".mov", ".avi", ".mkv", ".3gp", ".flv", ".wmv",
	".mpg", ".mpeg", ".webm", ".mts", ".m2ts", ".ts", ".rmvb", ".rm",
}

type FfmpegGenerator struct{}

func (g *FfmpegGenerator) Extensions() []string { return videoExtensions }
func (g *FfmpegGenerator) Priority() int        { return 100 }

func (g *FfmpegGenerator) Generate(src io.Reader, ext string) ([]byte, error) {
	tmp, err := os.CreateTemp("", "lumina-thumb-*"+ext)
	if err != nil {
		return nil, fmt.Errorf("create temp: %w", err)
	}
	tmpPath := tmp.Name()
	defer os.Remove(tmpPath)

	if _, err := io.Copy(tmp, src); err != nil {
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

func init() {
	if _, err := exec.LookPath("ffmpeg"); err == nil {
		RegisterGenerator(&FfmpegGenerator{})
	}
}
