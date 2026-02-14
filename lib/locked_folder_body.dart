import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:img_syncer/global.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockedFolderBody extends StatefulWidget {
  const LockedFolderBody({Key? key}) : super(key: key);

  @override
  State<LockedFolderBody> createState() => _LockedFolderBodyState();
}

class _LockedFolderBodyState extends State<LockedFolderBody> {
  bool _authenticated = false;
  bool _authenticating = true;
  List<Map<String, dynamic>> _metadata = [];
  String _lockedDirPath = '';
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (!mounted) return;
    setState(() => _authenticating = true);
    final localAuth = LocalAuthentication();
    try {
      final canAuth = await localAuth.canCheckBiometrics || await localAuth.isDeviceSupported();
      if (!canAuth) {
        // No biometric/PIN available, grant access directly
        _authenticated = true;
        await _loadPhotos();
        if (mounted) setState(() => _authenticating = false);
        return;
      }
      final result = await localAuth.authenticate(
        localizedReason: l10n.authenticate,
      );
      if (!mounted) return;
      if (result) {
        _authenticated = true;
        await _loadPhotos();
      } else {
        Navigator.of(context).pop();
        return;
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarManager.showSnackBar(l10n.authenticationFailed);
      Navigator.of(context).pop();
      return;
    }
    if (mounted) setState(() => _authenticating = false);
  }

  Future<void> _loadPhotos() async {
    final appDir = await getApplicationDocumentsDirectory();
    _lockedDirPath = '${appDir.path}/locked_photos';
    final dir = Directory(_lockedDirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString('locked_photos') ?? '[]';
    _metadata = List<Map<String, dynamic>>.from(json.decode(existingJson));

    // Remove entries where file no longer exists
    final validMetadata = <Map<String, dynamic>>[];
    for (final item in _metadata) {
      final file = File('$_lockedDirPath/${item['filename']}');
      if (await file.exists()) {
        validMetadata.add(item);
      }
    }
    _metadata = validMetadata;
    await prefs.setString('locked_photos', json.encode(_metadata));
    if (mounted) setState(() {});
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  Future<void> _removeFromLockedFolder() async {
    final prefs = await SharedPreferences.getInstance();
    final toRemove = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
    for (final index in toRemove) {
      final item = _metadata[index];
      final file = File('$_lockedDirPath/${item['filename']}');
      if (await file.exists()) {
        await file.delete();
      }
      _metadata.removeAt(index);
    }
    await prefs.setString('locked_photos', json.encode(_metadata));
    _selectedIndices.clear();
    if (mounted) {
      setState(() {});
      SnackBarManager.showSnackBar(l10n.removeFromLockedFolder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSelection = _selectedIndices.isNotEmpty;

    if (_authenticating) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.lockedFolder)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_authenticated) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.lockedFolder)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 64, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _authenticate,
                child: Text(l10n.authenticate),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.lockedFolder),
        actions: [
          if (hasSelection)
            IconButton(
              icon: const Icon(Icons.lock_open),
              onPressed: _removeFromLockedFolder,
              tooltip: l10n.removeFromLockedFolder,
            ),
        ],
      ),
      body: _metadata.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      l10n.lockedFolderDescription,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: _metadata.length,
              itemBuilder: (context, index) {
                final item = _metadata[index];
                final file = File('$_lockedDirPath/${item['filename']}');
                final isSelected = _selectedIndices.contains(index);
                return GestureDetector(
                  onTap: () {
                    if (hasSelection) {
                      _toggleSelection(index);
                    }
                  },
                  onLongPress: () => _toggleSelection(index),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        file,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.broken_image, color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          color: colorScheme.primary.withAlpha(77),
                          child: const Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.check_circle, color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
