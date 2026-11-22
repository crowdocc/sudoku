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

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 9;
    final paint = Paint();

    // Zemin
    paint.color = colors.board;
    canvas.drawRect(Offset.zero & size, paint);

    // Vurgular
    final sel = game.selection;
    final primary = sel.length == 1 ? sel.first : null;
    final hlNum = game.highlightNumber;
    for (var i = 0; i < 81; i++) {
      Color? bg;
      if (sel.contains(i)) {
        bg = colors.selected;
      } else if (primary != null && GameState.sameUnit(primary, i)) {
        bg = colors.peer;
      } else if (hlNum != null && game.values[i] == hlNum) {
        bg = colors.peer;
      }
      if (bg != null) {
        paint.color = bg;
        canvas.drawRect(
          Rect.fromLTWH(GameState.colOf(i) * cell, GameState.rowOf(i) * cell,
              cell, cell),
          paint,
        );
      }
    }

    // Sayılar ve notlar
    final bigSize = cell * 0.58;
    final noteSize = cell * 0.24;
    for (var i = 0; i < 81; i++) {
      final left = GameState.colOf(i) * cell;
      final top = GameState.rowOf(i) * cell;
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
        tp.paint(
          canvas,
          Offset(left + (cell - tp.width) / 2, top + (cell - tp.height) / 2),
        );
      } else if (game.notes[i] != 0) {
        final sub = cell / 3;
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
            Offset(left + c * sub + (sub - tp.width) / 2,
                top + r * sub + (sub - tp.height) / 2),
          );
        }
      }
    }

    // Çizgiler: önce ince, sonra kalın
    final thin = Paint()
      ..color = colors.thinLine
      ..strokeWidth = 1;
    for (var k = 1; k < 9; k++) {
      if (k % 3 == 0) continue;
      final p = k * cell;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), thin);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), thin);
    }
    final thick = Paint()
      ..color = colors.thickLine
      ..strokeWidth = 2;
    for (var k = 3; k < 9; k += 3) {
      final p = k * cell;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), thick);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), thick);
    }
    final border = Paint()
      ..color = colors.thickLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect((Offset.zero & size).deflate(1), border);
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}
