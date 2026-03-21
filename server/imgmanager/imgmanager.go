package imgmanager

import (
	"bytes"
	"fmt"
	"io"
	"io/fs"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/Workiva/go-datastructures/queue"
	"github.com/traftai/lumina/server/localstore"
)

const (
	defaultWorkerNum    = 2
	defaultThumbnailDir = ".thumbnail"
	defaultTrashDir     = ".trash"
	defaultLockedDir    = ".locked"
	trashAutoDeleteDays = 30
)

type TrashItem struct {
	OriginalPath string
	TrashPath    string
	TrashedAt    time.Time
	Size         int64
}

type ImgManager struct {
	dri      StorageDrive
	actQueue *queue.Queue
	logger   *log.Logger
	opt      Option
	store    *localstore.LocalStore
}

type Option struct {
	WorkerNum  int
	LocalStore *localstore.LocalStore
}

func NewImgManager(opt Option) *ImgManager {
	if opt.WorkerNum <= 0 {
		opt.WorkerNum = defaultWorkerNum
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
			return
		}
		if _, ok := dri.(SmartBackend); ok {
			im.logger.Printf("Smart backend detected, skipping SyncIndex")
			return
		}
		go func() {
			count, err := im.SyncIndex()
			if err != nil {
				im.logger.Printf("Background SyncIndex failed: %v", err)
			} else {
				im.logger.Printf("Background SyncIndex completed: %d files indexed", count)
			}
		}()
	}
}

func (im *ImgManager) Drive() StorageDrive {
	return im.dri
}

type actType int

const (
	actUpload = iota
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
		case actDelete:
			err := im.dri.Delete(act.path)
			if err != nil {
				im.logger.Println("Error deleting image:", err)
			}
		}
	}
}

func (im *ImgManager) UploadImgAsync(path string, content []byte, lastModified time.Time) {
	im.actQueue.Put(action{
		t:            actUpload,
		path:         path,
		content:      content,
		lastModified: lastModified,
	})
}

func (im *ImgManager) UploadVideo(content io.Reader, contentSize int64, name string, date time.Time) error {
	if content == nil {
		return fmt.Errorf("no video data")
	}
	// If client-provided date looks wrong (future or very recent),
	// try to extract the real date from the original filename.
	if fnDate, ok := extractDateFromOriginalName(name); ok {
		if dateLooksSuspicious(date) || dateDiffSignificant(date, fnDate) {
			im.logger.Printf("UploadVideo: overriding date %s with filename date %s for %s",
				date.Format("2006-01-02"), fnDate.Format("2006-01-02"), name)
			date = fnDate
			// Re-encode the name with the correct date prefix
			name = reEncodeName(name, date)
		}
	}
	path := filepath.Join(date.Format("2006/01/02"), name)
	err := im.dri.Upload(path, io.NopCloser(content), contentSize, date)
	if err != nil {
		im.logger.Println("Error uploading video:", err)
		return fmt.Errorf("error uploading video: %w", err)
	}
	if im.store != nil {
		im.store.UpsertRemoteFile(path, contentSize, date)
	}
	return nil
}

