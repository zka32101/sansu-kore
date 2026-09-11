import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_core/models/push_notification_model.dart';

/// Firestore ベースのプッシュ通知管理サービス
/// Phase 4.22: プッシュ通知・ユーザーリテンション実装
class FirestorePushNotificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 現在のユーザー ID を取得
  String? _getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// FCM トークンを更新
  Future<void> updateFCMToken(String fcmToken) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('users').doc(userId).update({
        'fcm_token': fcmToken,
        'fcm_token_updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 通知ログを記録
  Future<void> logNotification(
    String notificationId,
    String type,
    String title,
    String body, {
    String? deepLink,
    Map<String, dynamic>? customData,
  }) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notification_logs')
          .doc(notificationId)
          .set({
        'notification_id': notificationId,
        'type': type,
        'title': title,
        'body': body,
        'deep_link': deepLink,
        'custom_data': customData,
        'created_at': FieldValue.serverTimestamp(),
        'sent_at': FieldValue.serverTimestamp(),
        'delivered_at': null,
        'read_at': null,
        'engagement_time_seconds': null,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 通知を既読にマーク
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notification_logs')
          .doc(notificationId)
          .update({
        'read_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// ユーザーの通知設定を取得
  Future<PushNotificationConfig?> fetchNotificationConfig() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notification_config')
          .get();

      if (!doc.exists) {
        return null;
      }

      return PushNotificationConfig.fromJson(doc.data() ?? {});
    } catch (e) {
      rethrow;
    }
  }

  /// ユーザーの通知設定を更新
  Future<void> updateNotificationConfig(
      PushNotificationConfig config) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notification_config')
          .set(config.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// 通知統計を取得
  Future<NotificationStats?> fetchNotificationStats() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('analytics')
          .doc('notification_stats')
          .get();

      if (!doc.exists) {
        return null;
      }

      return NotificationStats.fromJson(doc.data() ?? {});
    } catch (e) {
      rethrow;
    }
  }

  /// 現在のユーザー ID を返す
  String? getCurrentUserId() => _getCurrentUserId();
}
