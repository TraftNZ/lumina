// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get library => 'Library';

  @override
  String get sync => 'Sync';

  @override
  String get cloudSync => 'Cloud sync';

  @override
  String get localFolder => 'Local folder';

  @override
  String get cloudStorage => 'Cloud storage';

  @override
  String get backgroundSync => 'Background sync';

  @override
  String get notSync => 'not sync';

  @override
  String get unsynchronizedPhotos => 'Unsynchronized photos';

  @override
  String get date => 'Date';

  @override
  String get delete => 'Delete';

  @override
  String get photos => 'photos';

  @override
  String get deleteThisPhoto => 'Delete this photo';

  @override
  String get deleteThisPhotos => 'Delete this photos';

  @override
  String get cantBeUndone => 'This action can\'t be undone';

  @override
  String get download => 'Download';

  @override
  String get upload => 'Upload';

  @override
  String get success => 'success';

  @override
  String get pics => 'pics';

  @override
  String get choose => 'Choose';

  @override
  String get stop => 'Stop';

  @override
  String get uploading => 'Uploading';

  @override
  String get downloading => 'Downloading';

  @override
  String get uploadFailed => 'Upload failed';

  @override
  String get uploaded => 'Uploaded';

  @override
  String get notUploaded => 'Not uploaded';

  @override
  String get chooseAlbum => 'Choose album';

  @override
  String get storageSetting => 'Storage setting';

  @override
  String get remoteStorageType => 'Remote storage type';

  @override
  String get samvbaServerAddress => 'Samba server address';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get share => 'Share';

  @override
  String get rootPath => 'Root path(Your photos will be uploaded to this path)';

  @override
  String get optional => 'optional';

  @override
  String get testStorage => 'Test storage';

  @override
  String get save => 'Save';

  @override
  String get enableBackgroundSync => 'Enable background sync';

  @override
  String get syncOnlyOnWifi => 'Sync only on WIFI';

  @override
  String get syncInterval => 'Sync interval';

  @override
  String get minite => 'minite';

  @override
  String get hour => 'hour';

  @override
  String get day => 'day';

  @override
  String get week => 'week';

  @override
  String get chineseday => '';

  @override
  String get yes => 'Yes';

  @override
  String get cancel => 'Cancel';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get setLocalFirst => 'Please set local folder first';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get storageNotSetted => 'Remote storage is not setted,please set it first';

  @override
  String get successfullyUpload => 'Successfully upload';

  @override
  String get testSuccess => 'Test success,you can save now';

  @override
  String get connectFailed => 'Storage connection failed';

  @override
  String get selectRoot => 'Select root path';

  @override
  String get currentPath => 'Current path';

  @override
  String get s3Storage => 'S3 Storage';

  @override
  String get s3Endpoint => 'Endpoint';

  @override
  String get s3Region => 'Region';

  @override
  String get s3AccessKeyId => 'Access Key ID';

  @override
  String get s3SecretAccessKey => 'Secret Access Key';

  @override
  String get s3Bucket => 'Bucket';

  @override
  String get refreshingPleaseWait => 'Comparing your local and cloud photos, if there are many photos, it may take some time. Please be patient......';

  @override
  String get setRemoteStroage => 'Please set cloud storage first';

  @override
  String get needPermision => 'Need permission to access photos';

  @override
  String get gotoSystemSetting => 'You can go to system settings to change the permission';

  @override
  String get openSetting => 'Open settings';

  @override
  String get settings => 'Settings';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get allSynced => 'All photos synced!';

  @override
  String backingUpPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'photos',
      one: 'photo',
    );
    return 'Backing up $count $_temp0';
  }

  @override
  String nRemaining(int count) {
    return '$count remaining';
  }

  @override
  String get collections => 'Collections';

  @override
  String get trash => 'Trash';

  @override
  String get lockedFolder => 'Locked Folder';

  @override
  String get deleteUploadedPhotos => 'Delete uploaded photos';

  @override
  String deleteUploadedPhotosConfirm(int count) {
    return 'Delete $count local copies? Cloud copies will be kept.';
  }

  @override
  String get noUploadedPhotosToDelete => 'No uploaded photos to delete';

  @override
  String get movedToTrash => 'Moved to trash';

  @override
  String get restore => 'Restore';

  @override
  String get emptyTrash => 'Empty trash';

  @override
  String get emptyTrashConfirm => 'Permanently delete all items in trash?';

  @override
  String get trashEmpty => 'Trash is empty';

  @override
  String get permanentlyDelete => 'Permanently delete';

  @override
  String get trashAutoDeleteNote => 'Items in trash are automatically deleted after 30 days';

  @override
  String get lockedFolderDescription => 'Photos moved here are hidden and require authentication to view';

  @override
  String get authenticate => 'Authenticate';

  @override
  String get authenticationFailed => 'Authentication failed';

  @override
  String get biometricNotAvailable => 'Biometric authentication not available';

  @override
  String get moveToLockedFolder => 'Hide';

  @override
  String get noPhotosSelected => 'No photos selected';

  @override
  String get stillInGallery => 'still in gallery';

  @override
  String get removeFromLockedFolder => 'Remove from Locked Folder';

  @override
  String get lockedFolderPin => 'Locked Folder PIN';

  @override
  String get lockedFolderPinDescription => 'Set a PIN for the Locked Folder when biometrics are unavailable';

  @override
  String get setPin => 'Set PIN';

  @override
  String get changePin => 'Change PIN';

  @override
  String get removePin => 'Remove PIN';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get enterNewPin => 'Enter new PIN';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get pinSet => 'PIN has been set';

  @override
  String get pinRemoved => 'PIN has been removed';

  @override
  String get pinMismatch => 'PINs do not match';

  @override
  String get incorrectPin => 'Incorrect PIN';

  @override
  String get pinRequired => 'Please set a Locked Folder PIN in Settings first';

  @override
  String get security => 'Security';

  @override
  String get thumbnailCache => 'Thumbnail cache';

  @override
  String get clearCache => 'Clear cache';

  @override
  String cacheCleared(String size) {
    return 'Cache cleared, freed $size';
  }

  @override
  String get rebuildIndex => 'Rebuild photo index';

  @override
  String get rebuildingIndex => 'Rebuilding index...';

  @override
  String indexRebuilt(int count) {
    return 'Index rebuilt: $count photos indexed';
  }

  @override
  String get cacheManagement => 'Cache';

  @override
  String get deviceAlbums => 'Device Albums';

  @override
  String get places => 'Places';

  @override
  String get scanningPhotos => 'Scanning photos for locations...';

  @override
  String get noLocationData => 'No photos with location data';

  @override
  String photosInCity(int count) {
    return '$count photos';
  }

  @override
  String get yearInReview => 'Year in Review';
}
