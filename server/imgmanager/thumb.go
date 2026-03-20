package imgmanager

import (
	"bytes"
	"errors"
	"image"
	"image/jpeg"
	"image/png"
	"io"
	"sort"
	"strings"

	"github.com/jdeng/goheif"
	"github.com/nfnt/resize"
	_ "golang.org/x/image/webp"
)

// ErrPassThrough signals that a generator cannot handle this file and the
// pipeline should try the next generator.
var ErrPassThrough = errors.New("pass through to next generator")

// ThumbGenerator produces a JPEG thumbnail from raw file data.
type ThumbGenerator interface {
	// Generate creates a thumbnail from src data. Return ErrPassThrough to
	// delegate to lower-priority generators.
	Generate(src io.Reader, ext string) ([]byte, error)

	// Extensions returns the file extensions this generator supports (e.g. ".jpg").
	Extensions() []string

	// Priority determines execution order — higher runs first.
	Priority() int
}

var generators []ThumbGenerator

// RegisterGenerator adds a generator to the global pipeline.
func RegisterGenerator(g ThumbGenerator) {
	generators = append(generators, g)
	sort.Slice(generators, func(i, j int) bool {
		return generators[i].Priority() > generators[j].Priority()
	})
}

// generateThumbnail runs the generator pipeline for the given extension.
func generateThumbnail(src io.Reader, ext string) ([]byte, error) {
	ext = strings.ToLower(ext)
	for _, g := range generators {
		supported := false
		for _, e := range g.Extensions() {
			if e == ext {
				supported = true
				break
			}
		}
		if !supported {
			continue
		}
		data, err := g.Generate(src, ext)
		if errors.Is(err, ErrPassThrough) {
			continue
		}
		return data, err
	}
	return nil, errors.New("no generator available for " + ext)
}

// BuiltinImageGenerator handles jpg/jpeg/png via pure Go decoders.
type BuiltinImageGenerator struct{}

func (g *BuiltinImageGenerator) Extensions() []string {
	return []string{".jpg", ".jpeg", ".png"}
}

func (g *BuiltinImageGenerator) Priority() int { return 300 }

func (g *BuiltinImageGenerator) Generate(src io.Reader, ext string) ([]byte, error) {
	data, err := io.ReadAll(src)
	if err != nil {
		return nil, err
	}

	var img image.Image
	switch ext {
	case ".jpg", ".jpeg":
		img, err = jpeg.Decode(bytes.NewReader(data))
	case ".png":
		img, err = png.Decode(bytes.NewReader(data))
		if err != nil {
			img, err = jpeg.Decode(bytes.NewReader(data))
		}
	}
	if err != nil {
		return nil, err
	}

	return encodeThumb(img)
}

// HeicWebpGenerator handles heic/heif/webp via goheif and x/image/webp.
type HeicWebpGenerator struct{}

func (g *HeicWebpGenerator) Extensions() []string {
	return []string{".heic", ".heif", ".webp"}
}

func (g *HeicWebpGenerator) Priority() int { return 200 }

func (g *HeicWebpGenerator) Generate(src io.Reader, ext string) ([]byte, error) {
	data, err := io.ReadAll(src)
	if err != nil {
		return nil, err
	}

	var img image.Image
	switch ext {
	case ".heic", ".heif":
		img, err = goheif.Decode(bytes.NewReader(data))
		if err != nil {
			img, err = jpeg.Decode(bytes.NewReader(data))
		}
	case ".webp":
		img, _, err = image.Decode(bytes.NewReader(data))
	}
	if err != nil {
		return nil, err
	}

	return encodeThumb(img)
}

func encodeThumb(img image.Image) ([]byte, error) {
	resized := resize.Thumbnail(thumbnailMaxWidth, thumbnailMaxHeight, img, resize.Bilinear)
	buf := &bytes.Buffer{}
	if err := jpeg.Encode(buf, resized, &jpeg.Options{Quality: 75}); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

func init() {
	RegisterGenerator(&BuiltinImageGenerator{})
	RegisterGenerator(&HeicWebpGenerator{})
}
