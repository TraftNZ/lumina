package imgmanager

import (
	"bytes"
	"fmt"
	"image"
	"image/jpeg"
	"image/png"
	"io"
	"io/fs"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/Workiva/go-datastructures/queue"
	"github.com/traftai/lumina/server/localstore"
	"github.com/nfnt/resize"
)

const (
	defaultWorkerNum          = 2
	defaultThumbnailMaxWidth  = 500
	defaultThumbnailMaxHeight = 500
	defaultThumbnailDir       = ".thumbnail"
	defaultTrashDir           = ".trash"
	defaultLockedDir           = ".locked"
	trashAutoDeleteDays       = 30
	syncMarkerFile            = ".sync_marker"
	syncIndexFile             = ".sync_index"
)

type TrashItem struct {
	OriginalPath string
	TrashPath    string
	TrashedAt    time.Time
	Size         int64
}

type ImgManager struct {
	dri            StorageDrive
	actQueue       *queue.Queue
	logger         *log.Logger
	opt            Option
	store          *localstore.LocalStore
	syncDebounce   *time.Timer
	syncDebounceMu sync.Mutex
}

type Option struct {
	WorkerNum          int
	ThumbnailMaxWidth  int
	ThumbnailMaxHeight int
	ThumbbailQuality   int
	LocalStore         *localstore.LocalStore
}

func NewImgManager(opt Option) *ImgManager {
	if opt.WorkerNum <= 0 {
		opt.WorkerNum = defaultWorkerNum
	}
	if opt.ThumbnailMaxWidth <= 0 {
		opt.ThumbnailMaxWidth = defaultThumbnailMaxWidth
	}
	if opt.ThumbnailMaxHeight <= 0 {
		opt.ThumbnailMaxHeight = defaultThumbnailMaxHeight
	}
	im := &ImgManager{
		actQueue: queue.New(10),
		logger:   log.New(os.Stdout, "[ImgManager] ", log.LstdFlags),
		opt:      opt,
		dri:      &UnimplementedDrive{},
		store:    opt.LocalStore,
	}
	for i := 0; i < im.opt.WorkerNum; i++ {
		go im.runWorker()
	}
	return im
}

func (im *ImgManager) Store() *localstore.LocalStore {
	return im.store
}

func (im *ImgManager) SetDrive(dri StorageDrive) {
	im.dri = dri
}

func (im *ImgManager) SwitchDrive(dri StorageDrive, configHash string) {
	im.dri = dri
	if im.store != nil {
		if err := im.store.SwitchDrive(configHash); err != nil {
			im.logger.Printf("Failed to switch drive store: %v", err)
		}
	}
}

func (im *ImgManager) Drive() StorageDrive {
	return im.dri
}

type actType int

const (
	actGenerateThumbnail = iota
	actUpload
	actDelete
)

type action struct {
	t            actType
	path         string
	content      []byte
	lastModified time.Time
}

func (im *ImgManager) runWorker() {
	for {
		item, err := im.actQueue.Get(1)
		if err != nil {
			im.logger.Println("Error getting action from queue:", err)
			continue
		}
		if len(item) == 0 {
			continue
		}
		act := item[0].(action)
		switch act.t {
		case actUpload:
			err := im.dri.Upload(
				act.path,
				io.NopCloser(bytes.NewReader(act.content)), int64(len(act.content)), act.lastModified)
			if err != nil {
				im.logger.Println("Error uploading image:", err)
			}
		case actGenerateThumbnail:
			err := im.GenerateThumbnail(act.path, act.content)
			if err != nil {
				im.logger.Println("Error generating thumbnail:", err)
			}
		case actDelete:
			err := im.dri.Delete(act.path)
			if err != nil {
				im.logger.Println("Error deleting image:", err)
			}
		}
	}
}

