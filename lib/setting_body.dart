import 'dart:io';
import 'package:flutter/material.dart';
import 'package:img_syncer/choose_album_route.dart';
import 'package:img_syncer/setting_storage_route.dart';
import 'package:img_syncer/background_sync_route.dart';
import 'package:img_syncer/theme.dart';
import 'package:img_syncer/global.dart';

class SettingBody extends StatelessWidget {
  const SettingBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          l10n.settings,
          style: textTheme.headlineMedium,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.md, bottom: AppSpacing.xs),
            child: Text(
              l10n.storageSetting,
              style: textTheme.titleSmall?.copyWith(color: colorScheme.primary),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading:
                      Icon(Icons.folder_outlined, color: colorScheme.primary),
                  title: Text(l10n.localFolder),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ChooseAlbumRoute()),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading:
                      Icon(Icons.cloud_outlined, color: colorScheme.primary),
                  title: Text(l10n.cloudStorage),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingStorageRoute(),
                        ));
                  },
                ),
              ],
            ),
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.only(
                  left: AppSpacing.md, bottom: AppSpacing.xs),
              child: Text(
                l10n.sync,
                style:
                    textTheme.titleSmall?.copyWith(color: colorScheme.primary),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.cloud_sync_outlined,
                    color: colorScheme.primary),
                title: Text(l10n.backgroundSync),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const BackgroundSyncSettingRoute()),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.md, bottom: AppSpacing.xs),
            child: Text(
              l10n.about,
              style: textTheme.titleSmall?.copyWith(color: colorScheme.primary),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading:
                      Icon(Icons.info_outline, color: colorScheme.primary),
                  title: const Text('Lumina'),
                  subtitle: Text('${l10n.version} 1.0.0'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
