import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Desktop (Linux / Windows / macOS) has no native `sqflite` backend, so we
/// route database calls through the FFI implementation. Without this the very
/// first DB read hangs, leaving the app stuck on the splash screen.
void initDesktopDatabaseFactory() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