func (im *ImgManager) GenerateThumbnail(path string, content []byte) error {
	var err error
	var imghdl image.Image
	switch strings.ToLower(filepath.Ext(path)) {
	case JpegSuffix:
		imghdl, err = jpeg.Decode(bytes.NewReader(content))
	case PngSuffix:
		imghdl, err = png.Decode(bytes.NewReader(content))
	default:
		return fmt.Errorf("unsupported image format: %s", filepath.Ext(path))
	}
	if err != nil {
		return err
	}
	newImghdl := resize.Thumbnail(uint(im.opt.ThumbnailMaxWidth), uint(im.opt.ThumbnailMaxHeight), imghdl, resize.Bilinear)
	buf := bytes.NewBuffer(make([]byte, 0))
	err = jpeg.Encode(buf, newImghdl, &jpeg.Options{Quality: 75})
	if err != nil {
		return err
	}
	thumbPath := filepath.Join(defaultThumbnailDir, path)
	err = im.dri.Upload(thumbPath, io.NopCloser(buf), int64(buf.Len()), time.Time{})
	if err != nil {
		return err
	}

	return nil
}

func (im *ImgManager) UploadImgAsync(path string, content []byte, lastModified time.Time) {
	im.actQueue.Put(action{
		t:            actUpload,
		path:         path,
		content:      content,
		lastModified: lastModified,
	})
}

func (im *ImgManager) GenerateThumbnailAsync(path string, content []byte) {
	im.actQueue.Put(action{
		t:       actGenerateThumbnail,
		path:    path,
		content: content,
	})
}

func (im *ImgManager) UploadVideo(content, thumbnailContent io.Reader, contentSize, thumbnailSize int64, name string, date time.Time) error {
	path := filepath.Join(date.Format("2006/01/02"), name)
	wg := sync.WaitGroup{}
	wg.Add(2)
	var err error
	go func() {
		defer wg.Done()
		if content == nil {
			return
		}
		e := im.dri.Upload(path, io.NopCloser(content), contentSize, date)
		if e != nil {
			im.logger.Println("Error uploading video:", e)
			err = fmt.Errorf("error uploading video: %w", e)
		}
	}()
	go func() {
		defer wg.Done()
		if thumbnailContent == nil {
			return
		}
		e := im.dri.Upload(filepath.Join(defaultThumbnailDir, path),
			io.NopCloser(thumbnailContent), thumbnailSize, date)
		if e != nil {
			im.logger.Println("Error uploading video:", err)
			err = fmt.Errorf("error uploading video thumbnail: %w", e)
		}
	}()
	wg.Wait()
	if err == nil && im.store != nil {
		im.store.IndexPhoto(path, filepath.Base(path), contentSize)
	}
	if err == nil {
		im.DebouncedWriteSyncState()
	}
	return err
}

func (im *ImgManager) UploadImg(content, thumbnailContent io.Reader, contentSize, thumbnailSize int64, name string, date time.Time) error {
	errCh := make(chan error, 2)
	var data []byte
	var thumbData []byte
	go func() {
		var err error
		if content != nil {
			data, err = io.ReadAll(content)
		}
		errCh <- err
	}()
	go func() {
		var err error
		if thumbnailContent != nil {
			thumbData, err = io.ReadAll(thumbnailContent)
		}
		errCh <- err
	}()
	for i := 0; i < 2; i++ {
		err := <-errCh
		if err != nil {
			return err
		}
	}
	if len(data) == 0 && len(thumbData) == 0 {
		return fmt.Errorf("no image data")
	}
	if date.IsZero() && len(data) > 0 {
		// try to get image time from metadata
		meta, err := GetImageMetadata(data)
		if err == nil {
			im.logger.Printf("Image metadata: %+v", meta)
			var dateStr string
			if meta.Datetime != "" {
				dateStr = meta.Datetime
			} else if meta.DateTimeOriginal != "" {
				dateStr = meta.DateTimeOriginal
			} else if meta.CreateDate != "" {
				dateStr = meta.CreateDate
			} else if meta.ModifyDate != "" {
				dateStr = meta.ModifyDate
			}
			if dateStr != "" {
				date, err = time.Parse("2006:01:02 15:04:05", dateStr)
				if err != nil {
					im.logger.Println("Error parsing date:", err)
				}
			}
		}
	}
	if date.Before(time.Date(1990, 1, 1, 0, 0, 0, 0, time.UTC)) {
		date = time.Now()
	}
	// try to get image time from given date
	if date.IsZero() {
		date = time.Now()
	}
	path := filepath.Join(date.Format("2006/01/02"), name)
	var err error
	if len(data) > 0 {
		err = im.dri.Upload(path,
			io.NopCloser(bytes.NewReader(data)), int64(len(data)), date)
		if err != nil {
			im.logger.Println("Error uploading image:", err)
			return err
		}
		if im.store != nil {
			im.store.IndexPhoto(path, filepath.Base(path), int64(len(data)))
		}
	}
	if len(thumbData) > 0 {
		err = im.dri.Upload(filepath.Join(defaultThumbnailDir, path),
			io.NopCloser(bytes.NewReader(thumbData)), int64(len(thumbData)), date)
		if err != nil {
			im.logger.Println("Error uploading thumbnail:", err)
			return err
		}
	}
	im.DebouncedWriteSyncState()
	return nil
}

