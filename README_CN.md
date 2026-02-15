<br/><br/><p align="center">
<img src="assets/icon/lumina_icon.png" width="150">
</p>
<h3 align="center">
Lumina - 一个用于查看和同步照片的无服务端应用
</h3>
<p align="center">
  <img src="https://github.com/zhupengjia/pho/actions/workflows/go_test.yml/badge.svg">
</p>
<p align="center">
  <a href="README_CN.md">中文</a> | <a href="README.md">English</a>
</p>

### 介绍

Lumina 是一款无服务端的照片同步和查看应用。它使用 Flutter 前端与嵌入式 Go gRPC 服务器（通过 gomobile 编译为 Android AAR / iOS xcframework），服务器运行在本地 localhost 上，无需外部服务器或数据库。

该应用旨在替代手机自带的相册应用，并能够将照片增量同步到网络储存，试图做到简洁而优秀的体验。

### 功能

- 本地照片查看
- 云端照片查看
- 增量同步照片到云端
- 后台定期同步
- 无数据库，无服务端
- 以时间组织云端存储的目录结构
- 支持上传和浏览视频
- 地点 — 在地图上按城市浏览照片（离线地理编码）

### 支持的网络储存

- [x] Samba (SMB)
- [x] WebDAV
- [x] NFS
- [x] S3 兼容存储 (AWS S3, MinIO, Backblaze B2 等)

### 安装

[下载 APK](https://github.com/zhupengjia/pho/releases)

### 截图

<p align="left">
<img src="assets/screenshot/Screenshots.png" >
</p>

### 构建

```bash
# 安装 protobuf 代码生成器
make prebuild

# 从 proto 定义生成 gRPC 代码（Go 和 Dart）
make protobuf

# 构建独立的 Go 服务端
make server

# 构建移动端库 (gomobile)
make server-aar    # Android AAR
make server-ios    # iOS xcframework

# 构建应用
make apk           # Android
make ipa           # iOS
```

### 测试

测试为 Go 集成测试，需要 Docker Compose 服务（SMB、WebDAV、NFS 容器）：

```bash
make test                                          # 完整流程：启动服务、测试、关闭
go test -v ./server/api -p 1 -failfast            # 仅 API 测试（需服务已运行）
go test -v ./server/drive -p 1 -failfast           # 仅 Drive 测试
docker compose -f test/docker-compose.yml up -d    # 手动启动测试服务
```

### 文件储存逻辑

本着尽可能简单的逻辑来储存文件，以时间为目录结构，以文件名为文件名储存源文件。在根目录创建一个 `.thumbnail` 目录来储存生成的缩略图，缩略图的目录结构与源文件相同。

你可以随时以其他形式利用你备份上去的照片，而不用依赖此应用。

目录结构示意图：
```bash
├── 2022
│   ├── 07
│   │   ├── 02
│   │   │   ├── 20220702_100940.JPG
│   │   │   ├── 20220702_111416.JPG
│   │   │   └── 20220702_111508.JPG
│   │   └── 03
│   │       ├── 20220703_101923.DNG
│   │       ├── 20220703_112336.DNG
│   │       └── 20220703_112338.DNG
├── 2023
│   └── 01
│       └── 03
│           ├── 20230103_112348.JPG
│           ├── 20230103_124634.JPG
│           └── 20230103_124918.DNG
└── .thumbnail
     └── 2022
         └── 07
             ├── 02
             │   ├── 20220702_100940.JPG
             │   ├── 20220702_111416.JPG
             │   └── 20220702_111508.JPG
             └── 03
                 ├── 20220703_101923.DNG
                 ├── 20220703_112336.DNG
                 └── 20220703_112338.DNG
```

### Roadmap

- [x] 支持放大/缩小图片
- [x] 支持上传/浏览视频
- [x] 支持 NFS
- [x] 支持 S3 兼容存储
- [x] 支持 iOS 端
- [ ] 支持 Desktop 端
- [x] 支持中英文

### 贡献

欢迎在 issue 中沟通交流，提出你的 pull request。

### 致谢

本项目基于 [fregie/pho](https://github.com/fregie/pho) 开发，感谢 [fregie](https://github.com/fregie) 的出色工作和开源贡献。

### License

[MIT](LICENSE)
