import 'dart:math' as math;


import 'package:flutter/material.dart';
class GeometryVisualWidget extends StatelessWidget {
  final String shapeName;

  const GeometryVisualWidget({super.key, required this.shapeName});

  static const Map<String, String> _jpNames = {
    'triangle': '三角形',
    'right_triangle': '直角三角形',
    'isosceles_triangle': '二等辺三角形',
    'equilateral_triangle': '正三角形',
    'square': '正方形',
    'rectangle': '長方形',
    'parallelogram': '平行四辺形',
    'rhombus': 'ひし形',
    'trapezoid': '台形',
    'circle': '円',
    'circle_radius': '半径と直径',
    'pentagon': '正五角形',
    'hexagon': '正六角形',
    'cube': '立方体',
    'box': '直方体',
    'cylinder': '円柱',
    'sphere': '球',
    'angle_right': '直角（90°）',
    'angle_acute': '鋭角（90°未満）',
    'angle_obtuse': '鈍角（90°〜180°）',
    'area_rectangle': '長方形の面積 = たて × よこ',
    'area_triangle': '三角形の面積 = 底辺 × 高さ ÷ 2',
    'area_parallelogram': '平行四辺形の面積 = 底辺 × 高さ',
    'area_circle': '円の面積 = 半径 × 半径 × π',
  };

  @override
  Widget build(BuildContext context) {
    final jpName = _jpNames[shapeName] ?? shapeName;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBCCFF), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 13, color: Color(0xFF5566BB)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  jpName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5566BB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(
              painter: _ShapePainter(shapeName: shapeName),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final String shapeName;
  const _ShapePainter({required this.shapeName});

  static const _blue = Color(0xFF5599FF);
  static const _fillColor = Color(0xFFCCDDFF);
  static const _fillLight = Color(0xFFE8F0FF);
  static const _red = Color(0xFFEE4444);
  static const _green = Color(0xFF33AA55);
  static const _labelStyle = TextStyle(
    color: Color(0xFF2244AA), fontSize: 11, fontWeight: FontWeight.bold,
  );
  static const _labelSm = TextStyle(
    color: Color(0xFF2244AA), fontSize: 10, fontWeight: FontWeight.w600,
  );

  Paint get _stroke => Paint()
    ..color = _blue
    ..strokeWidth = 2.5
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint get _fill => Paint()
    ..color = _fillColor
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    switch (shapeName) {
      case 'triangle':
        _triangle(canvas, cx, cy - 8);
        break;
      case 'right_triangle':
        _rightTriangle(canvas, cx, cy - 8);
        break;
      case 'isosceles_triangle':
        _isoscelesTriangle(canvas, cx, cy - 8);
        break;
      case 'equilateral_triangle':
        _equilateralTriangle(canvas, cx, cy - 8);
        break;
      case 'square':
        _square(canvas, cx, cy - 8);
        break;
      case 'rectangle':
        _rectangle(canvas, cx, cy - 8);
        break;
      case 'parallelogram':
        _parallelogram(canvas, cx, cy - 8);
        break;
      case 'rhombus':
        _rhombus(canvas, cx, cy - 8);
        break;
      case 'trapezoid':
        _trapezoid(canvas, cx, cy - 8);
        break;
      case 'circle':
        _circle(canvas, cx, cy - 8);
        break;
      case 'circle_radius':
        _circleRadius(canvas, cx, cy - 8);
        break;
      case 'pentagon':
        _polygon(canvas, cx, cy - 5, 5, 52);
        _drawLabel(canvas, cx, cy + 58, '正五角形（5つの角）', _labelStyle);
        break;
      case 'hexagon':
        _polygon(canvas, cx, cy - 5, 6, 52);
        _drawLabel(canvas, cx, cy + 58, '正六角形（6つの角）', _labelStyle);
        break;
      case 'cube':
        _cube(canvas, cx, cy - 8);
        break;
      case 'box':
        _box(canvas, cx, cy - 8);
        break;
      case 'cylinder':
        _cylinder(canvas, cx, cy - 8);
        break;
      case 'sphere':
        _sphere(canvas, cx, cy - 8);
        break;
      case 'angle_right':
        _angleRight(canvas, cx, cy);
        break;
      case 'angle_acute':
        _angle(canvas, cx, cy, 50, '鋭角（50°）');
        break;
      case 'angle_obtuse':
        _angle(canvas, cx, cy, 120, '鈍角（120°）');
        break;
      case 'area_rectangle':
        _areaRectangle(canvas, cx, cy - 8);
        break;
      case 'area_triangle':
        _areaTriangle(canvas, cx, cy - 8);
        break;
      case 'area_parallelogram':
        _areaParallelogram(canvas, cx, cy - 8);
        break;
      case 'area_circle':
        _areaCircle(canvas, cx, cy - 8);
        break;
    }
  }

