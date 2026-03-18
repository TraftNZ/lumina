package api

import (
	"context"
	"fmt"
	"io"
	"path/filepath"
	"strings"
	"time"

	pb "github.com/traftai/lumina/proto"
	"github.com/traftai/lumina/server/imgmanager"
)

type api struct {
	im       *imgmanager.ImgManager
	httpPort int

	pb.UnimplementedLuminaServer
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

func (a *api) FilterNotUploaded(stream pb.Lumina_FilterNotUploadedServer) error {
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
			found := false
			if info.ContentHash != "" {
				found = all[encodeName(t, info.Name, info.ContentHash)]
			}
			if !found {
				found = all[encodeName(t, info.Name, "")]
			}
			if !found {
				found = all[legacyEncodeName(t, info.Name)]
			}
			if !found {
				found = all[info.Name]
			}
			if !found {
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

func (a *api) MoveToLocked(ctx context.Context, req *pb.MoveToLockedRequest) (rsp *pb.MoveToLockedResponse, err error) {
	rsp = &pb.MoveToLockedResponse{Success: true}
	for _, path := range req.Paths {
		if e := a.im.MoveToLocked(path); e != nil {
			rsp.Success = false
			rsp.Message = fmt.Sprintf("move to locked error: %v", e)
			return
		}
	}
	return
}

func (a *api) ListLocked(ctx context.Context, req *pb.ListLockedRequest) (rsp *pb.ListLockedResponse, err error) {
	rsp = &pb.ListLockedResponse{Success: true}
	items, e := a.im.ListLocked(int(req.Offset), int(req.MaxReturn))
	if e != nil {
		rsp.Success = false
		rsp.Message = e.Error()
		return
	}
	rsp.Items = make([]*pb.TrashItem, len(items))
	for i, item := range items {
		rsp.Items[i] = &pb.TrashItem{
			OriginalPath: item.OriginalPath,
			TrashPath:    item.TrashPath,
			TrashedAt:    item.TrashedAt.Unix(),
			Size:         item.Size,
		}
	}
	return
}

func (a *api) RestoreFromLocked(ctx context.Context, req *pb.RestoreFromLockedRequest) (rsp *pb.RestoreFromLockedResponse, err error) {
	rsp = &pb.RestoreFromLockedResponse{Success: true}
	for _, lockedPath := range req.LockedPaths {
		if e := a.im.RestoreFromLocked(lockedPath); e != nil {
			rsp.Success = false
			rsp.Message = fmt.Sprintf("restore from locked error: %v", e)
			return
		}
	}
	return
}

func (a *api) UpdatePhotoLabels(ctx context.Context, req *pb.UpdatePhotoLabelsRequest) (rsp *pb.UpdatePhotoLabelsResponse, err error) {
	rsp = &pb.UpdatePhotoLabelsResponse{Success: true}
	store := a.im.Store()
	if store == nil {
		rsp.Success = false
		rsp.Message = "local store not available"
		return
	}
	if updateErr := store.UpdateLabels(req.Path, req.Labels, req.FaceIDs, req.Text); updateErr != nil {
		rsp.Success = false
		rsp.Message = updateErr.Error()
		return
	}
	return
}

func (a *api) SearchPhotos(ctx context.Context, req *pb.SearchPhotosRequest) (rsp *pb.SearchPhotosResponse, err error) {
	rsp = &pb.SearchPhotosResponse{Success: true}
	store := a.im.Store()
	if store == nil {
		rsp.Success = false
		rsp.Message = "local store not available"
		return
	}
	rsp.Paths = store.SearchLabels(req.Query)
	return
}

func (a *api) GetUnlabeledPhotos(ctx context.Context, req *pb.GetUnlabeledPhotosRequest) (rsp *pb.GetUnlabeledPhotosResponse, err error) {
	rsp = &pb.GetUnlabeledPhotosResponse{Success: true}
	store := a.im.Store()
	if store == nil {
		rsp.Success = false
		rsp.Message = "local store not available"
		return
	}
	limit := int(req.Limit)
	if limit <= 0 {
		limit = 50
	}
	rsp.Paths = store.GetUnlabeledPaths(limit)
	return
}

func (a *api) GetLabelSummary(ctx context.Context, req *pb.GetLabelSummaryRequest) (rsp *pb.GetLabelSummaryResponse, err error) {
	rsp = &pb.GetLabelSummaryResponse{Success: true}
	store := a.im.Store()
	if store == nil {
		rsp.Success = false
		return
	}
	summary := store.GetLabelSummary()
	rsp.FaceCount = int32(summary.FaceCount)
	rsp.FaceSamplePath = summary.FaceSample
	rsp.Labels = make([]*pb.LabelSummaryItem, 0, len(summary.Labels))
	for _, l := range summary.Labels {
		rsp.Labels = append(rsp.Labels, &pb.LabelSummaryItem{
			Label:      l.Label,
			Count:      int32(l.Count),
			SamplePath: l.SamplePath,
		})
	}
	return
}

func isVideo(name string) bool {
	ext := strings.ToLower(filepath.Ext(name))
	switch ext {
	case ".mp4", ".avi", ".rmvb", ".rm", ".flv", ".wmv", ".mkv", ".mov", ".mpg", ".mpeg", ".3gp", ".3g2", ".asf", ".asx", ".vob", ".m2ts", ".mts", ".ts":
		return true
	}
	return false
}
