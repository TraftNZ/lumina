// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get local => '本地';

  @override
  String get cloud => '云端';

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
  String get baiduNetdisk => '百度网盘';

  @override
  String get baiduNetdiskLogin => '百度网盘登录';

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
}
