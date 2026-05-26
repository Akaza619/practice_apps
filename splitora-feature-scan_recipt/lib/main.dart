import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:splitora_app/controllers/auth_controller.dart';
import 'package:splitora_app/controllers/wrapper.dart';
import 'package:splitora_app/services/receipt_storage_service.dart';
import 'package:splitora_app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await ReceiptStorageService.instance.init();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyAOM0Chs4RW-hEcmSf6ieSj6LAOkwxJ9gI",
      appId: "1:282557622679:android:55ed587f9b61d3b3b23cd2",
      messagingSenderId: "282557622679",
      projectId: "splitora-8a9fe",
    ),
  ).then((value) => Get.put(AuthController()));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: const Wrapper(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
    );
  }
}
