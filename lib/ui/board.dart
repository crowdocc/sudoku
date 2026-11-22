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

  /// Hücre dolgusu: seçili > aynı sayı > satır/sütun/kutu/kafes vurgusu > zemin.
  Color? _cellFill(int i, int? primary, Set<int> peers, int? sameNum) {
    if (game.selection.contains(i)) return colors.selected;
    if (sameNum != null && game.values[i] == sameNum) return colors.sameNumber;
    if (peers.contains(i)) return colors.peer;
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 9;
    final sel = game.selection;
    final numberFirst = game.isNumberFirst;
    final primary = !numberFirst && sel.length == 1 ? sel.first : null;
    final sameNum = game.highlightNumber;
    final killer = game.isKiller;

    // Vurgulanan hücreler: tek seçimde satır, sütun, kutu ve (killer) kafes.
    final peers = <int>{};
    if (primary != null) {
      for (var j = 0; j < 81; j++) {
        if (GameState.sameUnit(primary, j)) peers.add(j);
      }
      final cage = game.cageOf[primary];
      if (cage >= 0) peers.addAll(game.cages[cage].cells);
    }

    final frame = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(6));
    canvas.save();
    canvas.clipRRect(frame);

    // 1) Zemin
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.cell);

    // 2) Vurgu ve seçim dolguları, boyama
    final fill = Paint();
    for (var i = 0; i < 81; i++) {
      final rect = _cellRect(i, cell);
      final f = _cellFill(i, primary, peers, sameNum);
      if (f != null) {
        fill.color = f;
        canvas.drawRect(rect, fill);
      }
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
    }

    // Seçili hücrelerin ince açık mavi kenarı
    final selBorder = Paint()
      ..color = colors.selectedBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final i in sel) {
      canvas.drawRect(_cellRect(i, cell).deflate(1), selBorder);
    }

    // 3) Hücre çizgileri (~1 px, belli belirsiz); kutu sınırlarında çizilmez
    final thin = Paint()
      ..color = colors.cellLine
      ..strokeWidth = 1;
    for (var k = 1; k < 9; k++) {
      if (k % 3 == 0) continue;
      final p = k * cell;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), thin);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), thin);
    }

    // 4) 3x3 kutu çizgileri (~2 px, düz okra)
    final box = Paint()
      ..color = colors.boxLine
      ..strokeWidth = 2;
    for (var k = 3; k < 9; k += 3) {
      final p = k * cell;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), box);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), box);
    }
    canvas.restore();

    // Dış çerçeve: ince, köşeleri hafif yuvarlak, hücre çizgisi renginde
    canvas.drawRRect(
      frame.deflate(0.5),
      Paint()
        ..color = colors.cellLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // 5) Kafes çizgileri ve toplamlar
    if (killer) _paintCages(canvas, cell);

    // 6) Sayılar ve notlar
    final bigSize = cell * (killer ? 0.52 : 0.58);
    final noteSize = cell * (killer ? 0.19 : 0.24);
    for (var i = 0; i < 81; i++) {
      final rect = _cellRect(i, cell);
      final selected = sel.contains(i);
      final v = game.values[i];
      if (v != 0) {
        final TextPainter tp;
        if (game.isWrong(i)) {
          tp = _text('e$v', '$v', bigSize, colors.error, FontWeight.w400);
        } else if (game.given[i]) {
          tp = selected
              ? _text('G$v', '$v', bigSize, colors.selectedText, FontWeight.w600)
              : _text('g$v', '$v', bigSize, colors.givenText, FontWeight.w600);
        } else {
          tp = selected
              ? _text('U$v', '$v', bigSize, colors.selectedText, FontWeight.w400)
              : _text('u$v', '$v', bigSize, colors.userText, FontWeight.w400);
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
          final TextPainter tp;
          if (sameNum == d) {
            tp = _text('N$d', '$d', noteSize,
                selected ? colors.selectedText : colors.givenText,
                FontWeight.w700);
          } else if (selected) {
            tp = _text('m$d', '$d', noteSize, colors.selectedText,
                FontWeight.w500);
          } else {
            tp = _text('n$d', '$d', noteSize, colors.noteText, FontWeight.w500);
          }
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

  /// Kafes çizgileri: ince, kesikli, hücre kenarından ~4 px içeride, köşeleri
  /// yuvarlak. Toplamın olduğu köşede çizgi sayının etrafından dolaşır.
  void _paintCages(Canvas canvas, double cell) {
    final inset = math.min(4.0, cell * 0.11);
    final r = math.min(3.0, inset * 0.8);
    final dash = math.max(2.5, cell * 0.075);
    final space = math.max(2.0, cell * 0.055);
    final line = Paint()
      ..color = colors.cageLine
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final cageOf = game.cageOf;

    // Toplamlar ve kapladıkları alan
    final sumSize = cell * 0.2;
    final labelEnd = <int, Offset>{};
    for (final cage in game.cages) {
      final first = cage.cells.reduce(math.min);
      final rect = _cellRect(first, cell);
      final tp = _text('s${cage.sum}', '${cage.sum}', sumSize, colors.cageText,
          FontWeight.w600);
      final pos = Offset(rect.left + inset - 1, rect.top + 2);
      tp.paint(canvas, pos);
      labelEnd[first] =
          Offset(pos.dx + tp.width + 2.5, pos.dy + tp.height + 2.5);
    }

    bool same(int row, int col, int cage) =>
        row >= 0 &&
        row < 9 &&
        col >= 0 &&
        col < 9 &&
        cageOf[row * 9 + col] == cage;

    // Kenar ucu: dış köşede yuvarlak için içeride biter, komşunun da aynı
    // kenarı varsa hücre kenarına uzar, iç köşede karşı tarafa taşar.
    double extend(bool neighborSame, bool neighborHasEdge) {
      if (!neighborSame) return inset + r;
      if (neighborHasEdge) return 0;
      return -(inset - r);
    }

    void arc(Offset center, Offset from, Offset to) {
      final a1 = math.atan2(from.dy, from.dx);
      var sweep = math.atan2(to.dy, to.dx) - a1;
      while (sweep > math.pi) {
        sweep -= 2 * math.pi;
      }
      while (sweep < -math.pi) {
        sweep += 2 * math.pi;
      }
      canvas.drawArc(Rect.fromCircle(center: center, radius: r), a1, sweep,
          false, line);
    }

    for (var i = 0; i < 81; i++) {
      final cage = cageOf[i];
      if (cage < 0) continue;
      final row = i ~/ 9;
      final col = i % 9;
      final left = col * cell;
      final top = row * cell;
      final right = left + cell;
      final bottom = top + cell;
      final label = labelEnd[i];

      final upSame = same(row - 1, col, cage);
      final downSame = same(row + 1, col, cage);
      final leftSame = same(row, col - 1, cage);
      final rightSame = same(row, col + 1, cage);

      if (!upSame) {
        final y = top + inset;
        var x0 = left + extend(leftSame, !same(row - 1, col - 1, cage));
        if (label != null) x0 = math.max(x0, label.dx);
        final x1 = right - extend(rightSame, !same(row - 1, col + 1, cage));
        _dashed(canvas, Offset(x0, y), Offset(x1, y), dash, space, line);
      }
      if (!downSame) {
        final y = bottom - inset;
        final x0 = left + extend(leftSame, !same(row + 1, col - 1, cage));
        final x1 = right - extend(rightSame, !same(row + 1, col + 1, cage));
        _dashed(canvas, Offset(x0, y), Offset(x1, y), dash, space, line);
      }
      if (!leftSame) {
        final x = left + inset;
        var y0 = top + extend(upSame, !same(row - 1, col - 1, cage));
        if (label != null) y0 = math.max(y0, label.dy);
        final y1 = bottom - extend(downSame, !same(row + 1, col - 1, cage));
        _dashed(canvas, Offset(x, y0), Offset(x, y1), dash, space, line);
      }
      if (!rightSame) {
        final x = right - inset;
        final y0 = top + extend(upSame, !same(row - 1, col + 1, cage));
        final y1 = bottom - extend(downSame, !same(row + 1, col + 1, cage));
        _dashed(canvas, Offset(x, y0), Offset(x, y1), dash, space, line);
      }

      // Köşeler: sx/sy köşenin yönü (-1 sol/üst, +1 sağ/alt)
      for (final sx in const [-1, 1]) {
        for (final sy in const [-1, 1]) {
          final hSame = same(row, col + sx, cage);
          final vSame = same(row + sy, col, cage);
          final dSame = same(row + sy, col + sx, cage);
          final q = Offset(sx < 0 ? left + inset : right - inset,
              sy < 0 ? top + inset : bottom - inset);
          if (!hSame && !vSame) {
            // Dış köşe (toplamın olduğu köşe hariç)
            if (label != null && sx < 0 && sy < 0) continue;
            final center = q - Offset(sx * r, sy * r);
            arc(center, Offset(sx.toDouble(), 0), Offset(0, sy.toDouble()));
          } else if (hSame && vSame && !dSame) {
            // İç köşe
            final center = q + Offset(sx * r, sy * r);
            arc(center, Offset(-sx.toDouble(), 0), Offset(0, -sy.toDouble()));
          }
        }
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