  // ─── 基本図形 ────────────────────────────────────────────────────

  void _triangle(Canvas canvas, double cx, double cy) {
    _drawPath(canvas, [
      Offset(cx, cy - 48),
      Offset(cx - 55, cy + 42),
      Offset(cx + 55, cy + 42),
    ]);
    _drawLabel(canvas, cx, cy + 55, '三角形（3つの辺・3つの角）', _labelStyle);
  }

  void _rightTriangle(Canvas canvas, double cx, double cy) {
    final l = cx - 55, r = cx + 55, top = cy - 40, bot = cy + 42;
    _drawPath(canvas, [Offset(l, top), Offset(l, bot), Offset(r, bot)]);
    _cornerMark(canvas, l, bot, true);
    _drawLabel(canvas, cx + 5, bot + 14, '直角三角形（直角=90°）', _labelStyle);
  }

  void _isoscelesTriangle(Canvas canvas, double cx, double cy) {
    final p1 = Offset(cx, cy - 50);
    final p2 = Offset(cx - 48, cy + 42);
    final p3 = Offset(cx + 48, cy + 42);
    _drawPath(canvas, [p1, p2, p3]);
    _tickMark(canvas, p1, p2);
    _tickMark(canvas, p1, p3);
    _drawLabel(canvas, cx, cy + 55, '二等辺三角形（2辺が等しい）', _labelStyle);
  }

  void _equilateralTriangle(Canvas canvas, double cx, double cy) {
    const r = 52.0;
    final pts = List.generate(3, (i) {
      final a = -math.pi / 2 + i * 2 * math.pi / 3;
      return Offset(cx + r * math.cos(a), cy + r * math.sin(a) + 6);
    });
    _drawPath(canvas, pts);
    _tickMark(canvas, pts[0], pts[1]);
    _tickMark(canvas, pts[1], pts[2]);
    _tickMark(canvas, pts[2], pts[0]);
    _drawLabel(canvas, cx, cy + 62, '正三角形（3辺が等しい）', _labelStyle);
  }

  void _square(Canvas canvas, double cx, double cy) {
    const s = 76.0;
    final r = Rect.fromCenter(center: Offset(cx, cy), width: s, height: s);
    canvas.drawRect(r, _fill);
    canvas.drawRect(r, _stroke);
    _cornerMark(canvas, r.left, r.top, false);
    _tickMark(canvas, Offset(r.left, r.top), Offset(r.right, r.top));
    _tickMark(canvas, Offset(r.left, r.top), Offset(r.left, r.bottom));
    _drawLabel(canvas, cx, r.bottom + 14, '正方形（4辺が等しい）', _labelStyle);
  }

  void _rectangle(Canvas canvas, double cx, double cy) {
    const w = 110.0, h = 64.0;
    final r = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
    canvas.drawRect(r, _fill);
    canvas.drawRect(r, _stroke);
    _tickMark(canvas, Offset(r.left, r.top), Offset(r.right, r.top));
    _tickMark(canvas, Offset(r.left, r.bottom), Offset(r.right, r.bottom));
    _tickMark2(canvas, Offset(r.left, r.top), Offset(r.left, r.bottom));
    _tickMark2(canvas, Offset(r.right, r.top), Offset(r.right, r.bottom));
    _drawLabel(canvas, cx, r.bottom + 14, '長方形（向かい合う辺が等しい）', _labelStyle);
  }

