import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:img_syncer/global.dart';
import 'package:img_syncer/proto/img_syncer.pb.dart';
import 'package:img_syncer/storage/storage.dart';

class TrashBody extends StatefulWidget {
  const TrashBody({Key? key}) : super(key: key);

  @override
  State<TrashBody> createState() => _TrashBodyState();
}

class _TrashBodyState extends State<TrashBody> {
  List<TrashItem> _items = [];
  bool _loading = true;
  final Set<int> _selectedIndices = {};
  final Map<String, Uint8List?> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    setState(() => _loading = true);
    try {
      final rsp = await storage.cli.listTrash(
        ListTrashRequest(offset: 0, maxReturn: 500),
      );
      if (rsp.success) {
        _items = rsp.items;
        // Start loading thumbnails
        for (final item in _items) {
          _loadThumbnail(item.originalPath);
        }
      }
    } catch (e) {
      if (mounted) SnackBarManager.showSnackBar(e.toString());
    }
    if (mounted) setState(() => _loading = false);
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
      await storage.cli.restoreFromTrash(
        RestoreFromTrashRequest(trashPaths: paths),
      );
      if (mounted) {
        SnackBarManager.showSnackBar('${l10n.restore} ${paths.length} ${l10n.photos}');
      }
    } catch (e) {
      if (mounted) SnackBarManager.showSnackBar(e.toString());
    }
    _clearSelection();
    _loadTrash();
  }

  Future<void> _restoreAll() async {
    final paths = _items.map((i) => i.originalPath).toList();
    try {
      await storage.cli.restoreFromTrash(
        RestoreFromTrashRequest(trashPaths: paths),
      );
      if (mounted) {
        SnackBarManager.showSnackBar('${l10n.restore} ${paths.length} ${l10n.photos}');
      }
    } catch (e) {
      if (mounted) SnackBarManager.showSnackBar(e.toString());
    }
    _loadTrash();
  }

  Future<void> _deleteSelectedPermanently() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.permanentlyDelete),
        content: Text('${l10n.permanentlyDelete} ${_selectedIndices.length} ${l10n.photos}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final paths = _selectedIndices.map((i) => _items[i].trashPath).toList();
              try {
                await storage.cli.delete(DeleteRequest(paths: paths));
              } catch (e) {
                if (mounted) SnackBarManager.showSnackBar(e.toString());
              }
              _clearSelection();
              _loadTrash();
            },
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
  }

  Future<void> _emptyTrash() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.emptyTrash),
        content: Text(l10n.emptyTrashConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await storage.cli.emptyTrash(EmptyTrashRequest());
                if (mounted) SnackBarManager.showSnackBar(l10n.trashEmpty);
              } catch (e) {
                if (mounted) SnackBarManager.showSnackBar(e.toString());
              }
              _loadTrash();
            },
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
  }

  Future<void> _loadThumbnail(String originalPath) async {
    if (_thumbnailCache.containsKey(originalPath)) return;
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('$httpBaseUrl/trash/thumbnail/$originalPath'),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSelection = _selectedIndices.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trash),
        actions: [
          if (hasSelection) ...[
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: _restoreSelected,
              tooltip: l10n.restore,
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _deleteSelectedPermanently,
              tooltip: l10n.permanentlyDelete,
            ),
          ] else if (_items.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: _restoreAll,
              tooltip: l10n.restore,
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _emptyTrash,
              tooltip: l10n.emptyTrash,
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline, size: 64, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(l10n.trashEmpty, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.trashAutoDeleteNote,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
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
                            onTap: () => _toggleSelection(index),
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
                    ),
                  ],
                ),
    );
  }
}
