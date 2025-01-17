import 'dart:io';

import 'package:al_downloader/al_downloader.dart';
import 'package:audio_service/audio_service.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/generated/l10n.dart';
import 'package:gyawun/providers/audio_handler.dart';
import 'package:gyawun/providers/media_manager.dart';
import 'package:gyawun/providers/theme_manager.dart';
import 'package:gyawun/services/server.dart';
import 'package:gyawun/ui/themes/dark.dart';
import 'package:gyawun/ui/themes/light.dart';
import 'package:gyawun/utils/playback_cache.dart';
import 'package:gyawun/utils/router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:metadata_god/metadata_god.dart';

import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MetadataGod.initialize();
  ALDownloader.initialize();
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('downloads');
  await Hive.openBox('favorites');
  await Hive.openBox('songHistory');

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );
  await FlutterDisplayMode.setHighRefreshRate();

  GetIt.I.registerSingleton<AudioHandler>(await initAudioService());
  MediaManager mediaManager = MediaManager();
  ThemeManager themeManager = ThemeManager();
  GetIt.I.registerSingleton(mediaManager);
  GetIt.I.registerSingleton(themeManager);
  GetIt.I.registerSingleton(PlaybackCache());

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => themeManager),
      ChangeNotifierProvider(create: (context) => mediaManager),
    ],
    child: const MainApp(),
  ));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late HttpServer httpServer;
  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    httpServer = await startServer();
  }

  @override
  void dispose() {
    super.dispose();
    httpServer.close();
  }

  @override
  Widget build(BuildContext context) {
    ThemeManager themeManager = context.watch<ThemeManager>();

    return DynamicColorBuilder(builder: (lightScheme, darkScheme) {
      return GestureDetector(
        onTapDown: (details) => FocusManager.instance.primaryFocus?.unfocus(),
        child: MaterialApp.router(
          title: 'Gyawun',
          locale: Locale(themeManager.language['code']),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          theme: themeManager.isMaterialTheme && lightScheme != null
              ? materialLightTheme(lightScheme.primary)
              : themeManager.getLightTheme,
          darkTheme: themeManager.isMaterialTheme && darkScheme != null
              ? materialDarkTheme(darkScheme.primary)
              : themeManager.getDarkTheme,
          themeMode: themeManager.themeMode,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        ),
      );
    });
  }
}
