import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/settings_controller.dart';
import 'router.dart';
import 'theme.dart';

class CricitApp extends ConsumerWidget {
  const CricitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boot = ref.watch(bootstrapProvider);
    return boot.when(
      loading: () => MaterialApp(
        title: 'CRICIT',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        home: const SplashScreen(),
      ),
      error: (e, _) => MaterialApp(
        title: 'CRICIT',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        home: const SplashScreen(),
      ),
      data: (_) {
        final settings = ref.watch(settingsProvider);
        final hindi = settings.isHindi;
        return MaterialApp.router(
          title: 'CRICIT',
          debugShowCheckedModeBanner: false,
          theme: cricitTheme(brightness: Brightness.light, hindi: hindi),
          darkTheme: cricitTheme(brightness: Brightness.dark, hindi: hindi),
          themeMode: settings.themeMode,
          locale: Locale(settings.language),
          routerConfig: ref.watch(routerProvider),
          supportedLocales: const [Locale('en'), Locale('hi')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final requested =
                MediaQuery.textScalerOf(context).scale(settings.textScale);
            final capped = requested.clamp(0.9, 1.3);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(capped.toDouble()),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}
