import 'package:flutter/material.dart';
import 'package:img_syncer/global.dart';
import 'package:provider/provider.dart';
import 'package:img_syncer/state_model.dart';
import 'gallery_body.dart';
import 'collections_body.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:img_syncer/logger.dart';
import 'package:flutter/services.dart';
import 'package:img_syncer/l10n/app_localizations.dart';
import 'package:img_syncer/theme.dart';

const seedThemeColor = Color(0xFF5B9BD5);

void main() {
  Global.init().then((e) => runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settingModel),
            ChangeNotifierProvider.value(value: assetModel),
            ChangeNotifierProvider.value(value: stateModel),
          ],
          child: const MyApp(),
        ),
      ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  static const String _title = 'Lumina';

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        late ColorScheme lightColorScheme;
        late ColorScheme darkColorScheme;
        if (lightDynamic != null) {
          lightColorScheme = lightDynamic.harmonized();
        } else {
          logger.i("lightDynamic is null");
          lightColorScheme = ColorScheme.fromSeed(
            seedColor: seedThemeColor,
            brightness: Brightness.light,
          );
        }
        if (darkDynamic != null) {
          darkColorScheme = darkDynamic.harmonized();
        } else {
          logger.i("darkDynamic is null");
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: seedThemeColor,
            brightness: Brightness.dark,
          );
        }

        final lightTheme = buildLightTheme(lightColorScheme);
        final darkTheme = buildDarkTheme(darkColorScheme);

        return AdaptiveTheme(
            light: lightTheme,
            dark: darkTheme,
            initial: AdaptiveThemeMode.system,
            builder: (theme, darkTheme) {
              return MaterialApp(
                title: _title,
                debugShowCheckedModeBanner: false,
                home: const MyHomePage(title: _title),
                theme: theme,
                darkTheme: darkTheme,
                themeMode: ThemeMode.system,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              );
            });
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedTab = 0;
  GalleryViewMode _viewMode = GalleryViewMode.all;

  @override
  Widget build(BuildContext context) {
    SnackBarManager.init(context);
    initI18n(context);
    initRequestPermission(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(
              index: _selectedTab,
              children: [
                GalleryBody(viewMode: _viewMode),
                const CollectionsBody(),
              ],
            ),
            Consumer<StateModel>(
              builder: (context, model, child) {
                if (model.isSelectionMode) return const SizedBox.shrink();
                return Positioned(
                  left: 16,
                  bottom: 12,
                  child: _FloatingBottomBar(
                    selectedTab: _selectedTab,
                    onTabChanged: (index) {
                      setState(() {
                        _selectedTab = index;
                      });
                    },
                    viewMode: _selectedTab == 0 ? _viewMode : null,
                    onViewModeChanged: (mode) {
                      setState(() {
                        _viewMode = mode;
                      });
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingBottomBar extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final GalleryViewMode? viewMode;
  final ValueChanged<GalleryViewMode>? onViewModeChanged;

  const _FloatingBottomBar({
    required this.selectedTab,
    required this.onTabChanged,
    this.viewMode,
    this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return GlassContainer(
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabChip(
            context: context,
            icon: Icons.photo_library,
            label: l10n.photos,
            isSelected: selectedTab == 0,
            onTap: () => onTabChanged(0),
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(width: 4),
          _buildTabChip(
            context: context,
            icon: Icons.collections_bookmark,
            label: l10n.collections,
            isSelected: selectedTab == 1,
            onTap: () => onTabChanged(1),
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          if (viewMode != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                height: 20,
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: colorScheme.outlineVariant,
                ),
              ),
            ),
            ...GalleryViewMode.values.map((mode) {
              final selected = viewMode == mode;
              final label = switch (mode) {
                GalleryViewMode.years => l10n.years,
                GalleryViewMode.months => l10n.months,
                GalleryViewMode.all => l10n.all,
              };
              return GestureDetector(
                onTap: () => onViewModeChanged?.call(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Text(
                    label,
                    style: selected
                        ? textTheme.labelLarge
                            ?.copyWith(color: colorScheme.onPrimaryContainer)
                        : textTheme.labelLarge
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    if (isSelected) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimaryContainer),
              ),
            ],
          ),
        ),
      );
    }
    return IconButton(
      icon: Icon(icon, color: colorScheme.onSurfaceVariant),
      onPressed: onTap,
    );
  }
}
