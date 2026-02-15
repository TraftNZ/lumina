import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:img_syncer/event_bus.dart';
import 'package:img_syncer/global.dart';
import 'package:img_syncer/proto/img_syncer.pb.dart';
import 'package:img_syncer/storage/storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockedFolderBody extends StatefulWidget {
  const LockedFolderBody({Key? key}) : super(key: key);

  @override
  State<LockedFolderBody> createState() => _LockedFolderBodyState();
}

class _LockedFolderBodyState extends State<LockedFolderBody> {
  bool _authenticated = false;
  bool _authenticating = true;
  List<TrashItem> _items = [];
  bool _loading = true;
  final Set<int> _selectedIndices = {};
  final Map<String, Uint8List?> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<bool> _tryBiometricAuth() async {
    final localAuth = LocalAuthentication();
    try {
      final canAuth = await localAuth.canCheckBiometrics || await localAuth.isDeviceSupported();
      if (!canAuth) return false;
      return await localAuth.authenticate(
        localizedReason: l10n.authenticate,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> _showPinDialog(String correctPin) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.enterPin),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: l10n.enterPin,
            counterText: '',
          ),
          onSubmitted: (value) {
            if (value == correctPin) {
              Navigator.pop(ctx, true);
            } else {
              SnackBarManager.showSnackBar(l10n.incorrectPin);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              if (controller.text == correctPin) {
                Navigator.pop(ctx, true);
              } else {
                SnackBarManager.showSnackBar(l10n.incorrectPin);
              }
            },
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _authenticate() async {
    if (!mounted) return;
    setState(() => _authenticating = true);

    // Try biometric/device auth first
    if (await _tryBiometricAuth()) {
      _authenticated = true;
      await _loadLocked();
      if (mounted) setState(() => _authenticating = false);
      return;
    }

    if (!mounted) return;

    // Fallback to app PIN
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString('locked_folder_pin');

    if (storedPin != null && storedPin.isNotEmpty) {
      if (!mounted) return;
      setState(() => _authenticating = false);
      final pinOk = await _showPinDialog(storedPin);
      if (!mounted) return;
      if (pinOk) {
        _authenticated = true;
        await _loadLocked();
        if (mounted) setState(() {});
      } else {
        if (mounted) Navigator.of(context).pop();
      }
      return;
    }

    // No biometric and no PIN
    if (!mounted) return;
    setState(() => _authenticating = false);
    SnackBarManager.showSnackBar(l10n.pinRequired);
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  Future<void> _loadLocked() async {
    setState(() => _loading = true);
    try {
      final rsp = await storage.cli.listLocked(
        ListLockedRequest(offset: 0, maxReturn: 500),
      );
      if (rsp.success) {
        _items = rsp.items;
        for (final item in _items) {
          _loadThumbnail(item.originalPath);
        }
      }
    } catch (e) {
      if (mounted) SnackBarManager.showSnackBar(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadThumbnail(String originalPath) async {
    if (_thumbnailCache.containsKey(originalPath)) return;
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('$httpBaseUrl/locked/thumbnail/$originalPath'),
      );
      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>(
          <int>[],
          (previous, element) => previous..addAll(element),
        );
        _thumbnailCache[originalPath] = Uint8List.fromList(bytes);
      } else {
        _thumbnailCache[originalPath] = null;
      }
    } catch (_) {
      _thumbnailCache[originalPath] = null;
    }
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

  void _clearSelection() {
    setState(() => _selectedIndices.clear());
  }

  Future<void> _restoreSelected() async {
    final paths = _selectedIndices.map((i) => _items[i].originalPath).toList();
    try {
      await storage.cli.restoreFromLocked(
        RestoreFromLockedRequest(lockedPaths: paths),
      );
      if (mounted) {
        SnackBarManager.showSnackBar('${l10n.restore} ${paths.length} ${l10n.photos}');
      }
    } catch (e) {
      if (mounted) SnackBarManager.showSnackBar(e.toString());
    }
    _clearSelection();
    _loadLocked();
    eventBus.fire(RemoteRefreshEvent());
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
              onPressed: _restoreSelected,
              tooltip: l10n.removeFromLockedFolder,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
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
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final isSelected = _selectedIndices.contains(index);
                    final thumb = _thumbnailCache[item.originalPath];
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
                          if (thumb != null)
                            Image.memory(thumb, fit: BoxFit.cover)
                          else
                            Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(Icons.image, color: colorScheme.onSurfaceVariant),
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