func (im *ImgManager) GetImg(path string) (*Image, error) {
	img := &Image{}
	var err error
	img.Content, img.Size, err = im.dri.Download(path)
	if err != nil {
		return img, err
	}
	img.Path = path
	return img, nil
}

func (im *ImgManager) GetOffset(path string, offset int64) (*Image, error) {
	img := &Image{}
	var err error
	img.Content, img.Size, err = im.dri.DownloadWithOffset(path, offset)
	if err != nil {
		return img, err
	}
	img.Path = path
	return img, nil
}

func (im *ImgManager) GetThumbnail(path string) (*Image, error) {
	img := &Image{}
	var err error
	thumbnailPath := filepath.Join(defaultThumbnailDir, path)
	img.Content, img.Size, err = im.dri.Download(thumbnailPath)
	if err != nil {
		return img, fmt.Errorf("error downloading thumbnail: %w", err)
	}
	img.Path = thumbnailPath
	return img, nil
}

func (im *ImgManager) GetCachedThumbnail(path string) ([]byte, error) {
	if im.store != nil {
		if data, err := im.store.GetThumb(path); err == nil {
			return data, nil
		}
	}
	img, err := im.GetThumbnail(path)
	if err != nil {
		return nil, err
	}
	defer img.Content.Close()
	data, err := io.ReadAll(img.Content)
	if err != nil {
		return nil, err
	}
	if im.store != nil {
		go im.store.PutThumb(path, data)
	}
	return data, nil
}

func (im *ImgManager) DeleteSingleImg(path string) error {
	if path == "" {
		return nil
	}
	err := im.dri.Delete(path)
	if err != nil {
		return err
	}
	if im.store != nil {
		im.store.RemovePhoto(path)
		im.store.RemoveThumb(path)
	}
	im.DebouncedWriteSyncState()
	return nil
}

func (im *ImgManager) DeleteSingleImgAsync(path string) {
	if path != "" {
		im.actQueue.Put(action{t: actDelete, path: path})
	}
}

func (im *ImgManager) DeleteImg(paths []string) {
	for _, path := range paths {
		if path != "" {
			im.DeleteSingleImgAsync(path)
			if im.store != nil {
				im.store.RemovePhoto(path)
				im.store.RemoveThumb(path)
			}
		}
	}
}

func (im *ImgManager) RangeByDate(date time.Time, f func(path string, size int64) bool) error {
	t := date
	if t.IsZero() {
		t = time.Now()
	}
	year, month, day := t.Date()
	yDir, err := im.listDir(".")
	if err != nil {
		im.logger.Println("Error listing year dir:", err)
		return err
	}
	sort.Sort(desc(yDir))
	for _, yinfo := range yDir {
		if !yinfo.IsDir() {
			continue
		}
		yNum, err := strconv.Atoi(yinfo.Name())
		if err != nil {
			continue
		}
		if yNum > year {
			continue
		}
		mDir, err := im.listDir(filepath.Base(yinfo.Name()))
		if err != nil {
			im.logger.Println("Error listing month dir:", err)
			continue
		}
		sort.Sort(desc(mDir))
		for _, minfo := range mDir {
			if !minfo.IsDir() {
				continue
			}
			mNum, err := strconv.Atoi(minfo.Name())
			if err != nil {
				continue
			}
			if yNum == year && mNum > int(month) {
				continue
			}
			dDir, err := im.listDir(filepath.Join(yinfo.Name(), minfo.Name()))
			if err != nil {
				im.logger.Println("Error listing day dir:", err)
				continue
			}
			sort.Sort(desc(dDir))
			for _, dinfo := range dDir {
				if !dinfo.IsDir() {
					continue
				}
				dNum, err := strconv.Atoi(dinfo.Name())
				if err != nil {
					continue
				}
				if yNum == year && mNum == int(month) && dNum > day {
					continue
				}
				dirPath := filepath.Join(yinfo.Name(), minfo.Name(), dinfo.Name())
				goOn := true
				im.dri.Range(dirPath, func(info fs.FileInfo) bool {
					if info.IsDir() {
						return true
					}
					goOn = f(filepath.Join(dirPath, info.Name()), info.Size())
					return goOn
				})
				if !goOn {
					goto BREAK
				}
			}
		}
	}
BREAK:
	return nil
}

