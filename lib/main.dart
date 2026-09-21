import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'src/database.dart';
import 'src/home_page.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Neither of these must be allowed to block runApp() forever: if the
      // locale data or the SQLite file fails to initialize on a given
      // device, the app should still draw its UI (and let HomePage retry)
      // instead of leaving the user staring at a blank/black screen.
      try {
        await initializeDateFormatting('ja_JP');
      } catch (error, stack) {
        developer.log(
          'initializeDateFormatting failed',
          error: error,
          stackTrace: stack,
        );
      }
      try {
        await AppDatabase.instance.database;
      } catch (error, stack) {
        developer.log(
          'AppDatabase warm-up failed',
          error: error,
          stackTrace: stack,
        );
      }

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      );
      runApp(const AppBlockerApp());
    },
    (error, stack) {
      developer.log('Uncaught error', error: error, stackTrace: stack);
    },
  );
}

class AppBlockerApp extends StatelessWidget {
  const AppBlockerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF17211B);
    const green = Color(0xFF3F6B4F);
    const cream = Color(0xFFF6F3EA);
    final scheme = ColorScheme.fromSeed(
      seedColor: green,
      brightness: Brightness.light,
      surface: cream,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Focus Gate',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: cream,
        fontFamily: 'sans-serif',
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: ink,
          displayColor: ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white.withValues(alpha: .72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: .75),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
