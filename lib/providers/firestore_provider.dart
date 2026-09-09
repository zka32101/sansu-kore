import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sansu_kore/utils/security_utils.dart';
import 'package:shared_core/shared_core.dart' show FeedbackReport;

final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);
final authProvider = Provider((ref) => FirebaseAuth.instance);

final currentUserIdProvider = StreamProvider<String?>((ref) {
  final auth = ref.watch(authProvider);
  return auth.authStateChanges().map((user) => user?.uid);
});

/// Firestore user doc (profile + metadata)
final userDocProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, userId) async* {
  final firestore = ref.watch(firestoreProvider);
  yield* firestore.collection('users').doc(userId).snapshots().map(
    (snap) => snap.exists ? snap.data() : null,
  );
});

/// ユーザープロフィール同期
class UserProfileSync {
  static Future<void> initializeUser(String userId, {
    required String name,
    required int grade,
    required String favoriteItem,
  }) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('users').doc(userId).set({
      'profile': {
        'name': name,
        'grade': grade,
        'favoriteItem': favoriteItem,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  /// Update user profile with validated data only
  /// Prevents unauthorized field modifications via input validation
  static Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    final firestore = FirebaseFirestore.instance;
    try {
      // Validate and sanitize input data
      final validatedData = SecurityUtils.validateProfileUpdate(updates);

      final updateData = {...validatedData, 'updatedAt': FieldValue.serverTimestamp()};
      await firestore.collection('users').doc(userId).update({
        'profile': updateData,
      });
    } catch (e) {
      if (kDebugMode) print('Firestore updateProfile error: $e');
      rethrow;
    }
  }
}

/// ステージ進捗同期
class ProgressSync {
  static Future<void> saveProgress(String userId, int stageId, {
    required bool unlocked,
    required bool completed,
    required int completedCount,
  }) async {
    // Validate input
    if (stageId < 0 || stageId > 1000) {
      throw ArgumentError('Invalid stageId');
    }
    if (completedCount < 0 || completedCount > 100) {
      throw ArgumentError('Invalid completedCount');
    }

    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc('$stageId')
        .set({
      'stageId': stageId,
      'unlocked': unlocked,
      'completed': completed,
      'completedCount': completedCount,
      'lastPlayedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<Map<int, Map<String, dynamic>>> loadAllProgress(String userId) async {
    final firestore = FirebaseFirestore.instance;
    try {
      final snap = await firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .get()
          .timeout(const Duration(seconds: 10), onTimeout: () => throw Exception('Firestore timeout'));

      return {
        for (final doc in snap.docs)
          int.parse(doc.id): doc.data(),
      };
    } catch (e) {
      if (kDebugMode) print('Firestore loadAllProgress error: $e');
      return {};
    }
  }
}

/// ゴーストレコード同期
class GhostRecordSync {
  static Future<void> saveGhostRecord(String userId, {
    required int stageId,
    required List<int> questionMs,
  }) async {
    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection('users')
        .doc(userId)
        .collection('ghostRecords')
        .add({
      'stageId': stageId,
      'questionMs': questionMs,
      'totalMs': questionMs.fold(0, (s, v) => s + v),
      'playedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> getGhostRecordsByStage(
    String userId,
    int stageId,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final snap = await firestore
        .collection('users')
        .doc(userId)
        .collection('ghostRecords')
        .where('stageId', isEqualTo: stageId)
        .orderBy('playedAt', descending: true)
        .limit(10)
        .get();

    return snap.docs.map((doc) => doc.data()).toList();
  }
}

/// 無限練習セッション同期
class InfiniteSessionSync {
  static Future<void> saveSession(String userId, {
    required String topic,
    required int correctCount,
    required int wrongCount,
    required int streak,
  }) async {
    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection('users')
        .doc(userId)
        .collection('infiniteSessions')
        .add({
      'topic': topic,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'streak': streak,
      'playedAt': FieldValue.serverTimestamp(),
    });
  }
}

/// 誤答分析同期
class AnalyticsSync {
  static Future<void> recordWrongAnswer(String userId, {
    required int stageId,
    required int questionIndex,
    required String selectedAnswer,
    required String correctAnswer,
    required String topic,
  }) async {
    // Validate input
    if (stageId < 0 || stageId > 1000) {
      throw ArgumentError('Invalid stageId');
    }
    if (questionIndex < 0 || questionIndex > 100) {
      throw ArgumentError('Invalid questionIndex');
    }
    if (selectedAnswer.isEmpty || selectedAnswer.length > 500) {
      throw ArgumentError('Invalid selectedAnswer');
    }
    if (correctAnswer.isEmpty || correctAnswer.length > 500) {
      throw ArgumentError('Invalid correctAnswer');
    }
    if (topic.isEmpty || topic.length > 100) {
      throw ArgumentError('Invalid topic');
    }

    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection('users')
        .doc(userId)
        .collection('wrongAnswers')
        .add({
      'stageId': stageId,
      'questionIndex': questionIndex,
      'selectedAnswer': selectedAnswer,
      'correctAnswer': correctAnswer,
      'topic': topic,
      'recordedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>> getTopicStats(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final snap = await firestore
        .collection('users')
        .doc(userId)
        .collection('wrongAnswers')
        .get();

    final stats = <String, Map<String, int>>{};
    for (final doc in snap.docs) {
      final topic = doc['topic'] as String;
      stats.putIfAbsent(topic, () => {'correct': 0, 'wrong': 0});
    }

    return stats;
  }
}

/// バグ報告・改善要望（shared_core の FeedbackNotifier から注入される送信処理）
class FeedbackSync {
  /// [FeedbackReport] を Firestore の `feedback` コレクションへ書き込む。
  ///
  /// main.dart で `feedbackProvider.notifier.setSubmitHandler(FeedbackSync.submit)`
  /// として登録する想定。
  static Future<void> submit(FeedbackReport report) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('feedback').doc(report.id).set({
      'type': report.type.name,
      'title': report.title,
      'description': report.description,
      'appName': report.appName,
      'appVersion': report.appVersion,
      'platform': report.platform,
      'createdAt': report.createdAt.toIso8601String(),
      'serverCreatedAt': FieldValue.serverTimestamp(),
      'userId': report.userId,
      'status': report.status,
    });
  }
}