// DebouncedWriteSyncState schedules a WriteSyncState to run after a short
// delay. If called multiple times in quick succession (e.g. during a batch
// upload), only one WriteSyncState runs after the last call settles.
func (im *ImgManager) DebouncedWriteSyncState() {
	im.syncDebounceMu.Lock()
	defer im.syncDebounceMu.Unlock()
	if im.syncDebounce != nil {
		im.syncDebounce.Stop()
	}
	im.syncDebounce = time.AfterFunc(2*time.Second, func() {
		im.WriteSyncState()
	})
}

// WriteSyncState uploads both the index and marker to remote storage.
// Called async after mutations so other devices can download the index
// instead of walking all directories.
// It merges with the existing remote index first so concurrent uploads
// from different devices don't overwrite each other's entries.
func (im *ImgManager) WriteSyncState() {
	if im.store == nil {
		return
	}
	// Download existing remote index and merge into local before exporting,
	// so we don't lose entries added by other devices
	rc, _, err := im.dri.Download(syncIndexFile)
	if err == nil {
		data, readErr := io.ReadAll(rc)
		rc.Close()
		if readErr == nil {
			im.store.MergeIndex(data)
		}
	}
	// Upload merged index, then marker
	indexData, err := im.store.ExportIndex()
	if err != nil {
		im.logger.Printf("Failed to export index: %v", err)
		return
	}
	err = im.dri.Upload(syncIndexFile,
		io.NopCloser(bytes.NewReader(indexData)),
		int64(len(indexData)), time.Time{})
	if err != nil {
		im.logger.Printf("Failed to upload sync index: %v", err)
		return
	}
	// Write marker after index — so if a reader sees a new marker,
	// the index is guaranteed to be available
	marker := fmt.Sprintf("%d", time.Now().UnixNano())
	content := []byte(marker)
	err = im.dri.Upload(syncMarkerFile,
		io.NopCloser(bytes.NewReader(content)),
		int64(len(content)), time.Time{})
	if err != nil {
		im.logger.Printf("Failed to write sync marker: %v", err)
		return
	}
	im.store.SetLastSeenMarker(marker)
}

func (im *ImgManager) ReadSyncMarker() (string, error) {
	rc, _, err := im.dri.Download(syncMarkerFile)
	if err != nil {
		return "", err
	}
	defer rc.Close()
	data, err := io.ReadAll(rc)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(data)), nil
}

func (im *ImgManager) CheckMarkerChanged() (bool, error) {
	if im.store == nil {
		return true, nil
	}
	remote, err := im.ReadSyncMarker()
	if err != nil {
		return true, nil
	}
	local := im.store.GetLastSeenMarker()
	if local == "" {
		return true, nil
	}
	return remote != local, nil
}

// SyncFromRemoteIndex downloads the remote index file and imports it.
// Cost: 2 GETs (marker + index) instead of walking all directories.
func (im *ImgManager) SyncFromRemoteIndex() error {
	if im.store == nil {
		return fmt.Errorf("local store not available")
	}
	rc, _, err := im.dri.Download(syncIndexFile)
	if err != nil {
		return fmt.Errorf("download sync index: %w", err)
	}
	defer rc.Close()
	data, err := io.ReadAll(rc)
	if err != nil {
		return fmt.Errorf("read sync index: %w", err)
	}
	if err := im.store.ImportIndex(data); err != nil {
		return fmt.Errorf("import index: %w", err)
	}
	// Snapshot the current marker so we don't re-download next time
	if marker, err := im.ReadSyncMarker(); err == nil {
		im.store.SetLastSeenMarker(marker)
	}
	return nil
}

