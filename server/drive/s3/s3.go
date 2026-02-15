package s3

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"io/fs"
	"log"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

const defaultRegion = "us-east-1"

type S3Drive struct {
	client   *s3.Client
	bucket   string
	rootPath string
	logger   *log.Logger
}

func NewS3Drive(endpoint, region, accessKeyID, secretAccessKey string) *S3Drive {
	if region == "" {
		region = defaultRegion
	}
	cfg := aws.Config{
		Region:      region,
		Credentials: credentials.NewStaticCredentialsProvider(accessKeyID, secretAccessKey, ""),
	}
	client := s3.NewFromConfig(cfg, func(o *s3.Options) {
		if endpoint != "" {
			o.BaseEndpoint = aws.String(endpoint)
		}
		o.UsePathStyle = true
		// Only compute checksums when the API requires them (e.g. DeleteObjects).
		// The default (WhenSupported) adds CRC32 trailing checksums to PutObject,
		// which many S3-compatible services don't support.
		o.RequestChecksumCalculation = aws.RequestChecksumCalculationWhenRequired
	})
	return &S3Drive{
		client: client,
		logger: log.New(log.Writer(), "[S3Drive] ", log.LstdFlags),
	}
}

func (d *S3Drive) SetBucket(bucket string) {
	d.bucket = bucket
}

func (d *S3Drive) SetRootPath(root string) {
	root = filepath.ToSlash(root)
	root = strings.TrimPrefix(root, "/")
	if root != "" && !strings.HasSuffix(root, "/") {
		root += "/"
	}
	d.rootPath = root
}

func (d *S3Drive) fullKey(path string) string {
	path = filepath.ToSlash(path)
	if path == "." || path == "" {
		return d.rootPath
	}
	path = strings.TrimLeft(path, "/")
	return d.rootPath + path
}

// HeadBucket verifies that the configured bucket is accessible.
func (d *S3Drive) HeadBucket(ctx context.Context) error {
	_, err := d.client.HeadBucket(ctx, &s3.HeadBucketInput{
		Bucket: aws.String(d.bucket),
	})
	return err
}

// RoundtripTest uploads a small test object, downloads it, verifies the
// content matches, and deletes it. This proves that S3 writes actually persist.
func (d *S3Drive) RoundtripTest(ctx context.Context) error {
	testKey := d.fullKey(".lumina_write_test")
	testData := []byte("pho-roundtrip-test")

	// Upload
	_, err := d.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:        aws.String(d.bucket),
		Key:           aws.String(testKey),
		Body:          readSeekCloser{bytes.NewReader(testData)},
		ContentLength: aws.Int64(int64(len(testData))),
	})
	if err != nil {
		return fmt.Errorf("put test object: %w", err)
	}

	// Download and verify
	out, err := d.client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(d.bucket),
		Key:    aws.String(testKey),
	})
	if err != nil {
		return fmt.Errorf("get test object: %w", err)
	}
	got, err := io.ReadAll(out.Body)
	out.Body.Close()
	if err != nil {
		return fmt.Errorf("read test object: %w", err)
	}
	if !bytes.Equal(got, testData) {
		return fmt.Errorf("roundtrip mismatch: wrote %d bytes, read %d bytes", len(testData), len(got))
	}

	// Cleanup
	_, _ = d.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(d.bucket),
		Key:    aws.String(testKey),
	})
	d.logger.Printf("Roundtrip test passed: bucket=%s key=%s", d.bucket, testKey)
	return nil
}

func (d *S3Drive) ListBuckets(ctx context.Context) ([]string, error) {
	out, err := d.client.ListBuckets(ctx, &s3.ListBucketsInput{})
	if err != nil {
		return nil, err
	}
	names := make([]string, 0, len(out.Buckets))
	for _, b := range out.Buckets {
		names = append(names, aws.ToString(b.Name))
	}
	return names, nil
}

// readSeekCloser wraps an io.ReadSeeker with a no-op Close.
// This preserves Seek capability (unlike io.NopCloser) so the
// AWS SDK can compute checksums and retry without buffering.
type readSeekCloser struct {
	io.ReadSeeker
}

func (r readSeekCloser) Close() error { return nil }

func (d *S3Drive) Upload(path string, reader io.ReadCloser, size int64, lastModified time.Time) error {
	if reader == nil {
		return fmt.Errorf("reader is nil")
	}
	defer reader.Close()
	if d.bucket == "" {
		return fmt.Errorf("bucket not set")
	}
	key := d.fullKey(path)

	// The AWS SDK v2 needs a seekable body to compute request checksums.
	// Callers typically pass io.NopCloser(bytes.Reader) which hides Seek.
	// If the reader isn't seekable, buffer it so PutObject works correctly.
	var body io.Reader = reader
	if _, ok := reader.(io.ReadSeeker); !ok {
		data, err := io.ReadAll(reader)
		if err != nil {
			return fmt.Errorf("read upload body: %w", err)
		}
		size = int64(len(data))
		body = readSeekCloser{bytes.NewReader(data)}
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()

	_, err := d.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:        aws.String(d.bucket),
		Key:           aws.String(key),
		Body:          body,
		ContentLength: aws.Int64(size),
	})
	if err != nil {
		d.logger.Printf("PutObject failed: bucket=%s key=%s size=%d err=%v", d.bucket, key, size, err)
		return fmt.Errorf("s3 put object: %w", err)
	}
	return nil
}

