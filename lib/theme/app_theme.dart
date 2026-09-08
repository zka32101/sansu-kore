import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' show buildAppTheme;

// 小学コレ！算数メインカラー（レッド）
const kPrimaryColor = Color(0xFFE74C3C);
const kPrimaryDark = Color(0xFFC0392B);
const kPrimaryDeep = Color(0xFF922B21);
const kAccentGreen = Color(0xFF27AE60);
const kAccentBlue = Color(0xFF2980B9);
const kAccentOrange = Color(0xFFF39C12);
const kBgLight = Color(0xFFFDF6F0);
const kTextDark = Color(0xFF2C3E50);
const kTextMuted = Color(0xFF7F8C8D);

ThemeData buildSansuTheme() => buildAppTheme(
  primaryColor: kPrimaryColor,
  secondaryColor: kAccentGreen,
  bgColor: kBgLight,
);

enum GradeGroup { low, mid, high }

GradeGroup gradeGroupOf(int grade) {
  if (grade <= 2) return GradeGroup.low;
  if (grade <= 4) return GradeGroup.mid;
  return GradeGroup.high;
}

Color gradeColor(GradeGroup g) {
  switch (g) {
    case GradeGroup.low: return const Color(0xFFE74C3C);
    case GradeGroup.mid: return const Color(0xFFC0392B);
    case GradeGroup.high: return const Color(0xFF922B21);
  }
}