func (im *ImgManager) RebuildIndex(progressCb func(found int)) error {
	if im.store == nil {
		return fmt.Errorf("local store not available")
	}
	err := im.store.RebuildFromRemote(func(cb func(path string, filename string, size int64) bool) error {
		return im.RangeByDate(time.Now(), func(path string, size int64) bool {
			return cb(path, filepath.Base(path), size)
		})
	}, progressCb)
	if err != nil {
		return err
	}
	// After full rebuild, upload index + marker so other devices can use it
	im.WriteSyncState()
	return nil
}

func (im *ImgManager) listDir(path string) ([]fs.FileInfo, error) {
	infos := make([]fs.FileInfo, 0)
	err := im.dri.Range(path, func(info fs.FileInfo) bool {
		infos = append(infos, info)
		return true
	})
	return infos, err
}

func (im *ImgManager) MoveToTrash(path string) error {
	trashPath := filepath.Join(defaultTrashDir, path)
	if err := im.dri.Rename(path, trashPath); err != nil {
		return fmt.Errorf("move to trash error: %w", err)
	}
	// Also move thumbnail (ignore error if not present)
	thumbPath := filepath.Join(defaultThumbnailDir, path)
	trashThumbPath := filepath.Join(defaultTrashDir, defaultThumbnailDir, path)
	_ = im.dri.Rename(thumbPath, trashThumbPath)

	if im.store != nil {
		im.store.RemovePhoto(path)
		im.store.RemoveThumb(path)
	}
	im.DebouncedWriteSyncState()
	return nil
}

func (im *ImgManager) RestoreFromTrash(trashPath string) error {
	// trashPath is relative to .trash/, e.g. "2024/01/15/photo.jpg"
	originalPath := trashPath
	fullTrashPath := filepath.Join(defaultTrashDir, trashPath)
	if err := im.dri.Rename(fullTrashPath, originalPath); err != nil {
		return fmt.Errorf("restore from trash error: %w", err)
	}
	// Also restore thumbnail (ignore error)
	trashThumbPath := filepath.Join(defaultTrashDir, defaultThumbnailDir, trashPath)
	thumbPath := filepath.Join(defaultThumbnailDir, trashPath)
	_ = im.dri.Rename(trashThumbPath, thumbPath)

	if im.store != nil {
		// Try to get file size from the restored file
		var size int64
		im.dri.Range(filepath.Dir(originalPath), func(info fs.FileInfo) bool {
			if info.Name() == filepath.Base(originalPath) {
				size = info.Size()
				return false
			}
			return true
		})
		im.store.IndexPhoto(originalPath, filepath.Base(originalPath), size)
	}
	im.DebouncedWriteSyncState()
	return nil
}

func (im *ImgManager) ListTrash(offset, maxReturn int) ([]TrashItem, error) {
	if maxReturn <= 0 {
		maxReturn = 100
	}
	items := make([]TrashItem, 0)
	currentOffset := 0
	now := time.Now()

	im.rangeTrashByDate(now, func(path string, size int64, modTime time.Time) bool {
		// Auto-purge files older than 30 days
		if now.Sub(modTime) > trashAutoDeleteDays*24*time.Hour {
			fullPath := filepath.Join(defaultTrashDir, path)
			_ = im.dri.Delete(fullPath)
			return true
		}
		if currentOffset < offset {
			currentOffset++
			return true
		}
		items = append(items, TrashItem{
			OriginalPath: path,
			TrashPath:    filepath.Join(defaultTrashDir, path),
			TrashedAt:    modTime,
			Size:         size,
		})
		return len(items) < maxReturn
	})
	return items, nil
}

func (im *ImgManager) EmptyTrash() error {
	now := time.Now()
	var lastErr error
	im.rangeTrashByDate(now, func(path string, size int64, modTime time.Time) bool {
		fullPath := filepath.Join(defaultTrashDir, path)
		if err := im.dri.Delete(fullPath); err != nil {
			im.logger.Printf("Error deleting trash item %s: %v", fullPath, err)
			lastErr = err
		}
		// Also delete thumbnail
		thumbPath := filepath.Join(defaultTrashDir, defaultThumbnailDir, path)
		_ = im.dri.Delete(thumbPath)
		return true
	})
	return lastErr
}

