import 'package:flutter/material.dart';
import 'package:lumina/storageform/smbform.dart';
import 'package:lumina/storageform/webdavform.dart';
import 'package:lumina/storageform/nfsform.dart';
import 'package:lumina/storageform/s3form.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/state_model.dart';
import 'package:lumina/global.dart';
import 'package:lumina/theme.dart';

class SettingStorageRoute extends StatefulWidget {
  const SettingStorageRoute({Key? key}) : super(key: key);

  @override
  SettingStorageRouteState createState() => SettingStorageRouteState();
}

Drive getDrive(String drive) {
  return driveName.entries
      .firstWhere((element) => element.value == drive,
          orElse: () => const MapEntry(Drive.smb, "SMB"))
      .key;
}

IconData _driveIcon(Drive drive) {
  switch (drive) {
    case Drive.smb:
      return Icons.storage;
    case Drive.webDav:
      return Icons.cloud_outlined;
    case Drive.nfs:
      return Icons.dns_outlined;
    case Drive.s3:
      return Icons.cloud_outlined;
  }
}

class SettingStorageRouteState extends State<SettingStorageRoute> {
  @protected
  Drive currentDrive = Drive.smb;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final drive = prefs.getString("drive");
      if (drive != null) {
        setState(() {
          currentDrive = getDrive(drive);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    late Widget form;
    switch (currentDrive) {
      case Drive.smb:
        form = const SMBForm();
        break;
      case Drive.webDav:
        form = const WebDavForm();
        break;
      case Drive.nfs:
        form = const NFSForm();
        break;
      case Drive.s3:
        form = const S3Form();
        break;
    }
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(l10n.storageSetting,
              style: Theme.of(context).textTheme.titleLarge),
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                DropdownMenu<Drive>(
                  expandedInsets: EdgeInsets.zero,
                  initialSelection: currentDrive,
                  label: Text(l10n.remoteStorageType),
                  leadingIcon: Icon(_driveIcon(currentDrive)),
                  onSelected: (Drive? value) {
                    if (value != null) {
                      setState(() {
                        currentDrive = value;
                      });
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.setString('drive', driveName[value]!);
                      });
                    }
                  },
                  dropdownMenuEntries: driveName.entries
                      .map((entry) => DropdownMenuEntry<Drive>(
                            value: entry.key,
                            label: entry.key == Drive.s3
                                ? l10n.s3Storage
                                : entry.value,
                            leadingIcon: Icon(_driveIcon(entry.key)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                form,
              ],
            )));
  }
}
