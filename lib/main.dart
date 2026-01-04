import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'native_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for Windows
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Sync SQLite data into C++ memory before app starts
  await NativeService().syncWithDatabase();

  runApp(const ShareBitesApp());
}

class ShareBitesApp extends StatelessWidget {
  const ShareBitesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "ShareBites",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}