  void _parallelogram(Canvas canvas, double cx, double cy) {
    const shift = 22.0, w = 96.0, h = 56.0;
    _drawPath(canvas, [
      Offset(cx - w / 2 + shift, cy - h / 2),
      Offset(cx + w / 2 + shift, cy - h / 2),
      Offset(cx + w / 2 - shift, cy + h / 2),
      Offset(cx - w / 2 - shift, cy + h / 2),
    ]);
    _drawLabel(canvas, cx, cy + h / 2 + 14, '平行四辺形（向かい合う辺が平行）', _labelSm);
  }

  void _rhombus(Canvas canvas, double cx, double cy) {
    const hw = 56.0, hh = 44.0;
    _drawPath(canvas, [
      Offset(cx, cy - hh),
      Offset(cx + hw, cy),
      Offset(cx, cy + hh),
      Offset(cx - hw, cy),
    ]);
    _drawLabel(canvas, cx, cy + hh + 14, 'ひし形（4辺が等しい）', _labelStyle);
  }

  void _trapezoid(Canvas canvas, double cx, double cy) {
    const topW = 56.0, botW = 108.0, h = 56.0;
    _drawPath(canvas, [
      Offset(cx - topW / 2, cy - h / 2),
      Offset(cx + topW / 2, cy - h / 2),
      Offset(cx + botW / 2, cy + h / 2),
      Offset(cx - botW / 2, cy + h / 2),
    ]);
    _drawLabel(canvas, cx, cy + h / 2 + 14, '台形（上底と下底が平行）', _labelStyle);
  }

  void _circle(Canvas canvas, double cx, double cy) {
    canvas.drawCircle(Offset(cx, cy), 50, _fill);
    canvas.drawCircle(Offset(cx, cy), 50, _stroke);
    canvas.drawCircle(Offset(cx, cy), 3,
        Paint()..color = _blue..style = PaintingStyle.fill);
    _drawLabel(canvas, cx, cy + 65, '円（中心から外まで等しい）', _labelStyle);
  }