func (d *S3Drive) Download(path string) (io.ReadCloser, int64, error) {
	return d.DownloadWithOffset(path, 0)
}

func (d *S3Drive) DownloadWithOffset(path string, offset int64) (io.ReadCloser, int64, error) {
	if d.bucket == "" {
		return nil, 0, fmt.Errorf("bucket not set")
	}
	key := d.fullKey(path)
	input := &s3.GetObjectInput{
		Bucket: aws.String(d.bucket),
		Key:    aws.String(key),
	}
	if offset > 0 {
		input.Range = aws.String(fmt.Sprintf("bytes=%d-", offset))
	}

	// Use a background context here. We cannot use a timeout context because
	// the returned Body must remain readable after this function returns.
	// The caller is responsible for closing the body.
	out, err := d.client.GetObject(context.Background(), input)
	if err != nil {
		return nil, 0, fmt.Errorf("s3 get object %s: %w", key, err)
	}
	var totalSize int64
	if out.ContentLength != nil {
		totalSize = *out.ContentLength
		if offset > 0 {
			totalSize += offset
		}
	}
	return out.Body, totalSize, nil
}

func (d *S3Drive) Delete(path string) error {
	if d.bucket == "" {
		return fmt.Errorf("bucket not set")
	}
	key := d.fullKey(path)
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	_, err := d.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(d.bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return fmt.Errorf("s3 delete object %s: %w", key, err)
	}
	return nil
}

func (d *S3Drive) Rename(oldPath, newPath string) error {
	if d.bucket == "" {
		return fmt.Errorf("bucket not set")
	}
	oldKey := d.fullKey(oldPath)
	newKey := d.fullKey(newPath)
	copySource := d.bucket + "/" + oldKey

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	_, err := d.client.CopyObject(ctx, &s3.CopyObjectInput{
		Bucket:     aws.String(d.bucket),
		CopySource: aws.String(copySource),
		Key:        aws.String(newKey),
	})
	if err != nil {
		return fmt.Errorf("s3 copy %s -> %s: %w", oldKey, newKey, err)
	}
	_, err = d.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(d.bucket),
		Key:    aws.String(oldKey),
	})
	if err != nil {
		return fmt.Errorf("s3 delete after copy %s: %w", oldKey, err)
	}
	return nil
}

func (d *S3Drive) Range(dir string, deal func(fs.FileInfo) bool) error {
	if d.bucket == "" {
		return fmt.Errorf("bucket not set")
	}
	prefix := d.fullKey(dir)
	if prefix != "" && !strings.HasSuffix(prefix, "/") {
		prefix += "/"
	}
	paginator := s3.NewListObjectsV2Paginator(d.client, &s3.ListObjectsV2Input{
		Bucket:    aws.String(d.bucket),
		Prefix:    aws.String(prefix),
		Delimiter: aws.String("/"),
	})
	for paginator.HasMorePages() {
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		page, err := paginator.NextPage(ctx)
		cancel()
		if err != nil {
			return fmt.Errorf("s3 list objects prefix=%s: %w", prefix, err)
		}
		// Subdirectories
		for _, cp := range page.CommonPrefixes {
			name := strings.TrimSuffix(strings.TrimPrefix(aws.ToString(cp.Prefix), prefix), "/")
			if name == "" {
				continue
			}
			if !deal(&s3FileInfo{name: name, isDir: true}) {
				return nil
			}
		}
		// Files
		infos := make([]fs.FileInfo, 0, len(page.Contents))
		for _, obj := range page.Contents {
			name := strings.TrimPrefix(aws.ToString(obj.Key), prefix)
			if name == "" || strings.Contains(name, "/") {
				continue
			}
			infos = append(infos, &s3FileInfo{
				name:    name,
				size:    aws.ToInt64(obj.Size),
				modTime: aws.ToTime(obj.LastModified),
			})
		}
		sort.Sort(desc(infos))
		for _, info := range infos {
			if !deal(info) {
				return nil
			}
		}
	}
	return nil
}

// s3FileInfo implements fs.FileInfo for S3 objects.
type s3FileInfo struct {
	name    string
	size    int64
	modTime time.Time
	isDir   bool
}

func (f *s3FileInfo) Name() string             { return f.name }
func (f *s3FileInfo) Size() int64              { return f.size }
func (f *s3FileInfo) Mode() fs.FileMode        { return 0444 }
func (f *s3FileInfo) ModTime() time.Time       { return f.modTime }
func (f *s3FileInfo) IsDir() bool              { return f.isDir }
func (f *s3FileInfo) Sys() interface{}         { return nil }
func (f *s3FileInfo) Type() fs.FileMode        { return f.Mode().Type() }
func (f *s3FileInfo) Info() (fs.FileInfo, error) { return f, nil }

var _ fs.DirEntry = (*s3FileInfo)(nil)

type desc []fs.FileInfo

func (d desc) Len() int      { return len(d) }
func (d desc) Swap(i, j int) { d[i], d[j] = d[j], d[i] }
func (d desc) Less(i, j int) bool {
	return d[i].ModTime().After(d[j].ModTime())
}
