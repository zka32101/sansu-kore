import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/feedback_model.dart';

const _pendingKey = 'feedback_pending_queue';
const _uuid = Uuid();

/// 送信の状態。
enum FeedbackSubmitStatus { idle, submitting, success, error }

class FeedbackSubmitState {
  final FeedbackSubmitStatus status;
  final String? errorMessage;

  const FeedbackSubmitState({required this.status, this.errorMessage});

  static const idle = FeedbackSubmitState(status: FeedbackSubmitStatus.idle);

  FeedbackSubmitState copyWith({
    FeedbackSubmitStatus? status,
    String? errorMessage,
  }) =>
      FeedbackSubmitState(
        status: status ?? this.status,
        errorMessage: errorMessage,
      );
}

/// 実際の送信処理（Firestore書き込み等）は各アプリ側から注入する。
/// shared_core は cloud_firestore に依存しないため、送信手段はコールバックとして
/// 外から与えてもらう（badge_provider の setBadgeDefinitions と同じ「型・共通ロジックは
/// shared_core、実処理はアプリ側」という設計）。
typedef FeedbackSubmitHandler = Future<void> Function(FeedbackReport report);

class FeedbackNotifier extends Notifier<FeedbackSubmitState> {
  FeedbackSubmitHandler? _submitHandler;

  /// 各アプリが実際の送信処理（Firestoreの `feedback` コレクションへの書き込み等）を注入する。
  void setSubmitHandler(FeedbackSubmitHandler handler) {
    _submitHandler = handler;
  }

  @override
  FeedbackSubmitState build() => FeedbackSubmitState.idle;

  String _detectPlatform() {
    if (kIsWeb) return 'Web';
    try {
      if (Platform.isIOS) return 'iOS';
      if (Platform.isAndroid) return 'Android';
      return Platform.operatingSystem;
    } catch (_) {
      return 'unknown';
    }
  }

  /// バグ報告・改善要望を送信する。
  ///
  /// Firestore等への送信は [setSubmitHandler] で登録したコールバックが行う。
  /// 未登録、または送信に失敗した場合はローカル（SharedPreferences）に
  /// 一時保存し、次回 [retryPendingReports] 呼び出し時（通常はアプリ起動時）に
  /// 再送信を試みる簡易的なオフラインキューとして扱う。
  Future<void> submitFeedback({
    required FeedbackType type,
    required String title,
    required String description,
    required String appName,
    String appVersion = '',
  }) async {
    state = state.copyWith(status: FeedbackSubmitStatus.submitting, errorMessage: null);

    final report = FeedbackReport(
      id: _uuid.v4(),
      type: type,
      title: title,
      description: description,
      appName: appName,
      appVersion: appVersion,
      platform: _detectPlatform(),
      createdAt: DateTime.now(),
      userId: FirebaseAuth.instance.currentUser?.uid,
    );

    final handler = _submitHandler;
    if (handler == null) {
      await _enqueuePending(report);
      state = state.copyWith(status: FeedbackSubmitStatus.success);
      return;
    }

    try {
      await handler(report);
      state = state.copyWith(status: FeedbackSubmitStatus.success);
    } catch (e) {
      await _enqueuePending(report);
      // ローカルに退避できたのでユーザーには送信済みとして扱ってよいが、
      // 直近の送信自体は失敗したことをエラーとして保持する。
      state = state.copyWith(status: FeedbackSubmitStatus.error, errorMessage: e.toString());
    }
  }

  void reset() {
    state = FeedbackSubmitState.idle;
  }

  Future<List<FeedbackReport>> _loadPending(SharedPreferences prefs) async {
    final raw = prefs.getStringList(_pendingKey) ?? [];
    return raw
        .map((s) {
          try {
            return FeedbackReport.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<FeedbackReport>()
        .toList();
  }

  Future<void> _savePending(SharedPreferences prefs, List<FeedbackReport> reports) async {
    await prefs.setStringList(
      _pendingKey,
      reports.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  Future<void> _enqueuePending(FeedbackReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = await _loadPending(prefs);
    pending.add(report);
    await _savePending(prefs, pending);
  }

  /// 未送信キューの再送信を試みる。アプリ起動時に呼び出す想定。
  /// [setSubmitHandler] が未登録の場合は何もしない。
  Future<void> retryPendingReports() async {
    final handler = _submitHandler;
    if (handler == null) return;

    final prefs = await SharedPreferences.getInstance();
    final pending = await _loadPending(prefs);
    if (pending.isEmpty) return;

    final stillFailed = <FeedbackReport>[];
    for (final report in pending) {
      try {
        await handler(report);
      } catch (_) {
        stillFailed.add(report);
      }
    }
    await _savePending(prefs, stillFailed);
  }
}

final feedbackProvider = NotifierProvider<FeedbackNotifier, FeedbackSubmitState>(FeedbackNotifier.new);
