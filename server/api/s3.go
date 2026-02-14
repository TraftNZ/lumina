package api

import (
	"context"
	"fmt"

	pb "github.com/fregie/img_syncer/proto"
	s3drive "github.com/fregie/img_syncer/server/drive/s3"
)

func (a *api) SetDriveS3(ctx context.Context, req *pb.SetDriveS3Request) (rsp *pb.SetDriveS3Response, e error) {
	rsp = &pb.SetDriveS3Response{Success: true}
	if req.Endpoint == "" && req.Region == "" {
		rsp.Success, rsp.Message = false, "param error: endpoint and region are both empty"
		return
	}
	if req.AccessKeyId == "" || req.SecretAccessKey == "" {
		rsp.Success, rsp.Message = false, "param error: access key ID or secret access key is empty"
		return
	}
	if req.Bucket == "" {
		rsp.Success, rsp.Message = false, "param error: bucket is empty"
		return
	}
	d := s3drive.NewS3Drive(req.Endpoint, req.Region, req.AccessKeyId, req.SecretAccessKey)
	d.SetBucket(req.Bucket)
	configHash := fmt.Sprintf("s3://%s/%s/%s", req.Endpoint, req.Bucket, req.Root)
	a.im.SwitchDrive(d, configHash)
	if req.Root != "" {
		d.SetRootPath(req.Root)
	}
	return
}

func (a *api) ListDriveS3Buckets(ctx context.Context, req *pb.ListDriveS3BucketsRequest) (rsp *pb.ListDriveS3BucketsResponse, e error) {
	rsp = &pb.ListDriveS3BucketsResponse{Success: true}
	dri := a.im.Drive()
	if dri == nil {
		rsp.Success, rsp.Message = false, "drive is not set"
		return
	}
	s3d, ok := dri.(*s3drive.S3Drive)
	if !ok {
		rsp.Success, rsp.Message = false, "drive is not S3"
		return
	}
	buckets, err := s3d.ListBuckets(ctx)
	if err != nil {
		rsp.Success, rsp.Message = false, fmt.Sprintf("list buckets failed: %s", err.Error())
		return
	}
	rsp.Buckets = buckets
	return
}
