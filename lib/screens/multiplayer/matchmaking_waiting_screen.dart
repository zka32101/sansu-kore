import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart' show MatchmakingSearchWidget, matchmakingProvider, MatchmakingStatus;


import '../../providers/multiplayer_provider.dart';
import '../../theme/app_theme.dart';
import 'multiplayer_quiz_screen.dart';
class MatchmakingWaitingScreen extends ConsumerStatefulWidget {
  final String userId;
  final String displayName;
  final double rating;
  final int grade;

  const MatchmakingWaitingScreen({
    super.key,
    required this.userId,
    required this.displayName,
    required this.rating,
    required this.grade,
  });

  @override
  ConsumerState<MatchmakingWaitingScreen> createState() => _MatchmakingWaitingScreenState();
}

class _MatchmakingWaitingScreenState extends ConsumerState<MatchmakingWaitingScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(matchmakingProvider.notifier).startSearching(
            userId: widget.userId,
            displayName: widget.displayName,
            rating: widget.rating,
            metadata: sansuMatchmakingMetadata(widget.grade),
          );
    });
  }

  @override
  void dispose() {
    // 画面を離れる際、まだマッチングが成立していなければキューから抜ける。
    if (!_navigated) {
      ref.read(matchmakingProvider.notifier).cancelSearch(widget.userId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(matchmakingProvider, (previous, next) {
      if (next.status == MatchmakingStatus.matched && next.matchId != null && !_navigated) {
        _navigated = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MultiplayerQuizScreen(
              matchId: next.matchId!,
              userId: widget.userId,
              grade: widget.grade,
            ),
          ),
        );
      }
    });

    final state = ref.watch(matchmakingProvider);

    return Scaffold(
      backgroundColor: kPrimaryDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: state.status == MatchmakingStatus.error
                ? _buildError(context, state.errorMessage)
                : MatchmakingSearchWidget(
                    avatar: const Text('🧮', style: TextStyle(fontSize: 48)),
                    displayName: widget.displayName,
                    rating: widget.rating,
                    accentColor: Colors.white,
                    onCancel: () {
                      _navigated = true; // dispose での二重 cancelSearch を防止
                      ref.read(matchmakingProvider.notifier).cancelSearch(widget.userId);
                      Navigator.of(context).pop();
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String? message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 48),
        const SizedBox(height: 16),
        Text(
          message ?? '対戦相手が見つかりませんでした。',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('戻る'),
        ),
      ],
    );
  }
}
