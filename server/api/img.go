package api

import (
	"context"
	"fmt"
	"io"
	"path/filepath"
	"time"

	pb "github.com/fregie/img_syncer/proto"
	"github.com/fregie/img_syncer/server/imgmanager"
)

type api struct {
	im                *imgmanager.ImgManager
	httpPort          int
	baiduLogginInChan chan *pb.StartBaiduNetdiskLoginResponse

	pb.UnimplementedImgSyncerServer
}

func NewApi(im *imgmanager.ImgManager) *api {
	a := &api{
		im: im,
	}
	return a
}

func (a *api) ListByDate(ctx context.Context, req *pb.ListByDateRequest) (rsp *pb.ListByDateResponse, err error) {
	rsp = &pb.ListByDateResponse{Success: true}
	if req.MaxReturn <= 0 {
		req.MaxReturn = 100
	}
	if req.Offset <= 0 {
		req.Offset = 0
	}
	var e error
	start := time.Now()
	if req.Date != "" {
		start, e = time.Parse("2006:01:02", req.Date)
		if e != nil {
			rsp.Success, rsp.Message = false, fmt.Sprintf("param error: date format error: %s", req.Date)
			return
		}
	}
	rsp.Paths = make([]string, 0, req.MaxReturn)
	offset := req.Offset
	needReturn := req.MaxReturn
	e = a.im.RangeByDate(start, func(path string, size int64) bool {
		if offset > 0 {
			offset--
			return true
		}
		rsp.Paths = append(rsp.Paths, path)
		needReturn--
		return needReturn > 0
	})
	if e != nil {
		rsp.Success, rsp.Message = false, e.Error()
		return
	}
	return
}

func (a *api) Delete(ctx context.Context, req *pb.DeleteRequest) (rsp *pb.DeleteResponse, err error) {
	rsp = &pb.DeleteResponse{Success: true}
	a.im.DeleteImg(req.Paths)
	return
}

func (a *api) FilterNotUploaded(stream pb.ImgSyncer_FilterNotUploadedServer) error {
	store := a.im.Store()
	if store == nil || store.IsEmpty() {
		return a.filterNotUploadedLegacy(stream)
	}

	// Check if remote has changed since last rebuild
	changed, _ := a.im.CheckMarkerChanged()
	if changed {
		go func() {
			a.im.RebuildIndex(nil)
		}()
		return a.filterNotUploadedLegacy(stream)
	}

	for {
		r, err := stream.Recv()
		if err != nil {
			if err == io.EOF {
				break
			}
			return err
		}
		filenames := make([]string, 0, len(r.Photos))
		infoMap := make(map[string]string) // encodedName -> assetId
		for _, info := range r.Photos {
			t, err := time.Parse("2006:01:02 15:04:05", info.Date)
			if err != nil {
				continue
			}
			encoded := encodeName(t, info.Name)
			filenames = append(filenames, encoded)
			infoMap[encoded] = info.Id
		}
		exists := store.BatchExistsByFilename(filenames)
		rsp := &pb.FilterNotUploadedResponse{Success: true, IsFinished: r.IsFinished}
		rsp.NotUploaedIDs = make([]string, 0)
		for _, name := range filenames {
			if !exists[name] {
				rsp.NotUploaedIDs = append(rsp.NotUploaedIDs, infoMap[name])
			}
		}
		if err := stream.Send(rsp); err != nil {
			return err
		}
		if rsp.IsFinished {
			break
		}
	}
	return nil
}

func (a *api) filterNotUploadedLegacy(stream pb.ImgSyncer_FilterNotUploadedServer) error {
	all := make(map[string]bool)
	a.im.RangeByDate(time.Now(), func(path string, size int64) bool {
		name := filepath.Base(path)
		all[name] = true
		return true
	})
	for {
		r, err := stream.Recv()
		if err != nil {
			if err == io.EOF {
				break
			}
			return err
		}
		rsp := &pb.FilterNotUploadedResponse{Success: true, IsFinished: r.IsFinished}
		rsp.NotUploaedIDs = make([]string, 0, len(r.Photos))
		for _, info := range r.Photos {
			t, err := time.Parse("2006:01:02 15:04:05", info.Date)
			if err != nil {
				continue
			}
			if !all[encodeName(t, info.Name)] {
				rsp.NotUploaedIDs = append(rsp.NotUploaedIDs, info.Id)
			}
		}
		if err := stream.Send(rsp); err != nil {
			return err
		}
		if rsp.IsFinished {
			break
		}
	}
	return nil
}

