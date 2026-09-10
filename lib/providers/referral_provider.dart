import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart' show coinProvider;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/referral_model.dart';

const _myCodesKey = 'sansu_my_referral_codes'; // 自分が生成したコード → 受取済みコイン
const _redeemedCodesKey = 'sansu_redeemed_referral_codes'; // この端末で使用済みのコード

class ReferralState {
  final String? activeCode;
  final bool isBusy;
  final String? errorMessage;

  const ReferralState({
    this.activeCode,
    this.isBusy = false,
    this.errorMessage,
  });

  ReferralState copyWith({
    String? activeCode,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
  }) =>
      ReferralState(
        activeCode: activeCode ?? this.activeCode,
        isBusy: isBusy ?? this.isBusy,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class ReferralNotifier extends Notifier<ReferralState> {
  @override
  ReferralState build() {
    Future.microtask(_loadActiveCode);
    return const ReferralState();
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('referral_codes');

  Future<void> _loadActiveCode() async {
    final prefs = await SharedPreferences.getInstance();
    final myCodes = _readMyCodes(prefs);
    if (myCodes.isNotEmpty) {
      state = state.copyWith(activeCode: myCodes.keys.last);
    }
  }

  Map<String, int> _readMyCodes(SharedPreferences prefs) {
    final raw = prefs.getString(_myCodesKey);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).cast<String, int>();
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeMyCodes(SharedPreferences prefs, Map<String, int> codes) =>
      prefs.setString(_myCodesKey, jsonEncode(codes));

  /// 紹介コードを生成（既に有効なコードがあれば使い回す）
  Future<String?> generateCode() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        state = state.copyWith(
            isBusy: false, errorMessage: 'ネットワークに接続してから再度お試しください');
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      final myCodes = _readMyCodes(prefs);

      // 既存コードが有効ならそのまま使う
      if (myCodes.isNotEmpty) {
        final existing = myCodes.keys.last;
        final doc = await _collection.doc(existing).get();
        if (doc.exists) {
          final code = ReferralCode.fromMap(existing, doc.data()!);
          if (!code.isExpired) {
            state = state.copyWith(activeCode: existing, isBusy: false);
            return existing;
          }
        }
      }

      // 新規生成
      final newCode = _generateCodeString();
      await _collection.doc(newCode).set({
        'creatorId': userId,
        'creatorCoins': 0,
        'usedCount': 0,
        'maxUses': ReferralRewards.maxUsesPerCode,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.now().toDate().add(Duration(days: ReferralRewards.expirationDays)),
      });

      myCodes[newCode] = 0; // このコードで受取済みのコイン量（初期0）
      await _writeMyCodes(prefs, myCodes);

      state = state.copyWith(activeCode: newCode, isBusy: false);
      return newCode;
    } catch (e) {
      if (kDebugMode) print('referral generateCode error: $e');
      state = state.copyWith(
          isBusy: false, errorMessage: 'コードの生成に失敗しました。通信状態をご確認ください');
      return null;
    }
  }

  /// 友達から受け取ったコードを入力して適用する。
  /// 成功時は null、失敗時はエラーメッセージを返す。
  Future<String?> redeemCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) return 'コードを入力してください';

    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        state = state.copyWith(isBusy: false);
        return 'ネットワークに接続してから再度お試しください';
      }

      final prefs = await SharedPreferences.getInstance();
      final redeemed = prefs.getStringList(_redeemedCodesKey) ?? [];
      if (redeemed.contains(code)) {
        state = state.copyWith(isBusy: false);
        return 'このコードはすでに使用済みです';
      }
      final myCodes = _readMyCodes(prefs);
      if (myCodes.containsKey(code)) {
        state = state.copyWith(isBusy: false);
        return '自分のコードは使用できません';
      }

      final docRef = _collection.doc(code);
      String? error;
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists) {
          error = 'コードが見つかりません';
          return;
        }
        final data = snap.data()!;
        final referral = ReferralCode.fromMap(code, data);
        if (referral.creatorId == userId) {
          error = '自分のコードは使用できません';
          return;
        }
        if (!referral.isUsable) {
          if (referral.isExpired) {
            error = 'このコードの有効期限が切れています';
          } else {
            error = 'このコードは利用回数の上限に達しています';
          }
          return;
        }
        tx.update(docRef, {
          'usedCount': FieldValue.increment(1),
          'creatorCoins': FieldValue.increment(ReferralRewards.coinsForReferrer),
        });
      });

      if (error != null) {
        state = state.copyWith(isBusy: false);
        return error;
      }

      // 自分（招待された側）に即時付与
      await ref.read(coinProvider.notifier).addCoins(ReferralRewards.coinsForReferee);

      redeemed.add(code);
      await prefs.setStringList(_redeemedCodesKey, redeemed);

      state = state.copyWith(isBusy: false);
      return null;
    } catch (e) {
      if (kDebugMode) print('referral redeemCode error: $e');
      state = state.copyWith(isBusy: false);
      return 'コードの適用に失敗しました。通信状態をご確認ください';
    }
  }

  /// 自分が生成したコードが友達に使われて貯まった未受取コインを回収する。
  /// アプリ起動時・招待画面表示時に呼ぶ。
  Future<void> claimPendingCreatorRewards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final myCodes = _readMyCodes(prefs);
      if (myCodes.isEmpty) return;

      int totalClaim = 0;
      final updated = Map<String, int>.from(myCodes);

      for (final entry in myCodes.entries) {
        final doc = await _collection.doc(entry.key).get();
        if (!doc.exists) continue;
        final referral = ReferralCode.fromMap(entry.key, doc.data()!);
        final alreadyClaimed = entry.value;
        final pending = referral.creatorCoins - alreadyClaimed;
        if (pending > 0) {
          totalClaim += pending;
          updated[entry.key] = referral.creatorCoins;
        }
      }

      if (totalClaim > 0) {
        await ref.read(coinProvider.notifier).addCoins(totalClaim);
        await _writeMyCodes(prefs, updated);
      }
    } catch (e) {
      if (kDebugMode) print('referral claimPendingCreatorRewards error: $e');
    }
  }

  String _generateCodeString() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 紛らわしい文字(0,O,1,I)を除外
    final rand = Random.secure();
    final suffix =
        List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'SANSU$suffix';
  }
}

final referralProvider =
    NotifierProvider<ReferralNotifier, ReferralState>(ReferralNotifier.new);
