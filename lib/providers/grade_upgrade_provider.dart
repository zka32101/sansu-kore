import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 学年アップグレード処理を管理するプロバイダ
final gradeUpgradeProvider = Provider<GradeUpgradeService>((ref) {
  return GradeUpgradeService(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

/// 学年アップグレードサービス
/// 4月になると自動的に学年を1上げる
class GradeUpgradeService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GradeUpgradeService(this._firestore, this._auth);

  /// ユーザーの学年をアップグレード（4月チェック）
  /// 4月1日になったら自動的に学年を1段階上げる
  Future<bool> checkAndUpgradeGradeIfNeeded() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final now = DateTime.now();

      // 4月でない場合はスキップ
      if (now.month != 4) return false;

      // ユーザードキュメントから最後のアップグレード日を取得
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) return false;

      final data = userDoc.data() ?? {};
      final lastUpgradedYear =
          (data['lastGradeUpgradedYear'] as int?) ?? 0;

      // 既に今年アップグレード済みの場合はスキップ
      if (lastUpgradedYear == now.year) return false;

      // 現在の学年を取得
      final currentGrade = (data['profile']?['grade'] as int?) ?? 1;

      // 学年を1上げる（最大6年生）
      final newGrade = (currentGrade + 1).clamp(1, 6);

      // Firestore を更新
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'profile.grade': newGrade,
        'lastGradeUpgradedYear': now.year,
        'lastGradeUpgradedAt': FieldValue.serverTimestamp(),
      });

      // ランキングも同時に更新
      await _updateRankingGrade(currentUser.uid, newGrade);

      return true;
    } catch (e) {
      print('Error upgrading grade: $e');
      return false;
    }
  }

  /// ランキング内の学年情報を更新
  Future<void> _updateRankingGrade(String userId, int newGrade) async {
    try {
      final batch = _firestore.batch();

      // グローバル、週間、月間のランキングを全て更新
      for (final category in ['global', 'weekly', 'monthly']) {
        final userRankingRef = _firestore
            .collection('rankings')
            .doc(category)
            .collection('users')
            .doc(userId);

        batch.update(userRankingRef, {'gradeLevel': newGrade});
      }

      await batch.commit();
    } catch (e) {
      print('Error updating ranking grade: $e');
    }
  }

  /// ユーザーの現在の学年を取得
  Future<int> getCurrentGrade() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return 1;

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) return 1;

      return (userDoc.data()?['profile']?['grade'] as int?) ?? 1;
    } catch (e) {
      print('Error getting current grade: $e');
      return 1;
    }
  }

  /// ユーザーの登録日を取得
  Future<DateTime> getUserStartDate() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return DateTime.now();

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) return DateTime.now();

      final createdAt = userDoc.data()?['createdAt'] as Timestamp?;
      return createdAt?.toDate() ?? DateTime.now();
    } catch (e) {
      print('Error getting user start date: $e');
      return DateTime.now();
    }
  }

  /// 学年別のユーザー数統計を取得
  Future<Map<int, int>> getGradeDistribution() async {
    try {
      final snapshot = await _firestore
          .collection('rankings')
          .doc('global')
          .collection('users')
          .get();

      final distribution = <int, int>{};

      for (final doc in snapshot.docs) {
        final gradeLevel =
            (doc.data()['gradeLevel'] as int?) ?? 1;
        distribution[gradeLevel] = (distribution[gradeLevel] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      print('Error getting grade distribution: $e');
      return {};
    }
  }

  /// 開始月別のユーザー数統計を取得
  Future<Map<String, int>> getStartMonthDistribution() async {
    try {
      final snapshot = await _firestore
          .collection('rankings')
          .doc('global')
          .collection('users')
          .get();

      final distribution = <String, int>{};

      for (final doc in snapshot.docs) {
        final startDate = doc.data()['startDate'] as Timestamp?;
        if (startDate != null) {
          final date = startDate.toDate();
          final key =
              '${date.year}年${date.month}月';
          distribution[key] =
              (distribution[key] ?? 0) + 1;
        }
      }

      return distribution;
    } catch (e) {
      print('Error getting start month distribution: $e');
      return {};
    }
  }
}
