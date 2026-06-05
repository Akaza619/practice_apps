import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:splitora_app/screens/chat_detail_screen.dart';

/// Firebase options shared by the app and the background isolate.
/// Must match the values used in [main].
const FirebaseOptions defaultFirebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyAOM0Chs4RW-hEcmSf6ieSj6LAOkwxJ9gI",
  appId: "1:282557622679:android:55ed587f9b61d3b3b23cd2",
  messagingSenderId: "282557622679",
  projectId: "splitora-8a9fe",
);

/// Top-level handler invoked by the OS when a push arrives while the app is
/// terminated or in the background. Runs in its own isolate, so Firebase must
/// be initialized here independently.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: defaultFirebaseOptions);
  // The OS automatically displays the `notification` payload while the app is
  // in the background/terminated, so there is nothing else to do here.
}

/// Handles everything FCM-related: permissions, token lifecycle, and showing /
/// routing notifications across foreground, background and terminated states.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notifications',
    description: 'Receipt and bill notifications',
    importance: Importance.high,
  );

  bool _initialized = false;

  /// Call once after Firebase is initialized (e.g. in `main`).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _requestPermission();
    await _setupLocalNotifications();

    // Foreground messages: the OS won't show them automatically, so we draw a
    // local notification ourselves.
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // Tapped while the app was backgrounded (still alive).
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNavigation);

    // Tapped while the app was terminated (cold start from a notification).
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Defer until the first frame so navigation has a context to work with.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleNavigation(initialMessage),
      );
    }

    // Keep the saved token fresh.
    _messaging.onTokenRefresh.listen(_saveToken);
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    // Android 13+ runtime notification permission.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _navigateFromPayload(payload);
      },
    );

    // Register the channel the function targets (Android 8+).
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      // Pack the routing fields so a tap on the local notification still works.
      payload:
          '${message.data['chatId'] ?? ''}|${message.data['isGroup'] ?? 'false'}|${message.data['chatName'] ?? ''}',
    );
  }

  void _navigateFromPayload(String payload) {
    final parts = payload.split('|');
    if (parts.isEmpty || parts[0].isEmpty) return;
    _openChat(
      chatId: parts[0],
      isGroup: parts.length > 1 && parts[1] == 'true',
      chatName: parts.length > 2 ? parts[2] : '',
    );
  }

  void _handleNavigation(RemoteMessage message) {
    final chatId = message.data['chatId'];
    if (chatId == null || (chatId as String).isEmpty) return;
    _openChat(
      chatId: chatId,
      isGroup: message.data['isGroup'] == 'true',
      chatName: message.data['chatName'] ?? '',
    );
  }

  void _openChat({
    required String chatId,
    required bool isGroup,
    required String chatName,
  }) {
    Get.to(
      () => ChatDetailScreen(
        chatId: chatId,
        isGroup: isGroup,
        chatName: chatName,
      ),
    );
  }

  /// Fetches the device token and stores it on the signed-in user's document.
  /// Tokens are kept in an array so a user can be reached on multiple devices.
  Future<void> registerTokenForCurrentUser() async {
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(token);
  }

  Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('🔔 NotificationService: no user yet, token not saved');
      return;
    }
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
    final short = token.length > 12 ? '${token.substring(0, 12)}…' : token;
    debugPrint('🔔 NotificationService: token saved for $uid → $short');
  }

  /// Removes this device's token on sign-out so a logged-out device stops
  /// receiving that user's notifications.
  Future<void> removeTokenForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final token = await _messaging.getToken();
    if (uid == null || token == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayRemove([token]),
    }, SetOptions(merge: true));
  }
}
