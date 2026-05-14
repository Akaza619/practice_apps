import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';
import 'services/hive_database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await HiveDatabaseService().init();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing Firebase: $e');
    }
    // If Firebase is not configured, the app will still run but Firebase features will fail.
    // The user needs to run flutterfire configure.
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receipt Scanner AI',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        colorScheme: const ColorScheme.dark(
          primary: AppConstants.primaryColor,
          surface: AppConstants.surfaceColor,
          error: AppConstants.errorColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
