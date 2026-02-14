import 'package:flutter/material.dart';
import 'package:img_syncer/global.dart';
import 'package:img_syncer/trash_body.dart';
import 'package:img_syncer/locked_folder_body.dart';

class CollectionsBody extends StatelessWidget {
  const CollectionsBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Image.asset('assets/icon/lumina_icon_transparent.png', width: 36, height: 36),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              l10n.collections,
              style: textTheme.headlineMedium,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _CollectionCard(
                icon: Icons.delete_outline,
                label: l10n.trash,
                color: colorScheme.errorContainer,
                iconColor: colorScheme.onErrorContainer,
                textColor: colorScheme.onErrorContainer,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TrashBody()),
                  );
                },
              ),
              _CollectionCard(
                icon: Icons.lock_outline,
                label: l10n.lockedFolder,
                color: colorScheme.tertiaryContainer,
                iconColor: colorScheme.onTertiaryContainer,
                textColor: colorScheme.onTertiaryContainer,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LockedFolderBody()),
                  );
                },
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;

  const _CollectionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: iconColor),
              const Spacer(),
              Text(
                label,
                style: textTheme.titleMedium?.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
