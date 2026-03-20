BUILD_VERSION   := $(shell git describe --tags 2>/dev/null || echo "dev")
GIT_COMMIT_SHA1 := $(shell git rev-parse HEAD)
BUILD_TIME      := $(shell date "+%F %T")
BUILD_NAME      := lumina_server
VERSION_PACKAGE_NAME := github.com/fregie/PrintVersion
GOPATH          := $(shell go env GOPATH)
export PATH     := $(GOPATH)/bin:$(HOME)/.pub-cache/bin:$(PATH)

DESCRIBE := lumina grpc server

.DEFAULT_GOAL := mac

.PHONY: prebuild protobuf server server-android server-ios server-mac server-linux server-windows android ios mac linux windows apk ipa testflight testflight-quick test

prebuild:
	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

protobuf:
	protoc -I. --go_out . --go_opt paths=source_relative \
		--go-grpc_out . --go-grpc_opt paths=source_relative \
		--dart_out=grpc:lib \
		proto/*.proto

server:
	CGO_ENABLED=0 go build -ldflags "\
		-X '${VERSION_PACKAGE_NAME}.Version=${BUILD_VERSION}' \
		-X '${VERSION_PACKAGE_NAME}.BuildTime=${BUILD_TIME}' \
		-X '${VERSION_PACKAGE_NAME}.GitCommitSHA1=${GIT_COMMIT_SHA1}' \
		-X '${VERSION_PACKAGE_NAME}.Describe=${DESCRIBE}' \
		-X '${VERSION_PACKAGE_NAME}.Name=${BUILD_NAME}'" \
    -o server/output/${BUILD_NAME} ./server

server-android: protobuf
	CGO_ENABLED=0 gomobile bind -tags mobile -target=android -androidapi 24 -ldflags "-s -w" -o android/app/libs/server.aar ./server/run

server-ios: protobuf
	CGO_ENABLED=0 gomobile bind -tags mobile -target=ios -ldflags "-s -w" -o ios/Frameworks/RUN.xcframework ./server/run

server-mac: protobuf
	@mkdir -p build/desktop
	CGO_ENABLED=1 go build -buildmode=c-shared \
		-o build/desktop/liblumina_server.dylib ./server/ffi

server-linux: protobuf
	@mkdir -p build/desktop
	CGO_ENABLED=1 go build -buildmode=c-shared \
		-o build/desktop/liblumina_server.so ./server/ffi

server-windows: protobuf
	@mkdir -p build/desktop
	CGO_ENABLED=1 GOOS=windows GOARCH=amd64 CC=x86_64-w64-mingw32-gcc go build -buildmode=c-shared \
		-o build/desktop/lumina_server.dll ./server/ffi

android: server-android
mac: server-mac
ios: server-ios
linux: server-linux
windows: server-windows

apk: server-android
	flutter build apk --release --obfuscate --split-debug-info=./debug-info

ipa: server-ios
	flutter build ipa --no-tree-shake-icons --obfuscate --split-debug-info=./debug-info

app-mac: server-mac
	flutter build macos --release

app-linux: server-linux
	flutter build linux --release

app-windows: server-windows
	flutter build windows --release

testflight:
	./deploy-testflight.sh

testflight-quick:
	./deploy-testflight.sh --skip-server

test:
	docker-compose -f test/docker-compose.yml up -d --build
	sleep 3
	go test -v ./server/api -p 1 -failfast
	go test -v ./server/drive -p 1 -failfast
	docker-compose -f test/docker-compose.yml down
