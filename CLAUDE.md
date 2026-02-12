# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pho is a serverless photo sync and viewing app. It uses a **Flutter** frontend with an **embedded Go gRPC server** compiled via gomobile (AAR for Android, xcframework for iOS). The server runs on localhost with a dynamically allocated port (10000-20000 range). No external server or database is required.

Supported storage backends: Samba (SMB), WebDAV, NFS, Baidu Netdisk.

## Build Commands

```bash
# Prerequisites - install protobuf code generators
make prebuild

# Generate gRPC code from proto definitions (both Go and Dart)
make protobuf

# Build standalone Go server binary
make server

# Build mobile libraries (gomobile)
make server-aar    # Android AAR
make server-ios    # iOS xcframework

# Build apps (with obfuscation)
make apk           # Android
make ipa           # iOS

# Flutter
flutter pub get
flutter analyze
```

## Testing

Tests are Go integration tests requiring Docker Compose services (SMB, WebDAV, NFS containers):

```bash
make test                                          # Full: start services, test, teardown
go test -v ./server/api -p 1 -failfast            # API tests only (services must be running)
go test -v ./server/drive -p 1 -failfast           # Drive tests only
docker compose -f test/docker-compose.yml up -d    # Start test services manually
```

## Architecture

### Hybrid App Pattern
- Flutter UI communicates with an embedded Go server over gRPC on localhost
- Go server is compiled to native mobile libraries via `golang.org/x/mobile/cmd/gomobile`
- Platform binding: Android `MainActivity.kt` and iOS `AppDelegate.swift` start the Go server and pass the port back to Flutter

### Key Directories
- `lib/` — Flutter/Dart UI code (Provider for state management, ARB localization: en/zh)
- `server/` — Go backend: `api/` (gRPC handlers), `drive/` (storage drivers), `imgmanager/` (photo management), `run/` (mobile entry point), `main.go` (standalone entry)
- `proto/` — Protobuf definitions (source of truth for API contract)
- `test/` — Docker Compose config for integration test services

### Storage Driver System
Pluggable `drive` interface in `server/drive/` with implementations for each backend. Photos are stored in `YYYY/MM/DD` directory structure with thumbnails in a `.thumbnail/` subdirectory mirroring the same layout.

### Sync Flow
Incremental sync via `FilterNotUploaded` streaming RPC — the client sends local photo hashes, the server responds with which ones are missing from remote storage.

### App Navigation
3 visible tabs: Local Photos, Cloud Photos, Sync. Settings accessed via navigation from within tabs.

## Proto Workflow
When modifying the API, edit `.proto` files in `proto/`, then run `make protobuf` to regenerate both `server/proto/` (Go) and `lib/proto/` (Dart).

## Dependencies
- **Dart**: `pubspec.yaml` — all packages from pub.dev
- **Go**: `go.mod` — includes a fork replacement for `go-nfs-client`
- **Flutter SDK**: >=3.8.0 <4.0.0
- **Go**: 1.26
- **Android**: minSdk 24, Kotlin 2.1.0, AGP 8.7.3, Gradle 8.11.1
- **iOS**: 13.0+