func (im *ImgManager) UploadImg(content io.Reader, contentSize int64, name string, date time.Time) error {
	if content == nil {
		return fmt.Errorf("no image data")
	}
	data, err := io.ReadAll(content)
	if err != nil {
		return err
	}
	if len(data) == 0 {
		return fmt.Errorf("no image data")
	}
	// Try EXIF extraction if date is missing or looks suspicious (future/very recent)
	if date.IsZero() || dateLooksSuspicious(date) {
		meta, metaErr := GetImageMetadata(data)
		if metaErr == nil {
			var dateStr string
			if meta.DateTimeOriginal != "" {
				dateStr = meta.DateTimeOriginal
			} else if meta.Datetime != "" {
				dateStr = meta.Datetime
			} else if meta.CreateDate != "" {
				dateStr = meta.CreateDate
			} else if meta.ModifyDate != "" {
				dateStr = meta.ModifyDate
			}
			if dateStr != "" {
				if parsed, parseErr := time.Parse("2006:01:02 15:04:05", dateStr); parseErr == nil {
					if !parsed.Before(time.Date(1990, 1, 1, 0, 0, 0, 0, time.UTC)) {
						if date.IsZero() || dateDiffSignificant(date, parsed) {
							im.logger.Printf("UploadImg: overriding date %s with EXIF date %s for %s",
								date.Format("2006-01-02"), parsed.Format("2006-01-02"), name)
							date = parsed
							name = reEncodeName(name, date)
						}
					}
				}
			}
		}
	}
	if date.Before(time.Date(1990, 1, 1, 0, 0, 0, 0, time.UTC)) {
		date = time.Now()
	}
	if date.IsZero() {
		date = time.Now()
	}
	path := filepath.Join(date.Format("2006/01/02"), name)
	err = im.dri.Upload(path,
		io.NopCloser(bytes.NewReader(data)), int64(len(data)), date)
	if err != nil {
		im.logger.Println("Error uploading image:", err)
		return err
	}
	if im.store != nil {
		im.store.UpsertRemoteFile(path, int64(len(data)), date)
	}
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

const (
	thumbnailMaxWidth  = 500
	thumbnailMaxHeight = 500
)

func (im *ImgManager) GetCachedThumbnail(path string) ([]byte, error) {
	// Smart backend handles its own thumbnails
	if sb, ok := im.dri.(SmartBackend); ok {
		// Check on-disk cache first
		if im.store != nil {
			cachePath := filepath.Join(im.store.ThumbCacheDir(), path)
			if data, err := os.ReadFile(cachePath); err == nil && len(data) > 0 {
				return data, nil
			}
		}

		// Check failure table
		if im.store != nil && im.store.IsThumbFailed(path) {
			return nil, fmt.Errorf("thumbnail previously failed for %s", filepath.Base(path))
		}

		// Fetch from SmartBackend
		data, err := sb.GetThumbnail(path)
		if err != nil {
			if im.store != nil {
				im.store.MarkThumbFailed(path)
			}
			return nil, err
		}

		// Write to disk cache asynchronously
		if im.store != nil {
			cachePath := filepath.Join(im.store.ThumbCacheDir(), path)
			go func() {
				os.MkdirAll(filepath.Dir(cachePath), 0755)
				os.WriteFile(cachePath, data, 0644)
			}()
		}

		return data, nil
	}

	// 1. Check failure table — skip known failures instantly
	if im.store != nil && im.store.IsThumbFailed(path) {
		return nil, fmt.Errorf("thumbnail previously failed for %s", filepath.Base(path))
	}

	// 2. Try pre-generated thumbnail from remote storage (.thumbnail/<path>)
	thumbPath := filepath.Join(defaultThumbnailDir, path)
	if thumbReader, _, err := im.dri.Download(thumbPath); err == nil {
		data, readErr := io.ReadAll(thumbReader)
		thumbReader.Close()
		if readErr == nil && len(data) > 0 {
			return data, nil
		}
	}

	// 3. Generate on-demand via generator pipeline
	ext := strings.ToLower(filepath.Ext(path))
	fullImg, _, err := im.dri.Download(path)
	if err != nil {
		return nil, fmt.Errorf("error downloading original: %w", err)
	}
	defer fullImg.Close()

	thumbData, err := generateThumbnail(fullImg, ext)
	if err != nil {
		if im.store != nil {
			im.store.MarkThumbFailed(path)
		}
		return nil, fmt.Errorf("thumbnail generation failed: %w", err)
	}

	// Upload generated thumbnail to remote for future use
	im.dri.Upload(thumbPath,
		io.NopCloser(bytes.NewReader(thumbData)), int64(len(thumbData)), time.Time{})

	return thumbData, nil
}

func (im *ImgManager) DeleteSingleImg(path string) error {
	if path == "" {
		return nil
	}
	err := im.dri.Delete(path)
	if err == nil && im.store != nil {
		im.store.RemoveRemoteFile(path)
	}
	return err
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
				var files []fs.FileInfo
				im.dri.Range(dirPath, func(info fs.FileInfo) bool {
					if !info.IsDir() {
						files = append(files, info)
					}
					return true
				})
				sort.Slice(files, func(i, j int) bool {
					return files[i].Name() > files[j].Name()
				})
				goOn := true
				for _, finfo := range files {
					goOn = f(filepath.Join(dirPath, finfo.Name()), finfo.Size())
					if !goOn {
						break
					}
				}
				if !goOn {
					goto BREAK
				}
			}
		}
	}