  void _circleRadius(Canvas canvas, double cx, double cy) {
    const r = 46.0;
    canvas.drawCircle(Offset(cx, cy), r, _fill);
    canvas.drawCircle(Offset(cx, cy), r, _stroke);
    canvas.drawCircle(Offset(cx, cy), 3,
        Paint()..color = _blue..style = PaintingStyle.fill);
    // 半径（赤）
    final rp = Paint()..color = _red..strokeWidth = 2.5..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, cy), Offset(cx + r, cy), rp);
    _drawLabel(canvas, cx + r / 2, cy - 10, '半径(r)', TextStyle(color: _red, fontSize: 10, fontWeight: FontWeight.bold));
    // 直径（緑）
    final dp = Paint()..color = _green..strokeWidth = 1.8..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx - r, cy + 16), Offset(cx + r, cy + 16), dp);
    _drawLabel(canvas, cx, cy + 24, '直径 = 半径 × 2', TextStyle(color: _green, fontSize: 10, fontWeight: FontWeight.bold));
    _drawLabel(canvas, cx, cy + 64, '半径と直径の関係', _labelStyle);
  }

  void _polygon(Canvas canvas, double cx, double cy, int n, double r) {
    final pts = List.generate(n, (i) {
      final a = -math.pi / 2 + i * 2 * math.pi / n;
      return Offset(cx + r * math.cos(a), cy + r * math.sin(a));
    });
    _drawPath(canvas, pts);
  }

  // ─── 立体 ─────────────────────────────────────────────────────────

  void _cube(Canvas canvas, double cx, double cy) {
    const s = 58.0, d = 22.0;
    final fp = Paint()..color = _fillLight..style = PaintingStyle.fill;
    // 上面
    _fillPath(canvas, fp, [
      Offset(cx - s / 2, cy - s / 2), Offset(cx - s / 2 + d, cy - s / 2 - d),
      Offset(cx + s / 2 + d, cy - s / 2 - d), Offset(cx + s / 2, cy - s / 2),
    ]);
    _drawPath(canvas, [
      Offset(cx - s / 2, cy - s / 2), Offset(cx - s / 2 + d, cy - s / 2 - d),
      Offset(cx + s / 2 + d, cy - s / 2 - d), Offset(cx + s / 2, cy - s / 2),
    ]);
    // 右面
    _fillPath(canvas, fp, [
      Offset(cx + s / 2, cy - s / 2), Offset(cx + s / 2 + d, cy - s / 2 - d),
      Offset(cx + s / 2 + d, cy + s / 2 - d), Offset(cx + s / 2, cy + s / 2),
    ]);
    _drawPath(canvas, [
      Offset(cx + s / 2, cy - s / 2), Offset(cx + s / 2 + d, cy - s / 2 - d),
      Offset(cx + s / 2 + d, cy + s / 2 - d), Offset(cx + s / 2, cy + s / 2),
    ]);
    // 前面
    final r = Rect.fromLTWH(cx - s / 2, cy - s / 2, s, s);
    canvas.drawRect(r, Paint()..color = _fillColor..style = PaintingStyle.fill);
    canvas.drawRect(r, _stroke);
    _drawLabel(canvas, cx + d / 2, cy + s / 2 + 14, '立方体（全面が正方形）', _labelStyle);
  }

  void _box(Canvas canvas, double cx, double cy) {
    const w = 78.0, h = 48.0, d = 24.0;
    final fp = Paint()..color = _fillLight..style = PaintingStyle.fill;
    _fillPath(canvas, fp, [
      Offset(cx - w / 2, cy - h / 2), Offset(cx - w / 2 + d, cy - h / 2 - d),
      Offset(cx + w / 2 + d, cy - h / 2 - d), Offset(cx + w / 2, cy - h / 2),
    ]);
    _drawPath(canvas, [
      Offset(cx - w / 2, cy - h / 2), Offset(cx - w / 2 + d, cy - h / 2 - d),
      Offset(cx + w / 2 + d, cy - h / 2 - d), Offset(cx + w / 2, cy - h / 2),
    ]);
    _fillPath(canvas, fp, [
      Offset(cx + w / 2, cy - h / 2), Offset(cx + w / 2 + d, cy - h / 2 - d),
      Offset(cx + w / 2 + d, cy + h / 2 - d), Offset(cx + w / 2, cy + h / 2),
    ]);
    _drawPath(canvas, [
      Offset(cx + w / 2, cy - h / 2), Offset(cx + w / 2 + d, cy - h / 2 - d),
      Offset(cx + w / 2 + d, cy + h / 2 - d), Offset(cx + w / 2, cy + h / 2),
    ]);
    final r = Rect.fromLTWH(cx - w / 2, cy - h / 2, w, h);
    canvas.drawRect(r, Paint()..color = _fillColor..style = PaintingStyle.fill);
    canvas.drawRect(r, _stroke);
    _drawLabel(canvas, cx + d / 2, cy + h / 2 + 14, '直方体（面が長方形）', _labelStyle);
  }

  void _cylinder(Canvas canvas, double cx, double cy) {
    const r = 38.0, h = 72.0, ey = 12.0;
    final bodyPaint = Paint()..color = _fillColor..style = PaintingStyle.fill;
    // 本体
    final body = Path()
      ..moveTo(cx - r, cy - h / 2 + ey)
      ..lineTo(cx - r, cy + h / 2)
      ..arcToPoint(Offset(cx + r, cy + h / 2), radius: Radius.elliptical(r, ey), clockwise: true)
      ..lineTo(cx + r, cy - h / 2 + ey);
    canvas.drawPath(body, bodyPaint);
    canvas.drawPath(body, _stroke);
    // 上面（楕円）
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - h / 2 + ey), width: r * 2, height: ey * 2), bodyPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - h / 2 + ey), width: r * 2, height: ey * 2), _stroke);
    // 下面（半弧）
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, cy + h / 2), width: r * 2, height: ey * 2), 0, math.pi, false, _stroke);
    _drawLabel(canvas, cx, cy + h / 2 + 14, '円柱（上下が円）', _labelStyle);
  }

  void _sphere(Canvas canvas, double cx, double cy) {
    canvas.drawCircle(Offset(cx, cy), 50, Paint()..color = _fillColor..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx, cy), 50, _stroke);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 100, height: 28),
        Paint()..color = _blue.withAlpha(90)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _drawLabel(canvas, cx, cy + 65, '球（どこから見ても円）', _labelStyle);
  }

  // ─── 角度 ─────────────────────────────────────────────────────────

  void _angleRight(Canvas canvas, double cx, double cy) {
    const len = 72.0, mark = 14.0;
    final ox = cx - 20, oy = cy + 20;
    canvas.drawLine(Offset(ox, oy), Offset(ox + len, oy), _stroke);
    canvas.drawLine(Offset(ox, oy), Offset(ox, oy - len), _stroke);
    final mp = Paint()..color = _red..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(ox + mark, oy)
        ..lineTo(ox + mark, oy - mark)
        ..lineTo(ox, oy - mark),
      mp,
    );
    _drawLabel(canvas, ox + len / 2 + 10, oy + 20, '直角 = 90°（正方形の角）', _labelStyle);
  }

  void _angle(Canvas canvas, double cx, double cy, double deg, String lbl) {
    const len = 70.0;
    final rad = deg * math.pi / 180;
    final ox = cx - 25, oy = cy + 20;
    canvas.drawLine(Offset(ox, oy), Offset(ox + len, oy), _stroke);
    canvas.drawLine(Offset(ox, oy),
        Offset(ox + len * math.cos(-rad), oy + len * math.sin(-rad)), _stroke);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(ox, oy), width: 36, height: 36),
      -rad, rad, false, _stroke..style = PaintingStyle.stroke..strokeWidth = 2,
    );
    _drawLabel(canvas, ox + 30, oy + 24, lbl, _labelStyle);
  }

  // ─── 面積 ─────────────────────────────────────────────────────────

  void _areaRectangle(Canvas canvas, double cx, double cy) {
    const w = 110.0, h = 64.0;
    final r = Rect.fromCenter(center: Offset(cx, cy - 4), width: w, height: h);
    canvas.drawRect(r, Paint()..color = _fillColor..style = PaintingStyle.fill);
    canvas.drawRect(r, _stroke);
    _drawLabel(canvas, cx, r.top - 10, 'よこ',
        TextStyle(color: _red, fontSize: 10, fontWeight: FontWeight.bold));
    _drawLabel(canvas, r.left - 18, cy - 4, 'たて',
        TextStyle(color: Color(0xFF0044CC), fontSize: 10, fontWeight: FontWeight.bold));
    _drawLabel(canvas, cx, r.bottom + 14, '面積 = たて × よこ', _labelStyle);
  }

  void _areaTriangle(Canvas canvas, double cx, double cy) {
    final top = Offset(cx, cy - 50);
    final bl = Offset(cx - 58, cy + 42);
    final br = Offset(cx + 58, cy + 42);
    _drawPath(canvas, [top, bl, br]);
    final dp = Paint()..color = _red..strokeWidth = 1.8..style = PaintingStyle.stroke;
    _dashedLine(canvas, cx, cy - 50, cx, cy + 42, dp);
    _drawLabel(canvas, cx + 8, cy - 12, '高さ',
        TextStyle(color: _red, fontSize: 10, fontWeight: FontWeight.bold));
    _drawLabel(canvas, cx, cy + 55, '面積 = 底辺 × 高さ ÷ 2', _labelStyle);
  }

  void _areaParallelogram(Canvas canvas, double cx, double cy) {
    const shift = 22.0, w = 96.0, h = 56.0;
    _drawPath(canvas, [
      Offset(cx - w / 2 + shift, cy - h / 2),
      Offset(cx + w / 2 + shift, cy - h / 2),
      Offset(cx + w / 2 - shift, cy + h / 2),
      Offset(cx - w / 2 - shift, cy + h / 2),
    ]);
    final dp = Paint()..color = _red..strokeWidth = 1.8..style = PaintingStyle.stroke;
    _dashedLine(canvas, cx + w / 2 + shift, cy - h / 2, cx + w / 2 + shift, cy + h / 2, dp);
    _drawLabel(canvas, cx + w / 2 + shift + 14, cy, '高さ',
        TextStyle(color: _red, fontSize: 10, fontWeight: FontWeight.bold));
    _drawLabel(canvas, cx, cy + h / 2 + 14, '面積 = 底辺 × 高さ', _labelStyle);
  }

  void _areaCircle(Canvas canvas, double cx, double cy) {
    const r = 46.0;
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = _fillColor..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx, cy), r, _stroke);
    final rp = Paint()..color = _red..strokeWidth = 2.5..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, cy), Offset(cx + r, cy), rp);
    canvas.drawCircle(Offset(cx, cy), 3, Paint()..color = _blue..style = PaintingStyle.fill);
    _drawLabel(canvas, cx + r / 2, cy - 10, 'r（半径）',
        TextStyle(color: _red, fontSize: 10, fontWeight: FontWeight.bold));
    _drawLabel(canvas, cx, cy + r + 14, '面積 = r × r × π（3.14）', _labelStyle);
  }

  // ─── ヘルパー ──────────────────────────────────────────────────────

  void _drawPath(Canvas canvas, List<Offset> pts) {
    final path = Path();
    for (int i = 0; i < pts.length; i++) {
      if (i == 0) path.moveTo(pts[i].dx, pts[i].dy);
      else path.lineTo(pts[i].dx, pts[i].dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = _fillColor..style = PaintingStyle.fill);
    canvas.drawPath(path, _stroke);
  }

  void _fillPath(Canvas canvas, Paint paint, List<Offset> pts) {
    final path = Path();
    for (int i = 0; i < pts.length; i++) {
      if (i == 0) path.moveTo(pts[i].dx, pts[i].dy);
      else path.lineTo(pts[i].dx, pts[i].dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _cornerMark(Canvas canvas, double x, double y, bool bottomLeft) {
    const s = 12.0;
    final mp = Paint()..color = _red..strokeWidth = 1.8..style = PaintingStyle.stroke;
    if (bottomLeft) {
      canvas.drawPath(
        Path()..moveTo(x + s, y)..lineTo(x + s, y - s)..lineTo(x, y - s), mp);
    } else {
      canvas.drawRect(Rect.fromLTWH(x, y, s, s), mp);
    }
  }

  void _tickMark(Canvas canvas, Offset a, Offset b) {
    final mx = (a.dx + b.dx) / 2, my = (a.dy + b.dy) / 2;
    final dx = b.dx - a.dx, dy = b.dy - a.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    final nx = -dy / len * 7, ny = dx / len * 7;
    canvas.drawLine(Offset(mx + nx, my + ny), Offset(mx - nx, my - ny), _stroke..strokeWidth = 2);
  }

  void _tickMark2(Canvas canvas, Offset a, Offset b) {
    final mx = (a.dx + b.dx) / 2, my = (a.dy + b.dy) / 2;
    final dx = b.dx - a.dx, dy = b.dy - a.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    final nx = -dy / len * 7, ny = dx / len * 7;
    final sp = Paint()..color = _blue..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(mx + nx - 3, my + ny - 3), Offset(mx - nx - 3, my - ny - 3), sp);
    canvas.drawLine(Offset(mx + nx + 3, my + ny + 3), Offset(mx - nx + 3, my - ny + 3), sp);
  }

  void _dashedLine(Canvas canvas, double x1, double y1, double x2, double y2, Paint p) {
    const dash = 5.0, gap = 3.5;
    final dx = x2 - x1, dy = y2 - y1;
    final total = math.sqrt(dx * dx + dy * dy);
    final nx = dx / total, ny = dy / total;
    double pos = 0;
    while (pos < total) {
      final end = math.min(pos + dash, total);
      canvas.drawLine(Offset(x1 + nx * pos, y1 + ny * pos), Offset(x1 + nx * end, y1 + ny * end), p);
      pos += dash + gap;
    }
  }

  void _drawLabel(Canvas canvas, double cx, double cy, String text, TextStyle style) {
    final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ShapePainter old) => old.shapeName != shapeName;
}
