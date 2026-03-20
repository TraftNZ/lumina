package api

import (
	"context"
	"errors"
	"fmt"
	"time"

	pb "github.com/traftai/lumina/proto"
	"github.com/traftai/lumina/server/drive/cloudreve"
	"github.com/traftai/lumina/server/localstore"
)

func (a *api) SetDriveCloudreve(ctx context.Context, req *pb.SetDriveCloudrveRequest) (rsp *pb.SetDriveCloudrveResponse, e error) {
	rsp = &pb.SetDriveCloudrveResponse{Success: true}
	if req.Server == "" {
		rsp.Success, rsp.Message = false, "param error: server is empty"
		return
	}
	if req.Email == "" || req.Password == "" {
		rsp.Success, rsp.Message = false, "param error: email or password is empty"
		return
	}

	cloudreve.SetLogDir(a.im.Store().BaseDataDir())
	d := cloudreve.NewCloudreveDrive(req.Server, req.Email, req.Password)

	configHash := fmt.Sprintf("cloudreve://%s@%s/%s", req.Email, req.Server, req.Root)
	dataDir := localstore.DriveDataDir(a.im.Store().BaseDataDir(), configHash)

	d.SetOnTokenUpdate(func(refreshToken string, refreshExp time.Time) {
		localstore.SaveTokenFile(dataDir, localstore.SavedToken{
			RefreshToken: refreshToken,
			RefreshExp:   refreshExp,
		})
	})

	if req.SessionId != "" && req.Otp != "" {
		if err := d.Login2FA(req.SessionId, req.Otp); err != nil {
			rsp.Success, rsp.Message = false, fmt.Sprintf("2FA failed: %s", err.Error())
			return
		}
	} else {
		saved, err := localstore.LoadTokenFile(dataDir)
		if err == nil && saved.RefreshToken != "" && time.Now().Before(saved.RefreshExp) {
			d.SetTokens(saved.RefreshToken, saved.RefreshExp)
			if err := d.RefreshAuth(); err == nil {
				goto authDone
			}
		}

		if err := d.Login(); err != nil {
			var err2fa *cloudreve.ErrRequire2FA
			if errors.As(err, &err2fa) {
				rsp.Require_2Fa = true
				rsp.SessionId = err2fa.SessionID
				return
			}
			rsp.Success, rsp.Message = false, fmt.Sprintf("login failed: %s", err.Error())
			return
		}
	}

authDone:
	if req.Root != "" {
		if err := d.SetRootPath(req.Root); err != nil {
			rsp.Success, rsp.Message = false, fmt.Sprintf("set root path failed: %s", err.Error())
			return
		}
	}

	a.im.SwitchDrive(d, configHash)
	return
}

func (a *api) ListDriveCloudrveDir(ctx context.Context, req *pb.ListDriveClourdreveDirRequest) (rsp *pb.ListDriveClourdreveDirResponse, e error) {
	rsp = &pb.ListDriveClourdreveDirResponse{Success: true}
	dri := a.im.Drive()
	if dri == nil {
		rsp.Success, rsp.Message = false, "drive is not set"
		return
	}
	cd, ok := dri.(*cloudreve.Cloudreve)
	if !ok {
		rsp.Success, rsp.Message = false, "drive is not cloudreve"
		return
	}
	if req.Dir == "" {
		req.Dir = "/"
	}
	dirs, err := cd.ListDir(req.Dir)
	if err != nil {
		rsp.Success, rsp.Message = false, fmt.Sprintf("list dir failed: %s", err.Error())
		return
	}
	rsp.Dirs = dirs
	return
}
