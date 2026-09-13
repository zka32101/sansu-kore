import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/models/daily_mission_model.dart';

/// 日々のミッション提供者
final dailyMissionProvider = StateNotifierProvider<DailyMissionNotifier, List<DailyMission>>((ref) {
  return DailyMissionNotifier();
});

class DailyMissionNotifier extends StateNotifier<List<DailyMission>> {
  DailyMissionNotifier() : super([]) {
    _initializeMissions();
  }

  void _initializeMissions() {
    // 初期ミッションロード
    state = [
      DailyMission(
        id: 'daily_1',
        title: '毎日クイズをプレイ',
        description: '1つ以上のクイズをプレイしよう',
        reward: 10,
        isCompleted: false,
      ),
      DailyMission(
        id: 'daily_2',
        title: '5問正解',
        description: '今日5問以上正解しよう',
        reward: 20,
        isCompleted: false,
      ),
      DailyMission(
        id: 'daily_3',
        title: 'ステージクリア',
        description: '1つのステージをクリアしよう',
        reward: 30,
        isCompleted: false,
      ),
    ];
  }

  void completeMission(String missionId) {
    state = [
      for (final mission in state)
        if (mission.id == missionId)
          mission.copyWith(isCompleted: true)
        else
          mission,
    ];
  }
}
