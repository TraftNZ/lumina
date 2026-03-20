package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"unsafe"

	"github.com/traftai/lumina/server/api"
	"github.com/traftai/lumina/server/imgmanager"
	"github.com/traftai/lumina/server/localstore"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	pb "github.com/traftai/lumina/proto"
)

var (
	Info  *log.Logger
	Error *log.Logger
)

func init() {
	Info = log.New(os.Stdout, "[INFO] ", log.Ldate|log.Ltime)
	Error = log.New(os.Stderr, "[ERROR] ", log.Ldate|log.Ltime|log.Lshortfile)
	_ = log.New(io.Discard, "[DEBUG] ", log.Ldate|log.Ltime|log.Lshortfile)
}

//export StartServer
func StartServer(dataDir *C.char, cacheDir *C.char) *C.char {
	goDataDir := C.GoString(dataDir)
	goCacheDir := C.GoString(cacheDir)
	_ = goCacheDir

	opt := imgmanager.Option{}

	if goDataDir != "" {
		store, err := localstore.New(goDataDir)
		if err != nil {
			Info.Printf("Failed to create local store (continuing without): %v", err)
		} else {
			opt.LocalStore = store
		}
	}

	imgManager := imgmanager.NewImgManager(opt)
	var grpcLis, httpLis net.Listener
	var err error
	var grpcPort, httpPort int
	for start := 10000; start < 20000; start++ {
		grpcLis, err = net.Listen("tcp", fmt.Sprintf("0.0.0.0:%d", start))
		if err != nil {
			Info.Printf("Listen on %d failed, try next port", start)
			continue
		} else {
			grpcPort = start
			break
		}
	}
	if err != nil {
		Error.Printf("Listen on all port failed, err: %v", err)
		return C.CString("")
	}

	for start := 10000; start < 20000; start++ {
		httpLis, err = net.Listen("tcp", fmt.Sprintf("0.0.0.0:%d", start))
		if err != nil {
			Info.Printf("Listen on %d failed, try next port", start)
			continue
		} else {
			httpPort = start
			break
		}
	}
	if err != nil {
		Error.Printf("Listen on all port failed, err: %v", err)
		return C.CString("")
	}

	a := api.NewApi(imgManager)
	a.SetHttpPort(httpPort)
	grpcServer := grpc.NewServer()
	pb.RegisterLuminaServer(grpcServer, a)
	reflection.Register(grpcServer)

	Info.Printf("Listening grpc on %s", grpcLis.Addr().String())
	go grpcServer.Serve(grpcLis)
	Info.Printf("Listening http on %s", httpLis.Addr().String())
	go http.Serve(httpLis, a.HttpHandler())

	return C.CString(fmt.Sprintf("%d,%d", grpcPort, httpPort))
}

//export FreeString
func FreeString(s *C.char) {
	C.free(unsafe.Pointer(s))
}

func main() {}