func (im *ImgManager) rangeTrashByDate(date time.Time, f func(path string, size int64, modTime time.Time) bool) {
	t := date
	if t.IsZero() {
		t = time.Now()
	}
	year, month, day := t.Date()
	yDir, err := im.listDir(defaultTrashDir)
	if err != nil {
		return
	}
	sort.Sort(desc(yDir))
	for _, yinfo := range yDir {
		if !yinfo.IsDir() {
			continue
		}
		if yinfo.Name() == defaultThumbnailDir {
			continue
		}
		yNum, err := strconv.Atoi(yinfo.Name())
		if err != nil {
			continue
		}
		if yNum > year {
			continue
		}
		mDir, err := im.listDir(filepath.Join(defaultTrashDir, yinfo.Name()))
		if err != nil {
			continue
		}
		sort.Sort(desc(mDir))
		for _, minfo := range mDir {
			if !minfo.IsDir() {
				continue
			}
			mNum, err := strconv.Atoi(minfo.Name())
			if err != nil {
				continue
			}
			if yNum == year && mNum > int(month) {
				continue
			}
			dDir, err := im.listDir(filepath.Join(defaultTrashDir, yinfo.Name(), minfo.Name()))
			if err != nil {
				continue
			}
			sort.Sort(desc(dDir))
			for _, dinfo := range dDir {
				if !dinfo.IsDir() {
					continue
				}
				dNum, err := strconv.Atoi(dinfo.Name())
				if err != nil {
					continue
				}
				if yNum == year && mNum == int(month) && dNum > day {
					continue
				}
				dirPath := filepath.Join(yinfo.Name(), minfo.Name(), dinfo.Name())
				goOn := true
				im.dri.Range(filepath.Join(defaultTrashDir, dirPath), func(info fs.FileInfo) bool {
					if info.IsDir() {
						return true
					}
					goOn = f(filepath.Join(dirPath, info.Name()), info.Size(), info.ModTime())
					return goOn
				})
				if !goOn {
					return
				}
			}
		}
	}
}

func (im *ImgManager) GetTrashThumbnail(path string) (*Image, error) {
	img := &Image{}
	var err error
	thumbnailPath := filepath.Join(defaultTrashDir, defaultThumbnailDir, path)
	img.Content, img.Size, err = im.dri.Download(thumbnailPath)
	if err != nil {
		return img, fmt.Errorf("error downloading trash thumbnail: %w", err)
	}
	img.Path = thumbnailPath
	return img, nil
}

// Locked folder functions

func (im *ImgManager) MoveToLocked(path string) error {
	lockedPath := filepath.Join(defaultLockedDir, path)
	if err := im.dri.Rename(path, lockedPath); err != nil {
		return fmt.Errorf("move to locked error: %w", err)
	}
	// Also move thumbnail (ignore error if not present)
	thumbPath := filepath.Join(defaultThumbnailDir, path)
	lockedThumbPath := filepath.Join(defaultLockedDir, defaultThumbnailDir, path)
	_ = im.dri.Rename(thumbPath, lockedThumbPath)

	if im.store != nil {
		im.store.RemovePhoto(path)
		im.store.RemoveThumb(path)
	}
	im.DebouncedWriteSyncState()
	return nil
}

func (im *ImgManager) RestoreFromLocked(lockedPath string) error {
	// lockedPath is relative to .locked/, e.g. "2024/01/15/photo.jpg"
	originalPath := lockedPath
	fullLockedPath := filepath.Join(defaultLockedDir, lockedPath)
	if err := im.dri.Rename(fullLockedPath, originalPath); err != nil {
		return fmt.Errorf("restore from locked error: %w", err)
	}
	// Also restore thumbnail (ignore error)
	lockedThumbPath := filepath.Join(defaultLockedDir, defaultThumbnailDir, lockedPath)
	thumbPath := filepath.Join(defaultThumbnailDir, lockedPath)
	_ = im.dri.Rename(lockedThumbPath, thumbPath)

	if im.store != nil {
		var size int64
		im.dri.Range(filepath.Dir(originalPath), func(info fs.FileInfo) bool {
			if info.Name() == filepath.Base(originalPath) {
				size = info.Size()
				return false
			}
			return true
		})
		im.store.IndexPhoto(originalPath, filepath.Base(originalPath), size)
	}
	im.DebouncedWriteSyncState()
	return nil
}

