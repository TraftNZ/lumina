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
	"time"

	"github.com/Workiva/go-datastructures/queue"
	"github.com/nfnt/resize"
	"github.com/traftai/lumina/server/localstore"
)

const (
	defaultWorkerNum    = 2
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
		}
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
	path := filepath.Join(date.Format("2006/01/02"), name)
	err := im.dri.Upload(path, io.NopCloser(content), contentSize, date)
	if err != nil {
		im.logger.Println("Error uploading video:", err)
		return fmt.Errorf("error uploading video: %w", err)
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
	if date.IsZero() {
		meta, metaErr := GetImageMetadata(data)
		if metaErr == nil {
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
				if parsed, parseErr := time.Parse("2006:01:02 15:04:05", dateStr); parseErr == nil {
					date = parsed
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
	ext := strings.ToLower(filepath.Ext(path))
	switch ext {
	case JpegSuffix, ".jpeg", PngSuffix:
	default:
		return nil, fmt.Errorf("thumbnail not available for %s", filepath.Base(path))
	}
	fullImg, _, err := im.dri.Download(path)
	if err != nil {
		return nil, fmt.Errorf("error downloading original: %w", err)
	}
	defer fullImg.Close()
	fullData, err := io.ReadAll(fullImg)
	if err != nil {
		return nil, err
	}
	var imghdl image.Image
	switch ext {
	case JpegSuffix, ".jpeg":
		imghdl, err = jpeg.Decode(bytes.NewReader(fullData))
	case PngSuffix:
		imghdl, err = png.Decode(bytes.NewReader(fullData))
	}
	if err != nil {
		return nil, fmt.Errorf("error decoding image: %w", err)
	}
	resized := resize.Thumbnail(thumbnailMaxWidth, thumbnailMaxHeight, imghdl, resize.Bilinear)
	buf := &bytes.Buffer{}
	if err := jpeg.Encode(buf, resized, &jpeg.Options{Quality: 75}); err != nil {
		return nil, fmt.Errorf("error encoding thumbnail: %w", err)
	}
	return buf.Bytes(), nil
}

func (im *ImgManager) DeleteSingleImg(path string) error {
	if path == "" {
		return nil
	}
	return im.dri.Delete(path)
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
	return nil
}

func (im *ImgManager) RestoreFromTrash(trashPath string) error {
	originalPath := trashPath
	fullTrashPath := filepath.Join(defaultTrashDir, trashPath)
	if err := im.dri.Rename(fullTrashPath, originalPath); err != nil {
		return fmt.Errorf("restore from trash error: %w", err)
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
	return nil
}

func (im *ImgManager) RestoreFromLocked(lockedPath string) error {
	originalPath := lockedPath
	fullLockedPath := filepath.Join(defaultLockedDir, lockedPath)
	if err := im.dri.Rename(fullLockedPath, originalPath); err != nil {
		return fmt.Errorf("restore from locked error: %w", err)
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
