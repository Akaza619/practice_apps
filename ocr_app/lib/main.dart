// import 'package:flutter/material.dart';
// import 'services/storage_service.dart';
// import 'screens/main_scaffold.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final storage = StorageService();
//   await storage.init();

//   runApp(ReceiptReaderApp(storage: storage));
// }

// class ReceiptReaderApp extends StatelessWidget {
//   final StorageService storage;
//   const ReceiptReaderApp({super.key, required this.storage});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Receipt reader',
//       debugShowCheckedModeBanner: false,
//       theme: _buildTheme(Brightness.light),
//       darkTheme: _buildTheme(Brightness.dark),
//       themeMode: ThemeMode.system,
//       home: MainScaffold(storage: storage),
//     );
//   }

//   ThemeData _buildTheme(Brightness brightness) {
//     final seed = const Color(0xFF1A73E8);
//     return ThemeData(
//       useMaterial3: true,
//       colorSchemeSeed: seed,
//       brightness: brightness,
//       cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)), side: BorderSide(color: Color(0x1A000000), width: 0.5))),
//       appBarTheme: AppBarTheme(
//         backgroundColor: seed,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'screens/main_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await storage.init();

  runApp(ReceiptReaderApp(storage: storage));
}

class ReceiptReaderApp extends StatelessWidget {
  final StorageService storage;
  const ReceiptReaderApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receipt Reader',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: MainScaffold(storage: storage),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    const seed = Color(0xFF1A73E8);
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seed,
      brightness: brightness,
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: Color(0x1A000000), width: 0.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: seed,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }
}