func (im *ImgManager) ListLocked(offset, maxReturn int) ([]TrashItem, error) {
	if maxReturn <= 0 {
		maxReturn = 100
	}
	items := make([]TrashItem, 0)
	currentOffset := 0
	now := time.Now()

	im.rangeLockedByDate(now, func(path string, size int64, modTime time.Time) bool {
		if currentOffset < offset {
			currentOffset++
			return true
		}
		items = append(items, TrashItem{
			OriginalPath: path,
			TrashPath:    filepath.Join(defaultLockedDir, path),
			TrashedAt:    modTime,
			Size:         size,
		})
		return len(items) < maxReturn
	})
	return items, nil
}

func (im *ImgManager) rangeLockedByDate(date time.Time, f func(path string, size int64, modTime time.Time) bool) {
	t := date
	if t.IsZero() {
		t = time.Now()
	}
	year, month, day := t.Date()
	yDir, err := im.listDir(defaultLockedDir)
	if err != nil {
		return
	}
	sort.Sort(desc(yDir))
	for _, yinfo := range yDir {
		if !yinfo.IsDir() {
			continue
		}
		if yinfo.Name() == defaultThumbnailDir {
			continue
		}
		yNum, err := strconv.Atoi(yinfo.Name())
		if err != nil {
			continue
		}
		if yNum > year {
			continue
		}
		mDir, err := im.listDir(filepath.Join(defaultLockedDir, yinfo.Name()))
		if err != nil {
			continue
		}
		sort.Sort(desc(mDir))
		for _, minfo := range mDir {
			if !minfo.IsDir() {
				continue
			}
			mNum, err := strconv.Atoi(minfo.Name())
			if err != nil {
				continue
			}
			if yNum == year && mNum > int(month) {
				continue
			}
			dDir, err := im.listDir(filepath.Join(defaultLockedDir, yinfo.Name(), minfo.Name()))
			if err != nil {
				continue
			}
			sort.Sort(desc(dDir))
			for _, dinfo := range dDir {
				if !dinfo.IsDir() {
					continue
				}
				dNum, err := strconv.Atoi(dinfo.Name())
				if err != nil {
					continue
				}
				if yNum == year && mNum == int(month) && dNum > day {
					continue
				}
				dirPath := filepath.Join(yinfo.Name(), minfo.Name(), dinfo.Name())
				goOn := true
				im.dri.Range(filepath.Join(defaultLockedDir, dirPath), func(info fs.FileInfo) bool {
					if info.IsDir() {
						return true
					}
					goOn = f(filepath.Join(dirPath, info.Name()), info.Size(), info.ModTime())
					return goOn
				})
				if !goOn {
					return
				}
			}
		}
	}
}

func (im *ImgManager) GetLockedThumbnail(path string) (*Image, error) {
	img := &Image{}
	var err error
	thumbnailPath := filepath.Join(defaultLockedDir, defaultThumbnailDir, path)
	img.Content, img.Size, err = im.dri.Download(thumbnailPath)
	if err != nil {
		return img, fmt.Errorf("error downloading locked thumbnail: %w", err)
	}
	img.Path = thumbnailPath
	return img, nil
}

type asc []fs.FileInfo

func (a asc) Len() int      { return len(a) }
func (a asc) Swap(i, j int) { a[i], a[j] = a[j], a[i] }
func (a asc) Less(i, j int) bool {
	yi, err := strconv.Atoi(a[i].Name())
	if err != nil {
		return false
	}
	yj, err := strconv.Atoi(a[j].Name())
	if err != nil {
		return true
	}
	return yi < yj
}

type desc []fs.FileInfo

func (d desc) Len() int      { return len(d) }
func (d desc) Swap(i, j int) { d[i], d[j] = d[j], d[i] }
func (d desc) Less(i, j int) bool {
	yi, err := strconv.Atoi(d[i].Name())
	if err != nil {
		return false
	}
	yj, err := strconv.Atoi(d[j].Name())
	if err != nil {
		return true
	}
	return yi > yj
}
