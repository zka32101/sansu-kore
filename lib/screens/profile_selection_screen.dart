import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../providers/grade_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
class ProfileSelectionScreen extends ConsumerStatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  ConsumerState<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends ConsumerState<ProfileSelectionScreen> {
  late TextEditingController _nameController;
  int _selectedGrade = 1;
  int _selectedAvatarIndex = 0;

  // アバター一覧（ファイル名順）
  static const List<String> avatarFiles = [
    '1. 茶色クマ  (honhon - Brown Bear).jpg',
    '2. 黒猫  (kuro-neko - Black Cat).jpg',
    '3. パンダ  (panda - Giant Panda).jpg',
    '4. キツネ  (kitsune - Fox).jpg',
    '5. ウサギ  (usagi - Rabbit).jpg',
    '6. トラ  (tora - Tiger).jpg',
    '7. ライオン  (raion - Lion).jpg',
    '8. カエル  (kaeru - Frog).jpg',
    '9. アヒル  (ahiru - Duck).jpg',
    '10. ブタ  (buta - Pig).jpg',
    '11. コアラ  (koala - Koala).jpg',
    '12. キリン  (kirin - Giraffe).jpg',
    '13. カンガルー (kangaroo).jpg',
    '14. イヌ  (inu - Dog).jpg',
    '15. アライグマ  (arai-guma - Raccoon).jpg',
    '16. ナマケモノ  (namakemono - Sloth).jpg',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showAddProfileDialog() {
    _nameController.clear();
    _selectedGrade = 1;
    _selectedAvatarIndex = 0;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('プロフィールを追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'お名前', hintText: 'たろう'),
              ),
              const SizedBox(height: 16),
              DropdownButton<int>(
                value: _selectedGrade,
                isExpanded: true,
                items: List.generate(6, (i) => i + 1).map((g) {
                  return DropdownMenuItem(value: g, child: Text('小学$g年生'));
                }).toList(),
                onChanged: (val) => setDialogState(() => _selectedGrade = val ?? 1),
              ),
              const SizedBox(height: 16),
              const Text('アバターを選ぶ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: avatarFiles.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => _selectedAvatarIndex = index),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedAvatarIndex == index ? kPrimaryColor : Colors.grey,
                            width: _selectedAvatarIndex == index ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset('assets/avatars/${avatarFiles[index]}', fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  await ref.read(profileProvider.notifier).addProfile(
                    _nameController.text,
                    _selectedGrade,
                  );
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final profiles = profileState.profiles;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF5F5), Color(0xFFFFE8E8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text('🔴', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              const Text(
                '小学コレ！算数',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kPrimaryColor),
              ),
              const SizedBox(height: 8),
              const Text(
                'だれが使う？',
                style: TextStyle(fontSize: 18, color: kTextMuted),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: profiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('プロフィールがありません', style: TextStyle(color: kTextMuted)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showAddProfileDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('プロフィールを追加'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: profiles.length + 1,
                        itemBuilder: (_, i) {
                          if (i == profiles.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: OutlinedButton.icon(
                                onPressed: _showAddProfileDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('別のプロフィールを追加'),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: kPrimaryColor),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            );
                          }
                          final profile = profiles[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () async {
                                // 前のユーザーのデータをクリア
                                await ref.read(profileProvider.notifier).clearUserData();
                                await ref.read(profileProvider.notifier).setCurrentProfile(profile.id);
                                await ref.read(gradeProvider.notifier).setGrade(profile.grade);
                                if (mounted) {
                                  Navigator.of(context).pushReplacementNamed('/home');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: kPrimaryColor.withAlpha(30),
                                      radius: 28,
                                      child: Text(
                                        profile.name.isNotEmpty ? profile.name[0] : '？',
                                        style: const TextStyle(fontSize: 24, color: kPrimaryColor),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            profile.name,
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            '小学${profile.grade}年生',
                                            style: const TextStyle(fontSize: 14, color: kTextMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, color: kTextMuted, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
