package s3

import (
	"context"
	"fmt"
	"io"
	"io/fs"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

type S3Drive struct {
	client   *s3.Client
	bucket   string
	rootPath string
}

func NewS3Drive(endpoint, region, accessKeyID, secretAccessKey string) *S3Drive {
	cfg := aws.Config{
		Region:      region,
		Credentials: credentials.NewStaticCredentialsProvider(accessKeyID, secretAccessKey, ""),
	}
	client := s3.NewFromConfig(cfg, func(o *s3.Options) {
		if endpoint != "" {
			o.BaseEndpoint = aws.String(endpoint)
		}
		o.UsePathStyle = true
	})
	return &S3Drive{
		client: client,
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
	return d.rootPath + filepath.ToSlash(path)
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

func (d *S3Drive) Upload(path string, reader io.ReadCloser, size int64, lastModified time.Time) error {
	if reader == nil {
		return fmt.Errorf("reader is nil")
	}
	defer reader.Close()
	if d.bucket == "" {
		return fmt.Errorf("bucket not set")
	}
	key := d.fullKey(path)
	_, err := d.client.PutObject(context.Background(), &s3.PutObjectInput{
		Bucket:        aws.String(d.bucket),
		Key:           aws.String(key),
		Body:          reader,
		ContentLength: aws.Int64(size),
	})
	return err
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
	out, err := d.client.GetObject(context.Background(), input)
	if err != nil {
		return nil, 0, err
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
	_, err := d.client.DeleteObject(context.Background(), &s3.DeleteObjectInput{
		Bucket: aws.String(d.bucket),
		Key:    aws.String(key),
	})
	return err
}

func (d *S3Drive) Rename(oldPath, newPath string) error {
	if d.bucket == "" {
		return fmt.Errorf("bucket not set")
	}
	oldKey := d.fullKey(oldPath)
	newKey := d.fullKey(newPath)
	copySource := d.bucket + "/" + oldKey
	_, err := d.client.CopyObject(context.Background(), &s3.CopyObjectInput{
		Bucket:     aws.String(d.bucket),
		CopySource: aws.String(copySource),
		Key:        aws.String(newKey),
	})
	if err != nil {
		return fmt.Errorf("copy object error: %w", err)
	}
	_, err = d.client.DeleteObject(context.Background(), &s3.DeleteObjectInput{
		Bucket: aws.String(d.bucket),
		Key:    aws.String(oldKey),
	})
	if err != nil {
		return fmt.Errorf("delete old object error: %w", err)
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
	// Collect directories from CommonPrefixes
	for paginator.HasMorePages() {
		page, err := paginator.NextPage(context.Background())
		if err != nil {
			return err
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

func (f *s3FileInfo) Name() string        { return f.name }
func (f *s3FileInfo) Size() int64          { return f.size }
func (f *s3FileInfo) Mode() fs.FileMode    { return 0444 }
func (f *s3FileInfo) ModTime() time.Time   { return f.modTime }
func (f *s3FileInfo) IsDir() bool          { return f.isDir }
func (f *s3FileInfo) Sys() interface{}     { return nil }
func (f *s3FileInfo) Type() fs.FileMode    { return f.Mode().Type() }
func (f *s3FileInfo) Info() (fs.FileInfo, error) { return f, nil }

// Ensure it also satisfies fs.DirEntry for callers that type-assert.
var _ fs.DirEntry = (*s3FileInfo)(nil)

type desc []fs.FileInfo

func (d desc) Len() int      { return len(d) }
func (d desc) Swap(i, j int) { d[i], d[j] = d[j], d[i] }
func (d desc) Less(i, j int) bool {
	return d[i].ModTime().After(d[j].ModTime())
}

// Ensure S3Drive satisfies the StorageDrive interface at compile time.
var _ interface {
	Upload(string, io.ReadCloser, int64, time.Time) error
	Download(string) (io.ReadCloser, int64, error)
	DownloadWithOffset(string, int64) (io.ReadCloser, int64, error)
	Delete(string) error
	Rename(string, string) error
	Range(string, func(fs.FileInfo) bool) error
} = (*S3Drive)(nil)
