import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/game_state.dart';
import 'app_theme.dart';

/// 9x9 ızgara: dokunarak tek hücre, parmağı gezdirerek çoklu seçim.
class Board extends StatelessWidget {
  final GameState game;

  const Board({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        int? indexAt(Offset p) {
          if (p.dx < 0 || p.dy < 0 || p.dx >= size || p.dy >= size) {
            return null;
          }
          final cell = size / 9;
          final r = (p.dy / cell).floor().clamp(0, 8).toInt();
          final c = (p.dx / cell).floor().clamp(0, 8).toInt();
          return r * 9 + c;
        }

        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              final i = indexAt(d.localPosition);
              if (i != null) game.tapCell(i);
            },
            onPanStart: (d) {
              final i = indexAt(d.localPosition);
              if (i != null) game.dragStart(i);
            },
            onPanUpdate: (d) {
              final i = indexAt(d.localPosition);
              if (i != null) game.dragTo(i);
            },
            child: CustomPaint(
              size: Size.square(size),
              painter: _BoardPainter(game: game, colors: colors),
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  final GameState game;
  final GameColors colors;
  final Map<String, TextPainter> _cache = <String, TextPainter>{};

  _BoardPainter({required this.game, required this.colors});

  TextPainter _text(String key, String text, double fontSize, Color color,
      FontWeight weight) {
    return _cache.putIfAbsent(key, () {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: fontSize,
            color: color,
            fontWeight: weight,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      return tp;
    });
  }

  Color _cellBackground(int i, int? primary, int? hlNum) {
    if (game.selection.contains(i)) return colors.selected;
    if (primary != null && GameState.sameUnit(primary, i)) return colors.peer;
    if (hlNum != null && game.values[i] == hlNum) return colors.peer;
    return colors.cell;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 9;
    final sel = game.selection;
    final primary = sel.length == 1 ? sel.first : null;
    final hlNum = game.highlightNumber;
    final killer = game.isKiller;
    final fill = Paint();

    // Hücre zeminleri, vurgular ve boyama (tek parça ızgara, hücre derinliği yok)
    for (var i = 0; i < 81; i++) {
      final rect = _cellRect(i, cell);
      fill.color = _cellBackground(i, primary, hlNum);
      canvas.drawRect(rect, fill);

      final mask = game.colors[i];
      if (mask == 0) continue;
      final list = <Color>[
        for (var k = 0; k < GameState.paletteSize; k++)
          if ((mask & (1 << k)) != 0)
            GameColors.palette[k].withValues(alpha: colors.paintAlpha),
      ];
      canvas.save();
      canvas.clipRect(rect);
      if (list.length == 1) {
        canvas.drawRect(rect, Paint()..color = list.first);
      } else {
        final sweep = 2 * math.pi / list.length;
        final arcRect = Rect.fromCircle(center: rect.center, radius: cell);
        for (var k = 0; k < list.length; k++) {
          canvas.drawArc(arcRect, -math.pi / 2 + k * sweep, sweep, true,
              Paint()..color = list[k]);
        }
      }
      canvas.restore();
      if (sel.contains(i)) {
        canvas.drawRect(
          rect.deflate(1.5),
          Paint()
            ..color = colors.selectedBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    // Hücre çizgileri: en ince ve en sönük; kutu sınırlarında çizilmez
    final thin = Paint()
      ..color = colors.cellLine
      ..strokeWidth = 0.8;
    for (var k = 1; k < 9; k++) {
      if (k % 3 == 0) continue;
      final p = k * cell;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), thin);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), thin);
    }

    // 3x3 kutu çizgileri: ince, soluk okra
    final box = Paint()
      ..color = colors.boxLine
      ..strokeWidth = 1;
    for (var k = 3; k < 9; k += 3) {
      final p = k * cell;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), box);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), box);
    }
    canvas.drawRect(
      (Offset.zero & size).deflate(0.5),
      Paint()
        ..color = colors.boxLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    if (killer) _paintCages(canvas, cell);

    // Sayılar ve notlar
    final bigSize = cell * (killer ? 0.52 : 0.58);
    final noteSize = cell * (killer ? 0.19 : 0.24);
    for (var i = 0; i < 81; i++) {
      final rect = _cellRect(i, cell);
      final v = game.values[i];
      if (v != 0) {
        final TextPainter tp;
        if (game.given[i]) {
          tp = _text('g$v', '$v', bigSize, colors.givenText, FontWeight.w600);
        } else if (game.isWrong(i)) {
          tp = _text('e$v', '$v', bigSize, colors.error, FontWeight.w400);
        } else {
          tp = _text('u$v', '$v', bigSize, colors.userText, FontWeight.w400);
        }
        final dy = killer ? cell * 0.04 : 0.0;
        tp.paint(
          canvas,
          Offset(rect.left + (cell - tp.width) / 2,
              rect.top + dy + (cell - tp.height) / 2),
        );
      } else if (game.notes[i] != 0) {
        final inset = killer ? cell * 0.17 : cell * 0.04;
        final area = rect.deflate(inset);
        final sub = area.width / 3;
        for (var d = 1; d <= 9; d++) {
          if (!game.hasNote(i, d)) continue;
          final strong = hlNum == d;
          final tp = strong
              ? _text('N$d', '$d', noteSize, colors.givenText, FontWeight.w700)
              : _text('n$d', '$d', noteSize, colors.noteText, FontWeight.w500);
          final r = (d - 1) ~/ 3;
          final c = (d - 1) % 3;
          tp.paint(
            canvas,
            Offset(area.left + c * sub + (sub - tp.width) / 2,
                area.top + r * sub + (sub - tp.height) / 2),
          );
        }
      }
    }
  }

  Rect _cellRect(int i, double cell) => Rect.fromLTWH(
      GameState.colOf(i) * cell, GameState.rowOf(i) * cell, cell, cell);

  void _paintCages(Canvas canvas, double cell) {
    final inset = cell * 0.13;
    final dash = math.max(2.5, cell * 0.08);
    final space = math.max(1.8, cell * 0.055);
    final line = Paint()
      ..color = colors.cageLine
      ..strokeWidth = 1.2;
    final cageOf = game.cageOf;

    // Kafes toplamları ve kapladıkları alan (kesik çizgi bu alanın dışında başlar)
    final sumSize = cell * 0.2;
    final labelEnd = <int, Offset>{};
    for (final cage in game.cages) {
      final first = cage.cells.reduce(math.min);
      final rect = _cellRect(first, cell);
      final tp = _text('s${cage.sum}', '${cage.sum}', sumSize, colors.cageText,
          FontWeight.w600);
      final pos = Offset(rect.left + cell * 0.05, rect.top + cell * 0.04);
      tp.paint(canvas, pos);
      labelEnd[first] = Offset(pos.dx + tp.width + cell * 0.04,
          pos.dy + tp.height + cell * 0.03);
    }

    bool same(int r, int c, int cage) =>
        r >= 0 && r < 9 && c >= 0 && c < 9 && cageOf[r * 9 + c] == cage;

    // Kenar ucu: komşu farklı kafesteyse içeride biter, komşunun da aynı kenarı
    // varsa hücre kenarına uzar, yoksa (iç köşe) karşı tarafa taşar.
    double extend(bool neighborSame, bool neighborHasEdge) {
      if (!neighborSame) return inset;
      if (neighborHasEdge) return 0;
      return -inset;
    }

    for (var i = 0; i < 81; i++) {
      final cage = cageOf[i];
      if (cage < 0) continue;
      final r = i ~/ 9;
      final c = i % 9;
      final left = c * cell;
      final top = r * cell;
      final right = left + cell;
      final bottom = top + cell;
      final label = labelEnd[i];

      final upSame = same(r - 1, c, cage);
      final downSame = same(r + 1, c, cage);
      final leftSame = same(r, c - 1, cage);
      final rightSame = same(r, c + 1, cage);

      if (!upSame) {
        final y = top + inset;
        var x0 = left + extend(leftSame, !same(r - 1, c - 1, cage));
        if (label != null) x0 = math.max(x0, label.dx);
        final x1 = right - extend(rightSame, !same(r - 1, c + 1, cage));
        _dashed(canvas, Offset(x0, y), Offset(x1, y), dash, space, line);
      }
      if (!downSame) {
        final y = bottom - inset;
        final x0 = left + extend(leftSame, !same(r + 1, c - 1, cage));
        final x1 = right - extend(rightSame, !same(r + 1, c + 1, cage));
        _dashed(canvas, Offset(x0, y), Offset(x1, y), dash, space, line);
      }
      if (!leftSame) {
        final x = left + inset;
        var y0 = top + extend(upSame, !same(r - 1, c - 1, cage));
        if (label != null) y0 = math.max(y0, label.dy);
        final y1 = bottom - extend(downSame, !same(r + 1, c - 1, cage));
        _dashed(canvas, Offset(x, y0), Offset(x, y1), dash, space, line);
      }
      if (!rightSame) {
        final x = right - inset;
        final y0 = top + extend(upSame, !same(r - 1, c + 1, cage));
        final y1 = bottom - extend(downSame, !same(r + 1, c + 1, cage));
        _dashed(canvas, Offset(x, y0), Offset(x, y1), dash, space, line);
      }
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, double dash, double space,
      Paint paint) {
    final total = (b - a).distance;
    if (total <= 0) return;
    final dir = (b - a) / total;
    var pos = 0.0;
    while (pos < total) {
      final end = math.min(pos + dash, total);
      canvas.drawLine(a + dir * pos, a + dir * end, paint);
      pos = end + space;
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}
