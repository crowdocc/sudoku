import 'package:flutter/material.dart';

import '../game/game_state.dart';
import 'app_theme.dart';

/// Alt panel: "Rakamlar" ve "Renkler" sayfaları. Ayrı kart yok; tuşlar doğrudan
/// zeminin üstünde. Yukarı-aşağı kaydırılarak ya da araç satırındaki geçiş
/// ikonuyla sayfa değiştirilir.
class BottomPanel extends StatelessWidget {
  final GameState game;
  final PageController controller;

  const BottomPanel({super.key, required this.game, required this.controller});

  static double heightFor(GameState game) => game.isKiller ? 190 : 70;

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    return SizedBox(
      height: heightFor(game),
      child: PageView(
        controller: controller,
        scrollDirection: Axis.vertical,
        onPageChanged: (p) => game.setColorPage(p == 1),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: game.isKiller
                ? _KillerDigits(game: game, colors: colors)
                : _ClassicDigits(game: game, colors: colors),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: _ColorsPage(game: game, colors: colors),
          ),
        ],
      ),
    );
  }
}

/// Yumuşak derinlikli tuş (tepeden bakış: her yöne eşit gölge).
class _Key extends StatelessWidget {
  final GameColors colors;
  final VoidCallback? onTap;
  final bool active;
  final bool faded;
  final Widget child;
  final Color? fillColor;

  const _Key({
    required this.colors,
    required this.onTap,
    required this.child,
    this.active = false,
    this.faded = false,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = fillColor ?? (active ? colors.keyActive : colors.key);
    return Opacity(
      opacity: faded ? 0.35 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          boxShadow: faded ? null : topDownShadow(colors.keyShadow, 5),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Tuşa çok hafif gömülü görünen rakam.
TextStyle _engraved(GameColors colors, double size, Color color,
        {FontWeight weight = FontWeight.w500}) =>
    TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.0,
      shadows: [Shadow(color: colors.engrave, blurRadius: 1.5)],
    );

class _DigitKey extends StatelessWidget {
  final GameState game;
  final GameColors colors;
  final int digit;
  final double fontSize;

  const _DigitKey({
    required this.game,
    required this.colors,
    required this.digit,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final left = game.remaining(digit);
    final complete = left <= 0;
    final active = game.inputMode == InputMode.numberFirst &&
        game.activeNumber == digit &&
        !game.activeIsNote;
    final textColor = active ? colors.keyActiveText : colors.keyText;
    return _Key(
      colors: colors,
      active: active,
      faded: complete,
      onTap: complete || !game.isPlaying ? null : () => game.pressNumber(digit),
      child: Stack(
        children: [
          Center(child: Text('$digit', style: _engraved(colors, fontSize, textColor))),
          Positioned(
            top: 3,
            right: 5,
            child: Text(
              '$left',
              style: TextStyle(
                fontSize: 9,
                height: 1.0,
                color: active
                    ? colors.keyActiveText.withValues(alpha: 0.7)
                    : colors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateKey extends StatelessWidget {
  final GameState game;
  final GameColors colors;
  final int digit;

  const _CandidateKey({
    required this.game,
    required this.colors,
    required this.digit,
  });

  @override
  Widget build(BuildContext context) {
    final complete = game.remaining(digit) <= 0;
    final active = game.inputMode == InputMode.numberFirst &&
        game.activeNumber == digit &&
        game.activeIsNote;
    final r = (digit - 1) ~/ 3;
    final c = (digit - 1) % 3;
    final textColor = active ? colors.keyActiveText : colors.keyText;
    return _Key(
      colors: colors,
      active: active,
      faded: complete,
      onTap: complete || !game.isPlaying
          ? null
          : () => game.pressNumber(digit, asCandidate: true),
      child: Align(
        alignment: Alignment((c - 1) * 0.62, (r - 1) * 0.62),
        child: Text('$digit',
            style: _engraved(colors, 13, textColor, weight: FontWeight.w600)),
      ),
    );
  }
}

class _ClassicDigits extends StatelessWidget {
  final GameState game;
  final GameColors colors;

  const _ClassicDigits({required this.game, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var d = 1; d <= 9; d++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: _DigitKey(game: game, colors: colors, digit: d, fontSize: 25),
            ),
          ),
      ],
    );
  }
}

Widget _grid3x3(Widget Function(int digit) build) {
  return Column(
    children: [
      for (var r = 0; r < 3; r++)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                for (var c = 0; c < 3; c++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: build(r * 3 + c + 1),
                    ),
                  ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _KillerDigits extends StatelessWidget {
  final GameState game;
  final GameColors colors;

  const _KillerDigits({required this.game, required this.colors});

  @override
  Widget build(BuildContext context) {
    Widget labeled(String label, Widget child) => Expanded(
          child: Column(
            children: [
              Expanded(child: child),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 10, color: colors.muted)),
            ],
          ),
        );
    return Row(
      children: [
        labeled(
          'Rakamlar',
          _grid3x3((d) =>
              _DigitKey(game: game, colors: colors, digit: d, fontSize: 22)),
        ),
        const SizedBox(width: 14),
        labeled(
          'Adaylar',
          _grid3x3((d) => _CandidateKey(game: game, colors: colors, digit: d)),
        ),
      ],
    );
  }
}

class _ColorsPage extends StatelessWidget {
  final GameState game;
  final GameColors colors;

  const _ColorsPage({required this.game, required this.colors});

  @override
  Widget build(BuildContext context) {
    Widget colorKey(int k) {
      final has = game.selectionHasColor(k);
      return _Key(
        colors: colors,
        onTap: game.isPlaying ? () => game.toggleColor(k) : null,
        child: Center(
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: GameColors.palette[k],
              shape: BoxShape.circle,
            ),
            child: has
                ? const Icon(Icons.check, size: 15, color: Color(0xFF1E1E1E))
                : null,
          ),
        ),
      );
    }

    final clearKey = _Key(
      colors: colors,
      onTap: game.isPlaying ? game.clearColors : null,
      child: Center(
        child: Icon(Icons.format_color_reset_outlined,
            size: 20, color: colors.keyText),
      ),
    );

    Widget cellOf(Widget w) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 3),
            child: w,
          ),
        );

    if (!game.isKiller) {
      return Row(
        children: [
          for (var k = 0; k < GameState.paletteSize; k++) cellOf(colorKey(k)),
          cellOf(clearKey),
        ],
      );
    }
    return Column(
      children: [
        Expanded(
          child: Row(children: [for (var k = 0; k < 5; k++) cellOf(colorKey(k))]),
        ),
        Expanded(
          child: Row(children: [
            for (var k = 5; k < GameState.paletteSize; k++) cellOf(colorKey(k)),
            cellOf(clearKey),
          ]),
        ),
      ],
    );
  }
}
