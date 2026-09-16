import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/referral_model.dart';
import 'coin_provider.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// 紹介キーを生成するProvider
final generateReferralKeyProvider = FutureProvider<String>((ref) async {
  final auth = ref.read(firebaseAuthProvider);
  final firestore = ref.read(firebaseFirestoreProvider);
  final user = auth.currentUser;

  if (user == null) {
    throw Exception('ユーザーがログインしていません');
  }

  // 紹介キー生成: SANSU + YYYYMMDD + ランダム5文字
  final now = DateTime.now();
  final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  final randomStr = _generateRandomString(5);
  final referralKey = 'SANSU$dateStr$randomStr';

  // Firestore に保存
  await firestore.collection('referral_codes').doc(referralKey).set({
    'creatorId': user.uid,
    'creatorCoins': 0,
    'usedCount': 0,
    'maxUses': 5,
    'createdAt': Timestamp.now(),
  });

  return referralKey;
});

/// 紹介コードを検証・適用するProvider
final validateAndApplyReferralCodeProvider = FutureProvider.family<bool, String>((ref, code) async {
  final auth = ref.read(firebaseAuthProvider);
  final firestore = ref.read(firebaseFirestoreProvider);
  final user = auth.currentUser;

  if (user == null) {
    throw Exception('ユーザーがログインしていません');
  }

  final docSnap = await firestore.collection('referral_codes').doc(code).get();
  if (!docSnap.exists) {
    throw Exception('紹介コードが見つかりません');
  }

  final referralData = docSnap.data() as Map<String, dynamic>;
  final usedCount = referralData['usedCount'] ?? 0;
  final maxUses = referralData['maxUses'] ?? 5;

  if (usedCount >= maxUses) {
    throw Exception('この紹介コードは上限に達しています');
  }

  final creatorId = referralData['creatorId'] as String;

  // トランザクション開始
  await firestore.runTransaction((transaction) async {
    // 1. 紹介した側にコイン加算（+100）
    final creatorRef = firestore.collection('users').doc(creatorId);
    final creatorDoc = await transaction.get(creatorRef);
    final creatorCurrentCoins = (creatorDoc.data()?['coins'] as int?) ?? 0;
    transaction.update(creatorRef, {
      'coins': creatorCurrentCoins + 100,
    });

    // 2. 紹介された側にコイン加算（+50）
    final userRef = firestore.collection('users').doc(user.uid);
    final userDoc = await transaction.get(userRef);
    final userCurrentCoins = (userDoc.data()?['coins'] as int?) ?? 0;
    transaction.update(userRef, {
      'coins': userCurrentCoins + 50,
    });

    // 3. 紹介コードの使用数を増加
    final codeRef = firestore.collection('referral_codes').doc(code);
    transaction.update(codeRef, {
      'usedCount': usedCount + 1,
    });
  });

  return true;
});

String _generateRandomString(int length) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = DateTime.now().microsecond % 36;
  String result = '';
  for (int i = 0; i < length; i++) {
    result += chars[(random + i) % chars.length];
  }
  return result;
}
