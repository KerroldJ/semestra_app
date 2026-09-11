import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'app/navigation/app_router.dart';
import 'core/database/db_factory_stub.dart'
    if (dart.library.io) 'core/database/db_factory_io.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_toast.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Plain `sqflite` has no web backend. On web we must route all database
  // calls through the FFI/WASM-based factory, otherwise every read/write
  // throws (semesters, subjects, items, settings all silently fail to save).
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    // Desktop has no native sqflite backend — use the FFI implementation.
    // (Mobile keeps the default native plugin.)
    initDesktopDatabaseFactory();
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final router = ref.watch(appRouterProvider);

    // The selection is explicit (light / midnight / charcoal / slate); the
    // chosen ThemeData carries its own brightness, so we hand the same theme to
    // both slots and pin the mode.
    final selectedTheme = AppTheme.themeFor(settings.themeMode);

    return MaterialApp.router(
      title: 'Semestra',
      debugShowCheckedModeBanner: false,
      theme: selectedTheme,
      darkTheme: selectedTheme,
      themeMode: ThemeMode.light,
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: router,
      builder: (context, child) {
        final scaler = TextScaler.linear(settings.textScale);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
