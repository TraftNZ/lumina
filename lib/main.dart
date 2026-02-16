import 'package:flutter/material.dart';
import 'package:lumina/global.dart';
import 'package:provider/provider.dart';
import 'package:lumina/state_model.dart';
import 'gallery_body.dart';
import 'collections_body.dart';
import 'search_body.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:lumina/logger.dart';
import 'package:flutter/services.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/theme.dart';

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
  GalleryViewMode? _viewMode;

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
                GalleryBody(viewMode: _viewMode ?? GalleryViewMode.all),
                const CollectionsBody(),
              ],
            ),
            Consumer<StateModel>(
              builder: (context, model, child) {
                if (model.isSelectionMode) return const SizedBox.shrink();
                return Positioned(
                  left: 16,
                  right: _selectedTab == 0 ? 16 : null,
                  bottom: 12,
                  child: _FloatingBottomBar(
                    selectedTab: _selectedTab,
                    onTabChanged: (index) {
                      setState(() {
                        _selectedTab = index;
                        if (index == 1) _viewMode = null;
                      });
                    },
                    showViewModes: _selectedTab == 0,
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
  final bool showViewModes;
  final GalleryViewMode? viewMode;
  final ValueChanged<GalleryViewMode>? onViewModeChanged;

  const _FloatingBottomBar({
    required this.selectedTab,
    required this.onTabChanged,
    this.showViewModes = false,
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
        mainAxisSize: showViewModes ? MainAxisSize.max : MainAxisSize.min,
        children: [
          _buildTabChip(
            context: context,
            icon: Icons.photo_library,
            label: l10n.photos,
            isSelected: selectedTab == 0,
            showLabel: viewMode == null,
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
          if (showViewModes) ...[
            const Spacer(),
            ...GalleryViewMode.values.map((mode) {
              final selected = viewMode == mode;
              final fullLabel = switch (mode) {
                GalleryViewMode.years => l10n.years,
                GalleryViewMode.months => l10n.months,
                GalleryViewMode.all => l10n.all,
              };
              final shortLabel = switch (mode) {
                GalleryViewMode.years => 'Y',
                GalleryViewMode.months => 'M',
                GalleryViewMode.all => 'A',
              };
              return GestureDetector(
                onTap: () => onViewModeChanged?.call(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Text(
                    selected ? fullLabel : shortLabel,
                    style: selected
                        ? textTheme.labelLarge
                            ?.copyWith(color: colorScheme.onPrimaryContainer)
                        : textTheme.labelLarge
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              );
            }),
            IconButton(
              icon: Icon(Icons.search, size: 20, color: colorScheme.onSurfaceVariant),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchBody()),
                );
              },
            ),
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
    bool showLabel = true,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    if (isSelected) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: showLabel ? 16 : 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: colorScheme.onPrimaryContainer),
              if (showLabel) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimaryContainer),
                ),
              ],
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
