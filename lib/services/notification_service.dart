import 'dart:convert';


import 'package:shared_preferences/shared_preferences.dart';


// 親のほめ導線自動化（設計書S-rank機能）
// FCMが未設定の場合はローカルのほめメッセージキューで代替
// 実際のプロダクションではFirebase Messagingと連携する
const _praiseQueueKey = 'praise_queue';
const _praiseCountKey = 'praise_sent_count';

class PraiseMessage {
  final String childName;
  final String achievement;
  final DateTime timestamp;
  final bool isRead;

  const PraiseMessage({
    required this.childName,
    required this.achievement,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'childName': childName,
    'achievement': achievement,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  factory PraiseMessage.fromJson(Map<String, dynamic> json) => PraiseMessage(
    childName: json['childName'] as String,
    achievement: json['achievement'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    isRead: json['isRead'] as bool? ?? false,
  );

  PraiseMessage copyWith({bool? isRead}) => PraiseMessage(
    childName: childName,
    achievement: achievement,
    timestamp: timestamp,
    isRead: isRead ?? this.isRead,
  );
}

// 設計書の推奨ほめメッセージ候補
const List<String> kPraiseTemplates = [
  'すごいね！頑張ったね！',
  '次のステージも楽しみだね',
  'パパ（ママ）も嬉しいよ',
  'よく頑張った！天才だね！',
  '続けてえらい！',
];

class NotificationService {
  // 達成時のほめメッセージをキューに追加（FCMの代替）
  static Future<void> triggerParentPraise({
    required String childName,
    required String achievement,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // キューに追加
    final queueJson = prefs.getString(_praiseQueueKey);
    final queue = queueJson != null
        ? (jsonDecode(queueJson) as List).map((e) => PraiseMessage.fromJson(e)).toList()
        : <PraiseMessage>[];

    queue.add(PraiseMessage(
      childName: childName,
      achievement: achievement,
      timestamp: DateTime.now(),
    ));

    // 最大10件保持
    if (queue.length > 10) queue.removeAt(0);

    await prefs.setString(_praiseQueueKey, jsonEncode(queue.map((m) => m.toJson()).toList()));

    // FCM送信（本番環境でFirebase Messagingと連携）
    // await _sendFCMNotification(childName, achievement);
  }

  static Future<List<PraiseMessage>> getPraiseQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_praiseQueueKey);
    if (json == null) return [];
    return (jsonDecode(json) as List).map((e) => PraiseMessage.fromJson(e)).toList();
  }

  static Future<void> markAsRead(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getPraiseQueue();
    if (index >= 0 && index < queue.length) {
      queue[index] = queue[index].copyWith(isRead: true);
      await prefs.setString(
        _praiseQueueKey,
        jsonEncode(queue.map((m) => m.toJson()).toList()),
      );
    }
  }

  static Future<int> getUnreadCount() async {
    final queue = await getPraiseQueue();
    return queue.where((m) => !m.isRead).length;
  }

  // セーフティネット：つまずき検出通知
  static Future<void> triggerStrugglingAlert({
    required String childName,
    required String topicName,
  }) async {
    // 親へ「${childName}が${topicName}で少しつまずいています」を通知
    // 本番ではFCM経由で親デバイスにプッシュ通知
    await triggerParentPraise(
      childName: childName,
      achievement: '$topicNameでつまずいているようです。今日は「よく頑張ってるね」と声をかけてあげてください。',
    );
  }

  // ランキングマイルストーン達成通知
  static Future<void> triggerRankingMilestone({
    required String childName,
    required int rank,
    required String milestone,
  }) async {
    String achievement;
    switch (milestone) {
      case 'top10':
        achievement = '🥇 $childNameさんがランキングトップ10に入りました！おめでとう🎉';
        break;
      case 'top100':
        achievement = '🏆 $childNameさんがランキングトップ100に入りました！やった👏';
        break;
      case 'weekly_win':
        achievement = '👑 $childNameさんが週間ランキング第1位になりました！スーパースター！🌟';
        break;
      default:
        achievement = 'ランキングが更新されました！ ${rank}位です。';
    }

    // 親へランキング達成を通知
    await triggerParentPraise(
      childName: childName,
      achievement: achievement,
    );

    // 本番ではFCM経由でプッシュ通知を送信
    // await _sendFCMNotification(childName, achievement);
  }
}
