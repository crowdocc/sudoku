import 'dart:async';

import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/puzzles.dart';
import 'app_theme.dart';
import 'board.dart';
import 'end_screen.dart';

class GameScreen extends StatefulWidget {
  final int puzzleIndex;

  const GameScreen({super.key, required this.puzzleIndex});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  /// Ayarlar ekranı gelene kadar giriş modu oturum boyunca hatırlanır.
  static InputMode _lastInputMode = InputMode.cellFirst;

  late final GameState game;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    game = GameState(testPuzzles[widget.puzzleIndex],
        inputMode: _lastInputMode);
    game.addListener(_onGameChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      game.pause();
    }
  }

  void _onGameChanged() {
    _lastInputMode = game.inputMode;
    if (_ended || game.status == GameStatus.playing) return;
    _ended = true;
    final won = game.status == GameStatus.won;
    final time = game.timeText;
    final mistakes = game.mistakes;
    Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => EndScreen(
            won: won,
            puzzleIndex: widget.puzzleIndex,
            timeText: time,
            mistakes: mistakes,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    game.removeListener(_onGameChanged);
    game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListenableBuilder(
              listenable: game,
              builder: (context, _) => Column(
                children: [
                  _TopBar(game: game, colors: colors),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: game.paused
                              ? _PausedView(game: game, colors: colors)
                              : Board(game: game),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ToolsRow(game: game, colors: colors),
                  const SizedBox(height: 8),
                  _NumberPad(game: game, colors: colors),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final GameState game;
  final GameColors colors;

  const _TopBar({required this.game, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Geri',
            icon: Icon(Icons.arrow_back, color: colors.icon),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          Row(
            children: List.generate(GameState.maxMistakes, (k) {
              final used = k < game.mistakes;
              return Container(
                width: 11,
                height: 11,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: used ? colors.error : Colors.transparent,
                  border: Border.all(
                    color: used ? colors.error : colors.muted,
                    width: 1.5,
                  ),
                ),
              );
            }),
          ),
          Expanded(
            child: Center(
              child: Text(
                game.timeText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.icon,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(width: 52),
          IconButton(
            tooltip: game.paused ? 'Devam et' : 'Duraklat',
            icon: Icon(game.paused ? Icons.play_arrow : Icons.pause,
                color: colors.icon),
            onPressed: game.status == GameStatus.playing
                ? game.togglePause
                : null,
          ),
        ],
      ),
    );
  }
}

class _PausedView extends StatelessWidget {
  final GameState game;
  final GameColors colors;

  const _PausedView({required this.game, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.peer,
        border: Border.all(color: colors.thickLine, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pause_circle_outline, size: 56, color: colors.muted),
          const SizedBox(height: 12),
          Text(
            'Duraklatıldı',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.givenText,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.padActive,
              foregroundColor: colors.padActiveText,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
            onPressed: game.resume,
            child: const Text('Devam et'),
          ),
        ],
      ),
    );
  }
}

class _ToolsRow extends StatelessWidget {
  final GameState game;
  final GameColors colors;

  const _ToolsRow({required this.game, required this.colors});

  @override
  Widget build(BuildContext context) {
    final numberFirst = game.inputMode == InputMode.numberFirst;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _ToolButton(
              icon: Icons.undo,
              label: 'Geri al',
              colors: colors,
              onTap: game.canUndo ? game.undo : null,
            ),
          ),
          Expanded(
            child: _ToolButton(
              icon: Icons.backspace_outlined,
              label: 'Silgi',
              colors: colors,
              onTap: game.isPlaying ? game.erase : null,
            ),
          ),
          Expanded(
            child: _ToolButton(
              icon: Icons.edit_outlined,
              label: game.notesMode ? 'Not: Açık' : 'Not: Kapalı',
              active: game.notesMode,
              colors: colors,
              onTap: game.isPlaying ? game.toggleNotesMode : null,
            ),
          ),
          SizedBox(
            width: 88,
            child: _ToolButton(
              icon: numberFirst ? Icons.dialpad : Icons.touch_app_outlined,
              label: numberFirst ? 'Önce sayı' : 'Önce hücre',
              colors: colors,
              onTap: game.isPlaying ? game.toggleInputMode : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final GameColors colors;
  final VoidCallback? onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.colors,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final iconColor = active
        ? colors.padActiveText
        : (enabled ? colors.icon : colors.muted.withValues(alpha: 0.5));
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? colors.padActive : Colors.transparent,
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: enabled ? colors.icon : colors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  final GameState game;
  final GameColors colors;

  const _NumberPad({required this.game, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: List.generate(9, (k) {
          final d = k + 1;
          final complete = game.isNumberComplete(d);
          final active = game.inputMode == InputMode.numberFirst &&
              game.activeNumber == d;
          final Color textColor;
          if (complete) {
            textColor = colors.muted.withValues(alpha: 0.35);
          } else if (active) {
            textColor = colors.padActiveText;
          } else {
            textColor = colors.givenText;
          }
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: active ? colors.padActive : colors.padButton,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: complete || !game.isPlaying
                      ? null
                      : () => game.pressNumber(d),
                  child: SizedBox(
                    height: 58,
                    child: Center(
                      child: Text(
                        '$d',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
