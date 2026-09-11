import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_core/models/retention_model.dart';

/// Firestore ベースのユーザーリテンション管理サービス
/// Phase 4.22: プッシュ通知・ユーザーリテンション実装
class FirestoreRetentionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 現在のユーザー ID を取得
  String? _getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// チャーン予測リストを取得（リスク高いユーザー）
  Future<List<ChurnPrediction>> fetchChurnPredictions({int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection('retention')
          .doc('predictions')
          .collection('users')
          .orderBy('churn_risk_score', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ChurnPrediction.fromJson(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 特定ユーザーのリテンション分析を取得
  Future<UserRetentionAnalytics?> fetchUserRetentionAnalytics(
      String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('retention')
          .doc('analytics')
          .get();

      if (!doc.exists) {
        return null;
      }

      return UserRetentionAnalytics.fromJson(doc.data() ?? {});
    } catch (e) {
      rethrow;
    }
  }

  /// リエンゲージメントキャンペーンを保存
  Future<void> saveReengagementCampaign(
      ReengagementCampaign campaign) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('retention')
          .doc('campaigns')
          .collection('active')
          .doc(campaign.campaignId)
          .set(campaign.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// コホート分析データを取得
  Future<CohortAnalytics?> fetchCohortAnalytics(String cohortId) async {
    try {
      final doc = await _firestore
          .collection('retention')
          .doc('cohorts')
          .collection('data')
          .doc(cohortId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return CohortAnalytics.fromJson(doc.data() ?? {});
    } catch (e) {
      rethrow;
    }
  }

  /// 人口統計を取得
  Future<PopulationStats?> fetchPopulationStats() async {
    try {
      final doc = await _firestore
          .collection('retention')
          .doc('stats')
          .collection('global')
          .doc('latest')
          .get();

      if (!doc.exists) {
        return null;
      }

      return PopulationStats.fromJson(doc.data() ?? {});
    } catch (e) {
      rethrow;
    }
  }

  /// リテンション設定を取得
  Future<RetentionConfig?> fetchRetentionConfig() async {
    try {
      final doc = await _firestore
          .collection('retention')
          .doc('config')
          .collection('settings')
          .doc('active')
          .get();

      if (!doc.exists) {
        return null;
      }

      return RetentionConfig.fromJson(doc.data() ?? {});
    } catch (e) {
      rethrow;
    }
  }

  /// 休止ユーザーリストを取得
  Future<List<UserRetentionAnalytics>> fetchDormantUsers(
      {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('activity_level', isEqualTo: 'dormant')
          .limit(limit)
          .get();

      final results = <UserRetentionAnalytics>[];

      for (var doc in snapshot.docs) {
        final retentionDoc = await _firestore
            .collection('users')
            .doc(doc.id)
            .collection('retention')
            .doc('analytics')
            .get();

        if (retentionDoc.exists) {
          results.add(UserRetentionAnalytics.fromJson(retentionDoc.data() ?? {}));
        }
      }

      return results;
    } catch (e) {
      rethrow;
    }
  }

  /// 現在のユーザー ID を返す
  String? getCurrentUserId() => _getCurrentUserId();
}
