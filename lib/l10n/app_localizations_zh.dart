// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get library => '照片库';

  @override
  String get sync => '同步';

  @override
  String get cloudSync => '云端同步';

  @override
  String get localFolder => '本地相册';

  @override
  String get cloudStorage => '云端设置';

  @override
  String get backgroundSync => '后台同步';

  @override
  String get notSync => '张照片尚未同步';

  @override
  String get unsynchronizedPhotos => '未同步照片';

  @override
  String get date => '日期';

  @override
  String get delete => '删除';

  @override
  String get photos => '照片';

  @override
  String get deleteThisPhoto => '删除这张照片';

  @override
  String get deleteThisPhotos => '删除选中的照片';

  @override
  String get cantBeUndone => '该操作无法撤销';

  @override
  String get download => '下载';

  @override
  String get upload => '上传';

  @override
  String get success => '成功';

  @override
  String get pics => '照片';

  @override
  String get choose => '选择';

  @override
  String get stop => '停止';

  @override
  String get uploading => '上传中';

  @override
  String get downloading => '下载中';

  @override
  String get uploadFailed => '上传失败';

  @override
  String get uploaded => '已上传';

  @override
  String get notUploaded => '未上传';

  @override
  String get chooseAlbum => '选择相册';

  @override
  String get storageSetting => '网络储存设置';

  @override
  String get remoteStorageType => '网络储存类型';

  @override
  String get samvbaServerAddress => 'Samba服务器地址';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get share => '分享';

  @override
  String get rootPath => '储存根目录(照片会储存在该目录下)';

  @override
  String get optional => '可选';

  @override
  String get testStorage => '测试连接';

  @override
  String get save => '保存';

  @override
  String get enableBackgroundSync => '启用后台同步';

  @override
  String get syncOnlyOnWifi => '仅在连接WIFI时同步';

  @override
  String get syncInterval => '同步间隔';

  @override
  String get minite => '分钟';

  @override
  String get hour => '小时';

  @override
  String get day => '天';

  @override
  String get week => '周';

  @override
  String get chineseday => '日';

  @override
  String get yes => '确认';

  @override
  String get cancel => '取消';

  @override
  String get permissionDenied => '权限不足';

  @override
  String get setLocalFirst => '请先设置本地相册';

  @override
  String get downloadFailed => '下载失败';

  @override
  String get storageNotSetted => '网络储存未配置,请先配置网络储存';

  @override
  String get successfullyUpload => '成功上传';

  @override
  String get testSuccess => '连接成功,请点击保存';

  @override
  String get connectFailed => '连接失败';

  @override
  String get selectRoot => '选择根目录';

  @override
  String get currentPath => '当前目录';

  @override
  String get s3Storage => 'S3 存储';

  @override
  String get s3Endpoint => '端点';

  @override
  String get s3Region => '区域';

  @override
  String get s3AccessKeyId => 'Access Key ID';

  @override
  String get s3SecretAccessKey => 'Secret Access Key';

  @override
  String get s3Bucket => '存储桶';

  @override
  String get refreshingPleaseWait => '正在交叉对比你本地和云端的照片,如果照片数量较多可能耗时较久,请耐心等待......';

  @override
  String get setRemoteStroage => '请先点击云端设置设置网络储存';

  @override
  String get needPermision => '需要访问相册的权限';

  @override
  String get gotoSystemSetting => '请转至系统设置授予相册的权限';

  @override
  String get openSetting => '打开设置';

  @override
  String get settings => '设置';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get allSynced => '所有照片已同步！';

  @override
  String backingUpPhotos(int count) {
    return '正在备份 $count 张照片';
  }

  @override
  String nRemaining(int count) {
    return '剩余 $count 张';
  }

  @override
  String get collections => '合集';

  @override
  String get trash => '回收站';

  @override
  String get lockedFolder => '已锁定的文件夹';

  @override
  String get deleteUploadedPhotos => '删除已上传的照片';

  @override
  String deleteUploadedPhotosConfirm(int count) {
    return '删除 $count 张本地副本？云端副本将保留。';
  }

  @override
  String get noUploadedPhotosToDelete => '没有已上传的照片可删除';

  @override
  String get movedToTrash => '已移至回收站';

  @override
  String get restore => '恢复';

  @override
  String get emptyTrash => '清空回收站';

  @override
  String get emptyTrashConfirm => '永久删除回收站中的所有项目？';

  @override
  String get trashEmpty => '回收站为空';

  @override
  String get permanentlyDelete => '永久删除';

  @override
  String get trashAutoDeleteNote => '回收站中的项目将在30天后自动删除';

  @override
  String get lockedFolderDescription => '移至此处的照片将被隐藏，需要验证身份才能查看';

  @override
  String get authenticate => '验证身份';

  @override
  String get authenticationFailed => '身份验证失败';

  @override
  String get moveToLockedFolder => '移至已锁定的文件夹';

  @override
  String get removeFromLockedFolder => '从已锁定的文件夹移除';

  @override
  String get lockedFolderPin => '锁定文件夹 PIN';

  @override
  String get lockedFolderPinDescription => '当生物识别不可用时，使用 PIN 码访问锁定文件夹';

  @override
  String get setPin => '设置 PIN';

  @override
  String get changePin => '更改 PIN';

  @override
  String get removePin => '移除 PIN';

  @override
  String get enterPin => '输入 PIN';

  @override
  String get enterNewPin => '输入新 PIN';

  @override
  String get confirmPin => '确认 PIN';

  @override
  String get pinSet => 'PIN 已设置';

  @override
  String get pinRemoved => 'PIN 已移除';

  @override
  String get pinMismatch => '两次输入的 PIN 不一致';

  @override
  String get incorrectPin => 'PIN 不正确';

  @override
  String get pinRequired => '请先在设置中设置锁定文件夹 PIN';

  @override
  String get security => '安全';

  @override
  String get thumbnailCache => '缩略图缓存';

  @override
  String get clearCache => '清除缓存';

  @override
  String cacheCleared(String size) {
    return '缓存已清除，释放了 $size';
  }

  @override
  String get rebuildIndex => '重建照片索引';

  @override
  String get rebuildingIndex => '正在重建索引...';

  @override
  String indexRebuilt(int count) {
    return '索引重建完成：已索引 $count 张照片';
  }

  @override
  String get cacheManagement => '缓存';

  @override
  String get deviceAlbums => '设备相册';

  @override
  String get places => '地点';

  @override
  String get scanningPhotos => '正在扫描照片位置...';

  @override
  String get noLocationData => '没有包含位置信息的照片';

  @override
  String photosInCity(int count) {
    return '$count 张照片';
  }
}
