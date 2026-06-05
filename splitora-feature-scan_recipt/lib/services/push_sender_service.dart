import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Sends FCM push notifications directly from the client using the FCM
/// HTTP v1 API.
///
/// ⚠️ SECURITY NOTE: this authorizes with a Firebase **service account**, whose
/// private key is bundled in the app (`assets/service_account.json`). Anyone
/// who unpacks the APK can extract that key and send pushes as this project.
/// This is the unavoidable trade-off of sending pushes without a backend.
class PushSenderService {
  PushSenderService._();
  static final PushSenderService instance = PushSenderService._();

  static const _serviceAccountAsset = 'assets/service_account.json';
  static const _scope = 'https://www.googleapis.com/auth/firebase.messaging';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AutoRefreshingAuthClient? _client;
  String? _projectId;

  /// Lazily builds (and caches) an auto-refreshing authenticated HTTP client
  /// from the bundled service account. Returns null if the key is missing.
  static const _tag = '📤 PushSender';

  Future<AutoRefreshingAuthClient?> _authClient() async {
    if (_client != null) return _client;
    try {
      final raw = await rootBundle.loadString(_serviceAccountAsset);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _projectId = json['project_id'] as String?;
      final credentials = ServiceAccountCredentials.fromJson(json);
      _client = await clientViaServiceAccount(credentials, [_scope]);
      debugPrint('$_tag ✅ Auth client ready (project: $_projectId)');
      return _client;
    } catch (e) {
      debugPrint(
        '$_tag ❌ Could not load service account ($_serviceAccountAsset). '
        'Push notifications disabled. Error: $e',
      );
      return null;
    }
  }

  /// Pushes a notification to every participant of [chatId] except [senderId].
  ///
  /// Fire-and-forget: never throws, so a failure here can't break message
  /// sending. Call it after the message has been written to Firestore.
  Future<void> sendChatNotification({
    required String chatId,
    required String senderId,
    required String senderName,
    required String body,
  }) async {
    try {
      debugPrint('$_tag ── Sending push for chat=$chatId from "$senderName"');
      final client = await _authClient();
      if (client == null || _projectId == null) {
        debugPrint('$_tag ⏭️  Skipped: no auth client / project id');
        return;
      }

      // Resolve participants + chat type from the parent chat doc.
      final chatSnap = await _firestore.collection('chats').doc(chatId).get();
      if (!chatSnap.exists) {
        debugPrint('$_tag ⚠️  Chat doc $chatId not found');
        return;
      }
      final chat = chatSnap.data()!;

      final isGroup = chat['isGroup'] == true;
      final participants = List<String>.from(chat['participants'] ?? const []);
      final recipients = participants.where((uid) => uid != senderId).toList();
      debugPrint(
        '$_tag Recipients (excl. sender): ${recipients.length} $recipients',
      );
      if (recipients.isEmpty) {
        debugPrint('$_tag ⏭️  No recipients to notify');
        return;
      }

      final title = isGroup
          ? '${chat['groupName'] ?? 'Group'} • $senderName'
          : senderName;
      final chatName = isGroup ? (chat['groupName'] ?? 'Group') : senderName;

      // Collect every recipient device token (token -> owning uid, for pruning).
      final Map<String, String> tokenOwner = {};
      final userSnaps = await Future.wait(
        recipients.map((uid) => _firestore.collection('users').doc(uid).get()),
      );
      for (final snap in userSnaps) {
        if (!snap.exists) continue;
        final tokens = List<String>.from(snap.data()?['fcmTokens'] ?? const []);
        debugPrint('$_tag User ${snap.id}: ${tokens.length} token(s)');
        for (final t in tokens) {
          tokenOwner[t] = snap.id;
        }
      }
      if (tokenOwner.isEmpty) {
        debugPrint(
          '$_tag ⏭️  No FCM tokens found for recipients. '
          '(Have they logged in on a device that registered a token?)',
        );
        return;
      }

      debugPrint('$_tag Sending to ${tokenOwner.length} token(s)...');
      final endpoint = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
      );

      // FCM v1 sends to one token per request.
      final results = await Future.wait(
        tokenOwner.entries.map(
          (entry) => _sendToToken(
            client: client,
            endpoint: endpoint,
            token: entry.key,
            ownerUid: entry.value,
            title: title,
            body: body,
            chatId: chatId,
            isGroup: isGroup,
            chatName: chatName,
          ),
        ),
      );
      final ok = results.where((r) => r).length;
      debugPrint('$_tag ✅ Done: $ok/${results.length} push(es) sent OK');
    } catch (e) {
      debugPrint('$_tag ❌ sendChatNotification failed: $e');
    }
  }

  /// Returns true if the push was accepted by FCM (HTTP 200).
  Future<bool> _sendToToken({
    required http.Client client,
    required Uri endpoint,
    required String token,
    required String ownerUid,
    required String title,
    required String body,
    required String chatId,
    required bool isGroup,
    required String chatName,
  }) async {
    final payload = {
      'message': {
        'token': token,
        'notification': {'title': title, 'body': body},
        'data': {
          'type': 'chat_message',
          'chatId': chatId,
          'isGroup': isGroup.toString(),
          'chatName': chatName,
        },
        'android': {
          'priority': 'high',
          'notification': {'channel_id': 'high_importance_channel'},
        },
        'apns': {
          'payload': {
            'aps': {'sound': 'default'},
          },
        },
      },
    };

    final shortToken = token.length > 12 ? '${token.substring(0, 12)}…' : token;
    try {
      final res = await client.post(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        debugPrint('$_tag   ✅ sent → $shortToken');
        return true;
      }

      // 404 UNREGISTERED / 400 INVALID_ARGUMENT => stale token, prune it.
      if (res.statusCode == 404 ||
          (res.statusCode == 400 && res.body.contains('UNREGISTERED')) ||
          res.body.contains('registration-token-not-registered')) {
        debugPrint('$_tag   🧹 stale token pruned → $shortToken');
        await _firestore.collection('users').doc(ownerUid).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      } else {
        debugPrint(
          '$_tag   ❌ failed (${res.statusCode}) → $shortToken : ${res.body}',
        );
      }
      return false;
    } catch (e) {
      debugPrint('$_tag   ❌ error → $shortToken : $e');
      return false;
    }
  }
}
