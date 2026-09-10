import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../providers/friends_provider.dart';
import '../theme/app_theme.dart';
class FriendRequestsScreen extends ConsumerStatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  ConsumerState<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFriends();
    });
  }

  void _initializeFriends() {
    ref.read(friendsProvider.notifier).fetchFriends();
  }

  @override
  Widget build(BuildContext context) {
    final friendsState = ref.watch(friendsProvider);
    final pendingRequests = friendsState.pendingRequests;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text(
          'フレンドリクエスト',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: pendingRequests.isEmpty
          ? _EmptyRequestsView()
          : ListView.builder(
              itemCount: pendingRequests.length,
              itemBuilder: (context, index) {
                final userId = pendingRequests[index];
                return _RequestTile(userId: userId);
              },
            ),
    );
  }
}

/// リクエストタイル
class _RequestTile extends ConsumerWidget {
  final String userId;

  const _RequestTile({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kPrimaryColor.withOpacity(0.3),
          child: const Text(
            'U',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
        ),
        title: const Text(
          'ユーザー',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'ユーザーID: $userId',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _acceptRequest(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _rejectRequest(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptRequest(BuildContext context, WidgetRef ref) async {
    await ref.read(friendsProvider.notifier).acceptFriendRequest(userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('フレンドを追加しました')),
      );
    }
  }

  Future<void> _rejectRequest(BuildContext context, WidgetRef ref) async {
    await ref.read(friendsProvider.notifier).rejectFriendRequest(userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('リクエストを拒否しました')),
      );
    }
  }
}

/// リクエストなし表示
class _EmptyRequestsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'リクエストがありません',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '新しいフレンドリクエストがある時\nここに表示されます',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
