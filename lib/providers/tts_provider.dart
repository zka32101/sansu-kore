import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
enum TtsLanguage { japanese, english }
enum TtsSource { question, choice }

class TtsState {
  final bool isInitialized;
  final bool isSpeaking;
  final double volume;
  final double rate;
  final TtsSource? currentSource;  // どのボタンが再生中か

  const TtsState({
    this.isInitialized = false,
    this.isSpeaking = false,
    this.volume = 1.0,
    this.rate = 0.8,
    this.currentSource,
  });

  TtsState copyWith({
    bool? isInitialized,
    bool? isSpeaking,
    double? volume,
    double? rate,
    TtsSource? currentSource,
  }) =>
      TtsState(
        isInitialized: isInitialized ?? this.isInitialized,
        isSpeaking: isSpeaking ?? this.isSpeaking,
        volume: volume ?? this.volume,
        rate: rate ?? this.rate,
        currentSource: currentSource ?? this.currentSource,
      );
}

class TtsNotifier extends Notifier<TtsState> {
  late FlutterTts _tts;

  @override
  TtsState build() {
    _init();
    ref.onDispose(() async {
      try {
        await _tts.stop();
        // flutter_tts v4.2.5 には release() メソッドがないため、stop() のみ
      } catch (e) {
        if (kDebugMode) print('TTS cleanup error: $e');
      }
    });
    return const TtsState();
  }

  Future<void> _init() async {
    try {
      _tts = FlutterTts();

      // イベントリスナー設定
      _tts.setStartHandler(() {
        state = state.copyWith(isSpeaking: true);
      });

      _tts.setCompletionHandler(() {
        state = state.copyWith(isSpeaking: false);
      });

      _tts.setErrorHandler((msg) {
        state = state.copyWith(isSpeaking: false);
      });

      // 言語設定（日本語）
      await _tts.setLanguage('ja-JP');
      await _tts.setVolume(state.volume);
      await _tts.setSpeechRate(state.rate);

      state = state.copyWith(isInitialized: true);
    } catch (e) {
      if (kDebugMode) print('TTS init error: $e');
    }
  }

  /// テキストを音声で読み上げ（source追跡対応）
  Future<void> speak(String text, {TtsSource source = TtsSource.question}) async {
    if (!state.isInitialized || text.isEmpty) return;
    try {
      // 別の source が再生中なら停止
      if (state.isSpeaking && state.currentSource != source) {
        await _tts.stop();
      }

      state = state.copyWith(currentSource: source);
      await _tts.speak(text);
    } catch (e) {
      if (kDebugMode) print('TTS speak error: $e');
    }
  }

  /// 音声再生を停止
  Future<void> stop() async {
    try {
      await _tts.stop();
      state = state.copyWith(isSpeaking: false);
    } catch (e) {
      if (kDebugMode) print('TTS stop error: $e');
    }
  }

  /// 一時停止
  Future<void> pause() async {
    try {
      await _tts.pause();
      state = state.copyWith(isSpeaking: false);
    } catch (e) {
      if (kDebugMode) print('TTS pause error: $e');
    }
  }

  /// 音量を変更（0.0 ~ 1.0）
  Future<void> setVolume(double volume) async {
    if (volume < 0 || volume > 1) return;
    try {
      await _tts.setVolume(volume);
      state = state.copyWith(volume: volume);
    } catch (e) {
      if (kDebugMode) print('TTS volume error: $e');
    }
  }

  /// 読み上げ速度を変更（0.0 ~ 1.0）
  Future<void> setRate(double rate) async {
    if (rate < 0 || rate > 1) return;
    try {
      await _tts.setSpeechRate(rate);
      state = state.copyWith(rate: rate);
    } catch (e) {
      if (kDebugMode) print('TTS rate error: $e');
    }
  }

  /// 言語を変更
  Future<void> setLanguage(TtsLanguage language) async {
    try {
      final lang = language == TtsLanguage.japanese ? 'ja-JP' : 'en-US';
      await _tts.setLanguage(lang);
    } catch (e) {
      if (kDebugMode) print('TTS language error: $e');
    }
  }

}

final ttsProvider = NotifierProvider<TtsNotifier, TtsState>(
  TtsNotifier.new,
);