func (a *api) MoveToTrash(ctx context.Context, req *pb.MoveToTrashRequest) (rsp *pb.MoveToTrashResponse, err error) {
	rsp = &pb.MoveToTrashResponse{Success: true}
	for _, path := range req.Paths {
		if e := a.im.MoveToTrash(path); e != nil {
			rsp.Success = false
			rsp.Message = fmt.Sprintf("move to trash error: %v", e)
			return
		}
	}
	return
}

func (a *api) ListTrash(ctx context.Context, req *pb.ListTrashRequest) (rsp *pb.ListTrashResponse, err error) {
	rsp = &pb.ListTrashResponse{Success: true}
	items, e := a.im.ListTrash(int(req.Offset), int(req.MaxReturn))
	if e != nil {
		rsp.Success = false
		rsp.Message = e.Error()
		return
	}
	rsp.Items = make([]*pb.TrashItem, 0, len(items))
	for _, item := range items {
		rsp.Items = append(rsp.Items, &pb.TrashItem{
			OriginalPath: item.OriginalPath,
			TrashPath:    item.TrashPath,
			TrashedAt:    item.TrashedAt.Unix(),
			Size:         item.Size,
		})
	}
	return
}

func (a *api) RestoreFromTrash(ctx context.Context, req *pb.RestoreFromTrashRequest) (rsp *pb.RestoreFromTrashResponse, err error) {
	rsp = &pb.RestoreFromTrashResponse{Success: true}
	for _, trashPath := range req.TrashPaths {
		if e := a.im.RestoreFromTrash(trashPath); e != nil {
			rsp.Success = false
			rsp.Message = fmt.Sprintf("restore from trash error: %v", e)
			return
		}
	}
	return
}

func (a *api) EmptyTrash(ctx context.Context, req *pb.EmptyTrashRequest) (rsp *pb.EmptyTrashResponse, err error) {
	rsp = &pb.EmptyTrashResponse{Success: true}
	if e := a.im.EmptyTrash(); e != nil {
		rsp.Success = false
		rsp.Message = e.Error()
	}
	return
}

func (a *api) RebuildIndex(req *pb.RebuildIndexRequest, stream pb.ImgSyncer_RebuildIndexServer) error {
	err := a.im.RebuildIndex(func(found int) {
		stream.Send(&pb.RebuildIndexResponse{
			Success:    true,
			TotalFound: int32(found),
		})
	})
	if err != nil {
		stream.Send(&pb.RebuildIndexResponse{
			Success:    false,
			Message:    err.Error(),
			IsFinished: true,
		})
		return nil
	}
	store := a.im.Store()
	var total int32
	if store != nil {
		total = int32(store.PhotoCount())
	}
	stream.Send(&pb.RebuildIndexResponse{
		Success:    true,
		TotalFound: total,
		IsFinished: true,
	})
	return nil
}

func (a *api) GetIndexStats(ctx context.Context, req *pb.GetIndexStatsRequest) (rsp *pb.GetIndexStatsResponse, err error) {
	rsp = &pb.GetIndexStatsResponse{Success: true}
	store := a.im.Store()
	if store == nil {
		rsp.Success = false
		rsp.Message = "local store not available"
		return
	}
	rsp.TotalPhotos = store.PhotoCount()
	rsp.CacheSizeBytes = store.CacheSizeBytes()
	rsp.LastIndexTimestamp = store.LastIndexTimestamp()
	return
}

func (a *api) ClearThumbnailCache(ctx context.Context, req *pb.ClearThumbnailCacheRequest) (rsp *pb.ClearThumbnailCacheResponse, err error) {
	rsp = &pb.ClearThumbnailCacheResponse{Success: true}
	store := a.im.Store()
	if store == nil {
		rsp.Success = false
		rsp.Message = "local store not available"
		return
	}
	rsp.FreedBytes = store.ClearAllThumbs()
	return
}

func isVideo(name string) bool {
	ext := filepath.Ext(name)
	switch ext {
	case ".mp4", ".avi", ".rmvb", ".rm", ".flv", ".wmv", ".mkv", ".mov", ".mpg", ".mpeg", ".3gp", ".3g2", ".asf", ".asx", ".vob", ".m2ts", ".mts", ".ts":
		return true
	}
	return false
}
