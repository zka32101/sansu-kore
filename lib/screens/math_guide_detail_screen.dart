// Math Guide Detail Screen - Full step-by-step tutorial display
// Shows complete guide with navigation and progress tracking

import 'package:flutter/material.dart';
import 'package:sansu_kore/models/math_guide_model.dart';
import 'package:sansu_kore/widgets/math_guide_widgets.dart';

/// 数学ガイド詳細画面
/// フルスクリーンでガイドの全ステップを表示
class MathGuideDetailScreen extends StatelessWidget {
  final MathGuide guide;

  const MathGuideDetailScreen({
    Key? key,
    required this.guide,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(guide.title),
        centerTitle: true,
        backgroundColor: Colors.blue.shade400,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: MathGuideDetail(guide: guide),
    );
  }
}
