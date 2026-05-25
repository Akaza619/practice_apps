// import 'package:ai_logic_firebase/screens/receipt_screen.dart';
// import 'package:ai_logic_firebase/service/hive_service.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:hive_flutter/hive_flutter.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // ── Lock orientation to portrait (optional — remove if not needed) ────────
//   await SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);

//   // ── Status bar styling ────────────────────────────────────────────────────
//   SystemChrome.setSystemUIOverlayStyle(
//     const SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent,
//       statusBarIconBrightness: Brightness.light,
//     ),
//   );

//   // ── Firebase (must init before any FirebaseAI call) ───────────────────────
//   await Firebase.initializeApp();

//   // ── Hive (must init before any HiveService call) ──────────────────────────
//   await Hive.initFlutter();
//   await HiveService.init(); // registers TypeAdapters (typeId 10 & 11) + opens box

//   runApp(const MyApp());
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Root App
// // ─────────────────────────────────────────────────────────────────────────────

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       title: 'Receipt Scanner',
//       debugShowCheckedModeBanner: false,

//       // ── Theme ─────────────────────────────────────────────────────────────
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF6C63FF),
//           brightness: Brightness.dark,
//         ),
//         scaffoldBackgroundColor: const Color(0xFF0A0A0F),
//         useMaterial3: true,
//       ),
//       darkTheme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF6C63FF),
//           brightness: Brightness.dark,
//         ),
//         scaffoldBackgroundColor: const Color(0xFF0A0A0F),
//         useMaterial3: true,
//       ),
//       themeMode: ThemeMode.dark,

//       // ── Initial route ──────────────────────────────────────────────────────
//       // Change this to your actual home screen if integrating into an
//       // existing app. To open the scanner from any screen use:
//       //   Get.to(() => const ReceiptScreen());
//       home: const ReceiptScreen(),

//       // ── GetX transitions ───────────────────────────────────────────────────
//       defaultTransition: Transition.fadeIn,
//       transitionDuration: const Duration(milliseconds: 300),
//     );
//   }
// }

import 'package:ai_logic_firebase/screens/receipt_screen.dart';
import 'package:ai_logic_firebase/service/hive_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Orientation ───────────────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Status bar ────────────────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // ── Firebase ──────────────────────────────────────────────────────────────
  await Firebase.initializeApp();
  debugPrint('✅ Firebase initialized');

  // ── Hive ──────────────────────────────────────────────────────────────────
  await Hive.initFlutter();
  await HiveService.init();
  debugPrint('✅ Hive initialized');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Receipt Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: const ReceiptScreen(),
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
