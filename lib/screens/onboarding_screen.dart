import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/coin_provider.dart';
import '../providers/grade_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _currentStep = 0;
  int _selectedGrade = 1;
  int? _selectedAnswer;
  bool _answered = false;
  bool _isCorrect = false;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 5) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    final name = _nameController.text.trim().isEmpty ? 'きみ' : _nameController.text.trim();
    await ref.read(profileProvider.notifier).addProfile(name, _selectedGrade);
    await ref.read(gradeProvider.notifier).setGrade(_selectedGrade);
    await ref.read(coinProvider.notifier).addCoins(30); // 初回ボーナスコイン
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _onAnswerTap(int idx) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = idx;
      _answered = true;
      _isCorrect = idx == 1; // 正解は「2」（1+1=2）
    });
    if (_isCorrect) {
      _bounceCtrl.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 1200), _nextStep);
    } else {
      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() {
          _selectedAnswer = null;
          _answered = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // プログレスバー
            LinearProgressIndicator(
              value: (_currentStep + 1) / 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
              minHeight: 4,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Name(),
                  _buildStep2Grade(),
                  _buildStep3Quiz(),
                  _buildStep4Character(),
                  _buildStep5Pokedex(),
                  _buildStep6Complete(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 1: 名前入力
  Widget _buildStep1Name() {
    return _StepWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔴', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          const Text(
            'ようこそ！小学コレ！算数へ',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kTextDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'きみの名前はなに？',
            style: TextStyle(fontSize: 18, color: kTextMuted),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'たろう',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 52),
            ),
            child: const Text('つぎへ →'),
          ),
        ],
      ),
    );
  }

  // Step 2: 学年選択
  Widget _buildStep2Grade() {
    return _StepWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎒', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            '何年生かな？',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kTextDark),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: 6,
            itemBuilder: (_, i) {
              final g = i + 1;
              final selected = _selectedGrade == g;
              return GestureDetector(
                onTap: () => setState(() => _selectedGrade = g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected ? kPrimaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? kPrimaryColor : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: kPrimaryColor.withAlpha(60), blurRadius: 8)]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      '小$g',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : kTextDark,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 52)),
            child: const Text('つぎへ →'),
          ),
        ],
      ),
    );
  }

  // Step 3: お試しクイズ
  Widget _buildStep3Quiz() {
    return _StepWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📝', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'まず、1問だけ！',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kTextDark),
          ),
          const SizedBox(height: 32),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '🔴  1 + 1 = ?',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kTextDark),
                ),
                const SizedBox(height: 24),
                ...List.generate(4, (i) {
                  final labels = ['1', '2', '3', '4'];
                  final isSelected = _selectedAnswer == i;
                  final isCorrect = i == 1;
                  Color bg = Colors.white;
                  if (_answered && isSelected) {
                    bg = isCorrect ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => _onAnswerTap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          labels[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _answered && isSelected ? Colors.white : kTextDark,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 4: キャラクター獲得演出
  Widget _buildStep4Character() {
    return _StepWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE082), Color(0xFFFFF9C4)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '⭐ 正解おめでとう！ ⭐',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark),
            ),
          ),
          const SizedBox(height: 32),
          ScaleTransition(
            scale: _bounceAnim,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: kPrimaryColor.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: kPrimaryColor, width: 3),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🔴', style: TextStyle(fontSize: 56)),
                  Text(
                    'イチコ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'イチコが仲間になったよ！',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'キャラクターを集めながら算数を学ぼう！',
            style: TextStyle(fontSize: 14, color: kTextMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 52)),
            child: const Text('図鑑で確認 →'),
          ),
        ],
      ),
    );
  }

  // Step 5: 図鑑表示
  Widget _buildStep5Pokedex() {
    return _StepWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'イチコが図鑑に入ったよ！',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kPrimaryColor, width: 2),
              boxShadow: [
                BoxShadow(color: kPrimaryColor.withAlpha(30), blurRadius: 12),
              ],
            ),
            child: Column(
              children: [
                const Text('🔴', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                const Text(
                  'イチコ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '1/110体',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '「あと109体の\nキャラが待ってるよ！」',
                  style: TextStyle(fontSize: 14, color: kTextMuted, height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // ロックされたキャラのプレビュー
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🔒', style: TextStyle(fontSize: 24)),
              ),
            )),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 52)),
            child: const Text('はじめよう！ →'),
          ),
        ],
      ),
    );
  }

  // Step 6: 完了
  Widget _buildStep6Complete() {
    final name = _nameController.text.trim().isEmpty ? 'きみ' : _nameController.text.trim();
    return _StepWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(
            '準備完了！\n$name（小$_selectedGrade）',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'さあ、何を学ぼう？',
            style: TextStyle(fontSize: 18, color: kTextMuted),
          ),
          const SizedBox(height: 32),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('🎁 スタートボーナス', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('コイン 30枚 をプレゼント！', style: TextStyle(color: kPrimaryColor, fontSize: 14)),
                const SizedBox(height: 4),
                const Text('2週間無料トライアル開始！', style: TextStyle(color: kAccentGreen, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _finishOnboarding,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(240, 56),
              backgroundColor: kAccentGreen,
            ),
            child: const Text('小学コレ！算数スタート 🚀', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _StepWrapper extends StatelessWidget {
  final Widget child;
  const _StepWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF5F5), Color(0xFFFFE8E8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: child,
        ),
      ),
    );
  }
}
