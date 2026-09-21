import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'src/database.dart';
import 'src/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP');
  await AppDatabase.instance.database;
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const AppBlockerApp());
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
