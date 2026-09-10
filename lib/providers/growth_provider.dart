import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart' show profileProvider, ProfileDataMigration;
import 'package:shared_preferences/shared_preferences.dart';

// 成長タイムカプセル — 最初の記録 vs 現在の記録
const _growthBaseKey = 'growth_record';

class GrowthRecord {
  final DateTime recordedAt;
  final int stagesCleared;
  final int totalQuestions;
  final int correctCount;
  final int totalCoins;
  final String? message; // 将来の自分へのメッセージ

  const GrowthRecord({
    required this.recordedAt,
    required this.stagesCleared,
    required this.totalQuestions,
    required this.correctCount,
    required this.totalCoins,
    this.message,
  });

  double get accuracy => totalQuestions == 0 ? 0 : correctCount / totalQuestions;

  Map<String, dynamic> toJson() => {
    'recordedAt': recordedAt.toIso8601String(),
    'stagesCleared': stagesCleared,
    'totalQuestions': totalQuestions,
    'correctCount': correctCount,
    'totalCoins': totalCoins,
    'message': message,
  };

  factory GrowthRecord.fromJson(Map<String, dynamic> json) => GrowthRecord(
    recordedAt: DateTime.parse(json['recordedAt'] as String),
    stagesCleared: json['stagesCleared'] as int,
    totalQuestions: json['totalQuestions'] as int,
    correctCount: json['correctCount'] as int,
    totalCoins: json['totalCoins'] as int,
    message: json['message'] as String?,
  );
}

class GrowthState {
  final GrowthRecord? firstRecord; // 初回プレイ時の記録
  final GrowthRecord? currentRecord; // 最新の記録
  final List<GrowthRecord> history; // 過去の記録リスト（最大12件）

  const GrowthState({
    this.firstRecord,
    this.currentRecord,
    this.history = const [],
  });

  bool get hasData => firstRecord != null && currentRecord != null;

  int get stageGrowth =>
      (currentRecord?.stagesCleared ?? 0) - (firstRecord?.stagesCleared ?? 0);
  double get accuracyGrowth =>
      (currentRecord?.accuracy ?? 0) - (firstRecord?.accuracy ?? 0);
}

class GrowthNotifier extends Notifier<GrowthState> {
  String _getGrowthKey(String profileId) {
    return ProfileDataMigration.profileScopedKey(profileId, _growthBaseKey);
  }

  @override
  GrowthState build() => const GrowthState();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final profileState = ref.watch(profileProvider);
    final profileId = profileState.currentProfileId;

    if (profileId == null) {
      state = const GrowthState();
      return;
    }

    final growthKey = _getGrowthKey(profileId);
    final json = prefs.getString(growthKey);
    if (json == null) {
      state = const GrowthState();
      return;
    }

    final data = jsonDecode(json) as Map<String, dynamic>;
    final history = (data['history'] as List? ?? [])
        .map((e) => GrowthRecord.fromJson(e as Map<String, dynamic>))
        .toList();

    state = GrowthState(
      firstRecord: history.isNotEmpty ? history.first : null,
      currentRecord: history.isNotEmpty ? history.last : null,
      history: history,
    );
  }

  Future<void> saveSnapshot({
    required int stagesCleared,
    required int totalQuestions,
    required int correctCount,
    required int totalCoins,
    String? message,
  }) async {
    final record = GrowthRecord(
      recordedAt: DateTime.now(),
      stagesCleared: stagesCleared,
      totalQuestions: totalQuestions,
      correctCount: correctCount,
      totalCoins: totalCoins,
      message: message,
    );

    final newHistory = [...state.history, record];
    // 最大12件保持
    final trimmed = newHistory.length > 12
        ? newHistory.sublist(newHistory.length - 12)
        : newHistory;

    final newState = GrowthState(
      firstRecord: state.firstRecord ?? record,
      currentRecord: record,
      history: trimmed,
    );
    state = newState;

    final prefs = await SharedPreferences.getInstance();
    final profileState = ref.watch(profileProvider);
    final profileId = profileState.currentProfileId;

    if (profileId == null) return;

    final growthKey = _getGrowthKey(profileId);
    await prefs.setString(
      growthKey,
      jsonEncode({
        'history': trimmed.map((r) => r.toJson()).toList(),
      }),
    );
  }

  // ステージクリア時に自動保存
  Future<void> autoSnapshot({
    required int stagesCleared,
    required int totalQuestions,
    required int correctCount,
    required int totalCoins,
  }) async {
    // 最後の記録から7日以上経過 or 初回のみ保存
    final last = state.currentRecord;
    if (last != null) {
      final diff = DateTime.now().difference(last.recordedAt).inDays;
      if (diff < 7) return; // 7日以内は保存しない
    }
    await saveSnapshot(
      stagesCleared: stagesCleared,
      totalQuestions: totalQuestions,
      correctCount: correctCount,
      totalCoins: totalCoins,
    );
  }
}

final growthProvider =
    NotifierProvider<GrowthNotifier, GrowthState>(GrowthNotifier.new);
