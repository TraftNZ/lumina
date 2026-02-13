import 'package:flutter/material.dart';
import 'package:img_syncer/global.dart';
import 'package:provider/provider.dart';
import 'package:img_syncer/state_model.dart';
import 'gallery_body.dart';
import 'setting_body.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:img_syncer/logger.dart';
import 'package:flutter/services.dart';
import 'package:img_syncer/l10n/app_localizations.dart';
import 'package:img_syncer/theme.dart';

const seedThemeColor = Color(0xFFFFAB40);

void main() {
  Global.init().then((e) => runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => settingModel),
            ChangeNotifierProvider(create: (context) => assetModel),
            ChangeNotifierProvider(create: (context) => stateModel),
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

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    SnackBarManager.init(context);
    initI18n(context);
    initRequestPermission(context);
    return Consumer<StateModel>(
      builder: (context, model, child) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              const GalleryBody(),
              if (!model.isSelectionMode)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  child: _FloatingBottomBar(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingBottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      elevation: 3,
      shape: const StadiumBorder(),
      color: colorScheme.surfaceContainerHigh,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library, size: 20, color: colorScheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      l10n.library,
                      style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.settings_outlined, color: colorScheme.onSurfaceVariant),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingBody()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
