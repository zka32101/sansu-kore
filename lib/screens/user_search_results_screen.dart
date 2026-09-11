import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_search_model.dart';
import '../providers/user_search_provider.dart';
import '../providers/friends_provider.dart';

/// ユーザー検索結果画面
class UserSearchResultsScreen extends ConsumerStatefulWidget {
  const UserSearchResultsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserSearchResultsScreen> createState() =>
      _UserSearchResultsScreenState();
}

class _UserSearchResultsScreenState
    extends ConsumerState<UserSearchResultsScreen> {
  final _searchController = TextEditingController();
  int? _selectedGrade;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    ref.read(userSearchProvider.notifier).searchUsers(query);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(userSearchProvider);
    final friendsState = ref.watch(friendsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ユーザーを検索'),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          // 検索バー
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ユーザーIDまたは名前で検索',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(userSearchProvider.notifier).clearSearch();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {});
                if (value.isNotEmpty) {
                  _performSearch(value);
                }
              },
            ),
          ),

          // 学年フィルタ
          if (searchState.searchResults.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('全て'),
                    selected: _selectedGrade == null,
                    onSelected: (selected) {
                      setState(() => _selectedGrade = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...List.generate(6, (index) {
                    final grade = index + 1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('${grade}年生'),
                        selected: _selectedGrade == grade,
                        onSelected: (selected) {
                          setState(() =>
                              _selectedGrade = selected ? grade : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // 検索結果
          Expanded(
            child: _buildSearchResults(
              searchState,
              friendsState,
              _selectedGrade,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    UserSearchState searchState,
    FriendsState friendsState,
    int? gradeFilter,
  ) {
    if (searchState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (searchState.error != null && searchState.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              searchState.error ?? 'エラーが発生しました',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (searchState.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'ユーザーを検索してください'
                  : 'ユーザーが見つかりません',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // フィルタ適用
    var results = searchState.searchResults;
    if (gradeFilter != null) {
      results = results.where((u) => u.gradeLevel == gradeFilter).toList();
    }

    if (results.isEmpty && gradeFilter != null) {
      return Center(
        child: Text(
          '${gradeFilter}年生のユーザーが見つかりません',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final user = results[index];
        return _UserSearchTile(
          user: user,
          friendsState: friendsState,
        );
      },
    );
  }
}

/// ユーザー検索結果タイル
class _UserSearchTile extends ConsumerStatefulWidget {
  final SearchUserData user;
  final FriendsState friendsState;

  const _UserSearchTile({
    required this.user,
    required this.friendsState,
  });

  @override
  ConsumerState<_UserSearchTile> createState() => _UserSearchTileState();
}

class _UserSearchTileState extends ConsumerState<_UserSearchTile> {
  bool _isRequestSending = false;

  @override
  Widget build(BuildContext context) {
    final isFriend =
        widget.friendsState.friends.any((f) => f.uid == widget.user.uid);
    final requestSent =
        widget.friendsState.sentRequests.contains(widget.user.uid);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // アバター
                CircleAvatar(
                  radius: 32,
                  backgroundImage: widget.user.avatarUrl != null
                      ? NetworkImage(widget.user.avatarUrl!)
                      : null,
                  child: widget.user.avatarUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),

                // ユーザー情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.getDisplayName(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${widget.user.uid}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.user.gradeLevel}年生',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // ボタン
                _buildActionButton(isFriend, requestSent),
              ],
            ),

            // スコア情報（オプション）
            if (widget.user.score != null || widget.user.correctRate != null)
              Column(
                children: [
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (widget.user.score != null)
                        Column(
                          children: [
                            Text(
                              '${widget.user.score}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              'スコア',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      if (widget.user.correctRate != null)
                        Column(
                          children: [
                            Text(
                              '${(widget.user.correctRate! * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              '正答率',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isFriend, bool requestSent) {
    if (isFriend) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check, size: 16),
        label: const Text('フレンド'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
        ),
      );
    }

    if (requestSent) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.hourglass_empty, size: 16),
        label: const Text('申請中'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade600,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _isRequestSending
          ? null
          : () => _sendFriendRequest(widget.user.uid),
      icon: const Icon(Icons.person_add, size: 16),
      label: const Text('追加'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _sendFriendRequest(String userId) async {
    setState(() => _isRequestSending = true);

    final success =
        await ref.read(friendsProvider.notifier).sendFriendRequest(userId);

    if (mounted) {
      setState(() => _isRequestSending = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('フレンドリクエストを送信しました')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('エラーが発生しました')),
        );
      }
    }
  }
}