BREAK:
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
	if im.store != nil {
		im.store.RemoveRemoteFile(path)
	}
	return nil
}

func (im *ImgManager) RestoreFromTrash(trashPath string) error {
	originalPath := trashPath
	fullTrashPath := filepath.Join(defaultTrashDir, trashPath)
	if err := im.dri.Rename(fullTrashPath, originalPath); err != nil {
		return fmt.Errorf("restore from trash error: %w", err)
	}
	if im.store != nil {
		im.store.UpsertRemoteFile(originalPath, 0, time.Now())
	}
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
		if strings.HasPrefix(yinfo.Name(), ".") {
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


// Locked folder functions

func (im *ImgManager) MoveToLocked(path string) error {
	lockedPath := filepath.Join(defaultLockedDir, path)
	if err := im.dri.Rename(path, lockedPath); err != nil {
		return fmt.Errorf("move to locked error: %w", err)
	}
	if im.store != nil {
		im.store.RemoveRemoteFile(path)
	}
	return nil
}

func (im *ImgManager) RestoreFromLocked(lockedPath string) error {
	originalPath := lockedPath
	fullLockedPath := filepath.Join(defaultLockedDir, lockedPath)
	if err := im.dri.Rename(fullLockedPath, originalPath); err != nil {
		return fmt.Errorf("restore from locked error: %w", err)
	}
	if im.store != nil {
		im.store.UpsertRemoteFile(originalPath, 0, time.Now())
	}
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
		if strings.HasPrefix(yinfo.Name(), ".") {
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


func (im *ImgManager) SyncIndex() (int, error) {
	if im.store == nil {
		return 0, fmt.Errorf("local store not available")
	}

	// SmartBackend (e.g. Cloudreve) provides its own file listing.
	if sb, ok := im.dri.(SmartBackend); ok {
		files, err := sb.ListPhotos()
		if err != nil {
			return 0, err
		}
		if len(files) > 0 {
			im.store.UpsertRemoteFiles(files)
		}
		im.store.SetLastIndexedDate(time.Now().Format("2006/01/02"))
		return im.store.CountRemoteFiles(), nil
	}

	lastDate := im.store.GetLastIndexedDate()
	var startDate time.Time
	if lastDate != "" {
		parsed, err := time.Parse("2006/01/02", lastDate)
		if err == nil {
			startDate = parsed
		}
	}
	now := time.Now()
	var batch []localstore.RemoteFile
	err := im.RangeByDate(now, func(path string, size int64) bool {
		parts := strings.SplitN(path, "/", 4)
		if len(parts) >= 3 {
			dirDate := parts[0] + "/" + parts[1] + "/" + parts[2]
			if !startDate.IsZero() {
				d, err := time.Parse("2006/01/02", dirDate)
				if err == nil && d.Before(startDate) {
					return false
				}
			}
		}
		rf := localstore.RemoteFile{
			Path:    path,
			Size:    size,
			ModTime: now,
		}
		rf.TakenAt = localstore.ParseDateFromPath(path)
		batch = append(batch, rf)
		return true
	})
	if err != nil {
		return 0, err
	}
	if len(batch) > 0 {
		im.store.UpsertRemoteFiles(batch)
	}
	im.store.SetLastIndexedDate(now.Format("2006/01/02"))
	return im.store.CountRemoteFiles(), nil
}

func (im *ImgManager) FullResyncIndex() (int, error) {
	if im.store == nil {
		return 0, fmt.Errorf("local store not available")
	}
	im.store.ClearRemoteFiles()

	// SmartBackend (e.g. Cloudreve) provides its own file listing.
	if sb, ok := im.dri.(SmartBackend); ok {
		files, err := sb.ListPhotos()
		if err != nil {
			return 0, err
		}
		if len(files) > 0 {
			im.store.UpsertRemoteFiles(files)
		}
		im.store.SetLastIndexedDate(time.Now().Format("2006/01/02"))
		return im.store.CountRemoteFiles(), nil
	}

	now := time.Now()
	var batch []localstore.RemoteFile
	err := im.RangeByDate(now, func(path string, size int64) bool {
		rf := localstore.RemoteFile{
			Path:    path,
			Size:    size,
			ModTime: now,
		}
		rf.TakenAt = localstore.ParseDateFromPath(path)
		batch = append(batch, rf)
		return true
	})
	if err != nil {
		return 0, err
	}
	if len(batch) > 0 {
		im.store.UpsertRemoteFiles(batch)
	}
	im.store.SetLastIndexedDate(now.Format("2006/01/02"))
	return im.store.CountRemoteFiles(), nil
}

func (im *ImgManager) ListFromIndex() []localstore.RemoteFile {
	// Always read from the local store cache. SyncIndex() populates it
	// (including for SmartBackend like Cloudreve), so we don't need to
	// re-fetch from the remote API on every call.
	if im.store == nil {
		return nil
	}
	return im.store.ListRemoteFiles()
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

// --- Date extraction and fix utilities ---

// filenameDatePatterns matches common date patterns in photo/video filenames.
// Examples: VID_20200103_120000, IMG_20200103_120000, 20200103_120000, Screenshot_20200103-120000
var filenameDatePatterns = []*regexp.Regexp{
	regexp.MustCompile(`(?:VID|IMG|PXL|Screenshot|MVIMG|PANO)_(\d{4})(\d{2})(\d{2})[_-](\d{2})(\d{2})(\d{2})`),
	regexp.MustCompile(`(\d{4})(\d{2})(\d{2})[_-](\d{2})(\d{2})(\d{2})`),
}

// extractDateFromOriginalName tries to extract a date from the original filename
// embedded in the encoded name format: YYYYMMDDHHmmss_<hash16>_<originalname>
func extractDateFromOriginalName(encodedName string) (time.Time, bool) {
	// Extract original name: skip the timestamp prefix and optional hash
	original := extractOriginalName(encodedName)
	if original == "" {
		original = encodedName
	}
	for _, re := range filenameDatePatterns {
		m := re.FindStringSubmatch(original)
		if m == nil {
			continue
		}
		year, _ := strconv.Atoi(m[1])
		month, _ := strconv.Atoi(m[2])
		day, _ := strconv.Atoi(m[3])
		hour, _ := strconv.Atoi(m[4])
		min, _ := strconv.Atoi(m[5])
		sec, _ := strconv.Atoi(m[6])
		if year < 1990 || year > 2100 || month < 1 || month > 12 || day < 1 || day > 31 {
			continue
		}
		return time.Date(year, time.Month(month), day, hour, min, sec, 0, time.Local), true
	}
	return time.Time{}, false
}

// extractOriginalName extracts the original filename from the encoded format.
// Encoded: YYYYMMDDHHmmss_<hash16>_<originalname> or YYYYMMDDHHmmss_<originalname>
func extractOriginalName(encoded string) string {
	// Try format with hash: 14-char timestamp + "_" + 16-char hash + "_" + name
	if len(encoded) > 31 && encoded[14] == '_' && encoded[31] == '_' {
		return encoded[32:]
	}
	// Try format without hash: 14-char timestamp + "_" + name
	if len(encoded) > 15 && encoded[14] == '_' {
		return encoded[15:]
	}
	return ""
}

// dateLooksSuspicious returns true if the date is in the future or within the
// last 7 days (likely time.Now() fallback rather than actual photo date).
func dateLooksSuspicious(t time.Time) bool {
	now := time.Now()
	if t.After(now) {
		return true
	}
	// Current year is suspicious for old media — most photos in a library
	// are from past years, not the upload date
	if t.Year() == now.Year() && now.Sub(t) < 30*24*time.Hour {
		return true
	}
	return false
}

// dateDiffSignificant returns true if two dates differ by more than 1 day.
func dateDiffSignificant(a, b time.Time) bool {
	diff := a.Sub(b)
	if diff < 0 {
		diff = -diff
	}
	return diff > 24*time.Hour
}

// reEncodeName replaces the timestamp prefix in an encoded filename with a new date.
func reEncodeName(encoded string, newDate time.Time) string {
	if len(encoded) > 14 && encoded[14] == '_' {
		return newDate.Format("20060102150405") + encoded[14:]
	}
	return encoded
}

// FixDates scans for files in a specific date directory and moves them.
func (im *ImgManager) FixDates(targetDir string) (moved int, err error) {
	return im.FixDatesVerbose(targetDir, io.Discard)
}

// FixDatesVerbose is like FixDates but writes progress to w.
func (im *ImgManager) FixDatesVerbose(targetDir string, w io.Writer) (moved int, err error) {
	if im.store == nil {
		return 0, fmt.Errorf("store not initialized")
	}
	files := im.store.ListRemoteFiles()
	fmt.Fprintf(w, "Store has %d total files, scanning for dir=%s\n", len(files), targetDir)
	now := time.Now()
	for _, f := range files {
		parts := strings.SplitN(f.Path, "/", 4)
		if len(parts) < 4 {
			continue
		}
		dirPrefix := strings.Join(parts[:3], "/")
		if targetDir != "" {
			if dirPrefix != targetDir {
				continue
			}
		} else {
			year, _ := strconv.Atoi(parts[0])
			if year != now.Year() {
				continue
			}
		}
		fileName := parts[3] // the encoded filename
		originalName := extractOriginalName(fileName)
		if originalName == "" {
			originalName = fileName
		}
		fmt.Fprintf(w, "[FixDates] processing %s (original=%s, isImage=%v, isVideo=%v)\n",
			fileName, originalName, isImageFile(originalName), isVideoFile(originalName))

		// Try to get the correct date
		var correctDate time.Time
		found := false

		// 1. Try filename date patterns
		if fnDate, ok := extractDateFromOriginalName(fileName); ok && fnDate.Year() != now.Year() {
			correctDate = fnDate
			found = true
			fmt.Fprintf(w, "[FixDates] %s -> date from filename: %s", fileName, correctDate.Format("2006-01-02")+"\n")
		}

		// 2. For images, try EXIF
		if !found && isImageFile(originalName) {
			fmt.Fprintf(w, "[FixDates] downloading %s for EXIF...\n", f.Path)
			content, _, dlErr := im.dri.Download(f.Path)
			if dlErr != nil {
				fmt.Fprintf(w, "[FixDates] download error for %s: %v\n", f.Path, dlErr)
			} else {
				data, readErr := io.ReadAll(content)
				content.Close()
				if readErr != nil {
					fmt.Fprintf(w, "[FixDates] read error for %s: %v\n", f.Path, readErr)
				} else {
					if exifDate, ok := extractExifDate(data); ok && exifDate.Year() != now.Year() {
						correctDate = exifDate
						found = true
						fmt.Fprintf(w, "[FixDates] %s -> EXIF date: %s", fileName, correctDate.Format("2006-01-02")+"\n")
					} else {
						fmt.Fprintf(w, "[FixDates] %s -> no valid EXIF date found\n", fileName)
					}
				}
			}
		}

		// 3. For videos, try ffprobe
		if !found && isVideoFile(originalName) {
			if vDate, ok := extractVideoDate(im, f.Path, w); ok && vDate.Year() != now.Year() {
				correctDate = vDate
				found = true
				fmt.Fprintf(w, "[FixDates] %s -> video date: %s", fileName, correctDate.Format("2006-01-02")+"\n")
			}
		}

		if !found {
			fmt.Fprintf(w, "[FixDates] %s -> no correct date found, skipping\n", fileName)
			continue
		}

		// Build new path with correct date
		newEncodedName := reEncodeName(fileName, correctDate)
		newPath := filepath.Join(correctDate.Format("2006/01/02"), newEncodedName)
		if newPath == f.Path {
			continue
		}

		fmt.Fprintf(w, "[FixDates] moving %s -> %s\n", f.Path, newPath)
		if renameErr := im.dri.Rename(f.Path, newPath); renameErr != nil {
			fmt.Fprintf(w, "[FixDates] rename error: %v\n", renameErr)
			continue
		}
		// Update store
		im.store.RemoveRemoteFile(f.Path)
		im.store.UpsertRemoteFile(newPath, f.Size, correctDate)
		// Also move thumbnail if it exists
		oldThumb := filepath.Join(defaultThumbnailDir, parts[0], parts[1], parts[2], originalName)
		newThumb := filepath.Join(defaultThumbnailDir, correctDate.Format("2006/01/02"), originalName)
		_ = im.dri.Rename(oldThumb, newThumb)
		moved++
	}
	return moved, nil
}

func isVideoFile(name string) bool {
	ext := strings.ToLower(filepath.Ext(name))
	switch ext {
	case ".mp4", ".mov", ".avi", ".mkv", ".3gp", ".flv", ".wmv", ".mpg", ".mpeg", ".webm", ".mts", ".m2ts", ".ts", ".rmvb":
		return true
	}
	return false
}

// extractVideoDate downloads a video and uses ffprobe to get creation_time.
func extractVideoDate(im *ImgManager, filePath string, w io.Writer) (time.Time, bool) {
	fmt.Fprintf(w, "[FixDates] downloading video %s for ffprobe...\n", filePath)
	content, size, err := im.dri.Download(filePath)
	if err != nil {
		fmt.Fprintf(w, "[FixDates] video download error for %s: %v\n", filePath, err)
		return time.Time{}, false
	}
	fmt.Fprintf(w, "[FixDates] downloaded %s (%d bytes), running ffprobe...\n", filePath, size)
	// Use current directory for temp files — macOS sandbox may block /tmp
	tmpDir := "."
	if home, _ := os.UserHomeDir(); home != "" {
		tmpDir = home
	}
	tmp, tmpErr := os.CreateTemp(tmpDir, "lumina-fixdate-*.mp4")
	if tmpErr != nil {
		content.Close()
		fmt.Fprintf(w, "[FixDates] temp file error: %v\n", tmpErr)
		return time.Time{}, false
	}
	tmpPath := tmp.Name()
	defer os.Remove(tmpPath)
	n, cpErr := io.Copy(tmp, content)
	content.Close()
	tmp.Close()
	if cpErr != nil {
		fmt.Fprintf(w, "[FixDates] copy error: %v\n", cpErr)
		return time.Time{}, false
	}
	fmt.Fprintf(w, "[FixDates] wrote %d bytes to temp, running ffprobe...\n", n)
	t, ok := ffprobeCreationTime(tmpPath)
	if ok {
		fmt.Fprintf(w, "[FixDates] ffprobe date: %s\n", t.Format("2006-01-02 15:04:05"))
	} else {
		fmt.Fprintf(w, "[FixDates] ffprobe: no creation_time found\n")
	}
	return t, ok
}

// ffprobeCreationTime runs ffprobe to extract creation_time from a video file.
func ffprobeCreationTime(path string) (time.Time, bool) {
	// Use full path — sandboxed macOS apps may not have /opt/homebrew/bin in PATH
	ffprobePath := "ffprobe"
	for _, p := range []string{"/opt/homebrew/bin/ffprobe", "/usr/local/bin/ffprobe", "/usr/bin/ffprobe"} {
		if _, err := os.Stat(p); err == nil {
			ffprobePath = p
			break
		}
	}
	// Try multiple metadata keys — Apple uses com.apple.quicktime.creationdate
	for _, tag := range []string{
		"format_tags=creation_time",
		"format_tags=com.apple.quicktime.creationdate",
		"stream_tags=creation_time",
	} {
		cmd := exec.Command(ffprobePath,
			"-v", "quiet",
			"-show_entries", tag,
			"-of", "default=noprint_wrappers=1:nokey=1",
			path,
		)
		out, err := cmd.Output()
		if err != nil {
			continue
		}
		s := strings.TrimSpace(string(out))
		if s == "" {
			continue
		}
		for _, layout := range []string{
			"2006-01-02T15:04:05.000000Z",
			"2006-01-02T15:04:05Z",
			"2006-01-02T15:04:05+0800",
			"2006-01-02T15:04:05+08:00",
			"2006-01-02T15:04:05",
			"2006-01-02 15:04:05",
		} {
			if t, parseErr := time.Parse(layout, s); parseErr == nil && t.Year() >= 1990 {
				return t, true
			}
		}
	}
	return time.Time{}, false
}

func isImageFile(name string) bool {
	ext := strings.ToLower(filepath.Ext(name))
	switch ext {
	case ".jpg", ".jpeg", ".png", ".heic", ".heif", ".webp", ".tiff", ".tif", ".dng", ".cr2", ".nef", ".arw":
		return true
	}
	return false
}

func extractExifDate(data []byte) (time.Time, bool) {
	meta, err := GetImageMetadata(data)
	if err != nil {
		return time.Time{}, false
	}
	for _, dateStr := range []string{meta.DateTimeOriginal, meta.Datetime, meta.CreateDate, meta.ModifyDate} {
		if dateStr == "" {
			continue
		}
		if parsed, parseErr := time.Parse("2006:01:02 15:04:05", dateStr); parseErr == nil {
			if parsed.Year() >= 1990 {
				return parsed, true
			}
		}
	}
	return time.Time{}, false
}
