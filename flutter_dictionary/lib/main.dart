import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/dictionary_provider.dart';
import 'screens/home_screen.dart';

void main() {
  // Initialize SQLite for desktop platforms
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  runApp(const ChineseRussianDictionaryApp());
}

class ChineseRussianDictionaryApp extends StatelessWidget {
  const ChineseRussianDictionaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DictionaryProvider(),
      child: MaterialApp(
        title: '汉俄词典',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF00CCFF),
            secondary: const Color(0xFF8B5CF6),
            surface: const Color(0xFF0D0D1A),
            background: const Color(0xFF0D0D1A),
          ),
          scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
