import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync'**
  String get cloudSync;

  /// No description provided for @localFolder.
  ///
  /// In en, this message translates to:
  /// **'Local folder'**
  String get localFolder;

  /// No description provided for @cloudStorage.
  ///
  /// In en, this message translates to:
  /// **'Cloud storage'**
  String get cloudStorage;

  /// No description provided for @backgroundSync.
  ///
  /// In en, this message translates to:
  /// **'Background sync'**
  String get backgroundSync;

  /// No description provided for @notSync.
  ///
  /// In en, this message translates to:
  /// **'not sync'**
  String get notSync;

  /// No description provided for @unsynchronizedPhotos.
  ///
  /// In en, this message translates to:
  /// **'Unsynchronized photos'**
  String get unsynchronizedPhotos;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'photos'**
  String get photos;

  /// No description provided for @deleteThisPhoto.
  ///
  /// In en, this message translates to:
  /// **'Delete this photo'**
  String get deleteThisPhoto;

  /// No description provided for @deleteThisPhotos.
  ///
  /// In en, this message translates to:
  /// **'Delete this photos'**
  String get deleteThisPhotos;

  /// No description provided for @cantBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action can\'t be undone'**
  String get cantBeUndone;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'success'**
  String get success;

  /// No description provided for @pics.
  ///
  /// In en, this message translates to:
  /// **'pics'**
  String get pics;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get uploading;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailed;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @notUploaded.
  ///
  /// In en, this message translates to:
  /// **'Not uploaded'**
  String get notUploaded;

  /// No description provided for @chooseAlbum.
  ///
  /// In en, this message translates to:
  /// **'Choose album'**
  String get chooseAlbum;

  /// No description provided for @storageSetting.
  ///
  /// In en, this message translates to:
  /// **'Storage setting'**
  String get storageSetting;

  /// No description provided for @remoteStorageType.
  ///
  /// In en, this message translates to:
  /// **'Remote storage type'**
  String get remoteStorageType;

  /// No description provided for @samvbaServerAddress.
  ///
  /// In en, this message translates to:
  /// **'Samba server address'**
  String get samvbaServerAddress;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @rootPath.
  ///
  /// In en, this message translates to:
  /// **'Root path(Your photos will be uploaded to this path)'**
  String get rootPath;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @testStorage.
  ///
  /// In en, this message translates to:
  /// **'Test storage'**
  String get testStorage;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @enableBackgroundSync.
  ///
  /// In en, this message translates to:
  /// **'Enable background sync'**
  String get enableBackgroundSync;

  /// No description provided for @syncOnlyOnWifi.
  ///
  /// In en, this message translates to:
  /// **'Sync only on WIFI'**
  String get syncOnlyOnWifi;

  /// No description provided for @syncInterval.
  ///
  /// In en, this message translates to:
  /// **'Sync interval'**
  String get syncInterval;

  /// No description provided for @minite.
  ///
  /// In en, this message translates to:
  /// **'minite'**
  String get minite;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hour;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get week;

  /// No description provided for @chineseday.
  ///
  /// In en, this message translates to:
  /// **''**
  String get chineseday;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @setLocalFirst.
  ///
  /// In en, this message translates to:
  /// **'Please set local folder first'**
  String get setLocalFirst;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @storageNotSetted.
  ///
  /// In en, this message translates to:
  /// **'Remote storage is not setted,please set it first'**
  String get storageNotSetted;

  /// No description provided for @successfullyUpload.
  ///
  /// In en, this message translates to:
  /// **'Successfully upload'**
  String get successfullyUpload;

  /// No description provided for @testSuccess.
  ///
  /// In en, this message translates to:
  /// **'Test success,you can save now'**
  String get testSuccess;

  /// No description provided for @connectFailed.
  ///
  /// In en, this message translates to:
  /// **'Storage connection failed'**
  String get connectFailed;

  /// No description provided for @selectRoot.
  ///
  /// In en, this message translates to:
  /// **'Select root path'**
  String get selectRoot;

  /// No description provided for @currentPath.
  ///
  /// In en, this message translates to:
  /// **'Current path'**
  String get currentPath;

  /// No description provided for @s3Storage.
  ///
  /// In en, this message translates to:
  /// **'S3 Storage'**
  String get s3Storage;

  /// No description provided for @s3Endpoint.
  ///
  /// In en, this message translates to:
  /// **'Endpoint'**
  String get s3Endpoint;

  /// No description provided for @s3Region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get s3Region;

  /// No description provided for @s3AccessKeyId.
  ///
  /// In en, this message translates to:
  /// **'Access Key ID'**
  String get s3AccessKeyId;

  /// No description provided for @s3SecretAccessKey.
  ///
  /// In en, this message translates to:
  /// **'Secret Access Key'**
  String get s3SecretAccessKey;

  /// No description provided for @s3Bucket.
  ///
  /// In en, this message translates to:
  /// **'Bucket'**
  String get s3Bucket;

  /// No description provided for @refreshingPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Comparing your local and cloud photos, if there are many photos, it may take some time. Please be patient......'**
  String get refreshingPleaseWait;

  /// No description provided for @setRemoteStroage.
  ///
  /// In en, this message translates to:
  /// **'Please set cloud storage first'**
  String get setRemoteStroage;

  /// No description provided for @needPermision.
  ///
  /// In en, this message translates to:
  /// **'Need permission to access photos'**
  String get needPermision;

  /// No description provided for @gotoSystemSetting.
  ///
  /// In en, this message translates to:
  /// **'You can go to system settings to change the permission'**
  String get gotoSystemSetting;

  /// No description provided for @openSetting.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSetting;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @allSynced.
  ///
  /// In en, this message translates to:
  /// **'All photos synced!'**
  String get allSynced;

  /// No description provided for @backingUpPhotos.
  ///
  /// In en, this message translates to:
  /// **'Backing up {count} {count, plural, =1{photo} other{photos}}'**
  String backingUpPhotos(int count);

  /// No description provided for @nRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} remaining'**
  String nRemaining(int count);

  /// No description provided for @collections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collections;

  /// No description provided for @trash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trash;

  /// No description provided for @lockedFolder.
  ///
  /// In en, this message translates to:
  /// **'Locked Folder'**
  String get lockedFolder;

  /// No description provided for @deleteUploadedPhotos.
  ///
  /// In en, this message translates to:
  /// **'Delete uploaded photos'**
  String get deleteUploadedPhotos;

  /// No description provided for @deleteUploadedPhotosConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} local copies? Cloud copies will be kept.'**
  String deleteUploadedPhotosConfirm(int count);

  /// No description provided for @noUploadedPhotosToDelete.
  ///
  /// In en, this message translates to:
  /// **'No uploaded photos to delete'**
  String get noUploadedPhotosToDelete;

  /// No description provided for @movedToTrash.
  ///
  /// In en, this message translates to:
  /// **'Moved to trash'**
  String get movedToTrash;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @emptyTrash.
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get emptyTrash;

  /// No description provided for @emptyTrashConfirm.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete all items in trash?'**
  String get emptyTrashConfirm;

  /// No description provided for @trashEmpty.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get trashEmpty;

  /// No description provided for @permanentlyDelete.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete'**
  String get permanentlyDelete;

  /// No description provided for @trashAutoDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Items in trash are automatically deleted after 30 days'**
  String get trashAutoDeleteNote;

  /// No description provided for @lockedFolderDescription.
  ///
  /// In en, this message translates to:
  /// **'Photos moved here are hidden and require authentication to view'**
  String get lockedFolderDescription;

  /// No description provided for @authenticate.
  ///
  /// In en, this message translates to:
  /// **'Authenticate'**
  String get authenticate;

  /// No description provided for @authenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authenticationFailed;

  /// No description provided for @biometricNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication not available'**
  String get biometricNotAvailable;

  /// No description provided for @moveToLockedFolder.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get moveToLockedFolder;

  /// No description provided for @noPhotosSelected.
  ///
  /// In en, this message translates to:
  /// **'No photos selected'**
  String get noPhotosSelected;

  /// No description provided for @stillInGallery.
  ///
  /// In en, this message translates to:
  /// **'still in gallery'**
  String get stillInGallery;

  /// No description provided for @removeFromLockedFolder.
  ///
  /// In en, this message translates to:
  /// **'Remove from Locked Folder'**
  String get removeFromLockedFolder;

  /// No description provided for @lockedFolderPin.
  ///
  /// In en, this message translates to:
  /// **'Locked Folder PIN'**
  String get lockedFolderPin;

  /// No description provided for @lockedFolderPinDescription.
  ///
  /// In en, this message translates to:
  /// **'Set a PIN for the Locked Folder when biometrics are unavailable'**
  String get lockedFolderPinDescription;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setPin;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @removePin.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN'**
  String get removePin;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @enterNewPin.
  ///
  /// In en, this message translates to:
  /// **'Enter new PIN'**
  String get enterNewPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @pinSet.
  ///
  /// In en, this message translates to:
  /// **'PIN has been set'**
  String get pinSet;

  /// No description provided for @pinRemoved.
  ///
  /// In en, this message translates to:
  /// **'PIN has been removed'**
  String get pinRemoved;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get pinMismatch;

  /// No description provided for @incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get incorrectPin;

  /// No description provided for @pinRequired.
  ///
  /// In en, this message translates to:
  /// **'Please set a Locked Folder PIN in Settings first'**
  String get pinRequired;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @thumbnailCache.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail cache'**
  String get thumbnailCache;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clearCache;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared, freed {size}'**
  String cacheCleared(String size);

  /// No description provided for @rebuildIndex.
  ///
  /// In en, this message translates to:
  /// **'Rebuild photo index'**
  String get rebuildIndex;

  /// No description provided for @rebuildingIndex.
  ///
  /// In en, this message translates to:
  /// **'Rebuilding index...'**
  String get rebuildingIndex;

  /// No description provided for @indexRebuilt.
  ///
  /// In en, this message translates to:
  /// **'Index rebuilt: {count} photos indexed'**
  String indexRebuilt(int count);

  /// No description provided for @cacheManagement.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get cacheManagement;

  /// No description provided for @deviceAlbums.
  ///
  /// In en, this message translates to:
  /// **'Device Albums'**
  String get deviceAlbums;

  /// No description provided for @places.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get places;

  /// No description provided for @scanningPhotos.
  ///
  /// In en, this message translates to:
  /// **'Scanning photos for locations...'**
  String get scanningPhotos;

  /// No description provided for @noLocationData.
  ///
  /// In en, this message translates to:
  /// **'No photos with location data'**
  String get noLocationData;

  /// No description provided for @photosInCity.
  ///
  /// In en, this message translates to:
  /// **'{count} photos'**
  String photosInCity(int count);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
