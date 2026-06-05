import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitora_app/controllers/auth_controller.dart';
import 'package:splitora_app/controllers/connectivity_controller.dart';
import 'package:splitora_app/controllers/wrapper.dart';
import 'package:splitora_app/services/notification_service.dart';
import 'package:splitora_app/services/receipt_storage_service.dart';
import 'package:splitora_app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize connectivity monitoring before anything else.
  Get.put(ConnectivityController());

  await ReceiptStorageService.instance.init();
  await Firebase.initializeApp(options: defaultFirebaseOptions);

  // Must be registered before runApp so terminated/background pushes are handled.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.instance.init();

  Get.put(AuthController());
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
