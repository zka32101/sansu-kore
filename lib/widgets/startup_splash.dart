import 'package:flutter/material.dart';

/// 組織ロゴ（画面下部用）。起動画面とアプリ本体スプラッシュで共通に使う。
class OrgLogoFooter extends StatelessWidget {
  const OrgLogoFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Semantics(
          label: 'Your Wish',
          child: Image.asset(
            'assets/branding/yourwish_logo.png',
            height: 40,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// 起動中の読み込み画面（中央に進行表示、下部に組織ロゴ）。
///
/// 初期化（Firebase・環境変数など）が終わる前に出す。app_common_kit の
/// `StartupSplash` と同じ見た目で、アプリ内に持っている。
class StartupSplash extends StatelessWidget {
  const StartupSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          Expanded(child: Center(child: CircularProgressIndicator())),
          OrgLogoFooter(),
        ],
      ),
    );
  }
}
