import 'dart:async';

import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/puzzles.dart';
import 'app_theme.dart';
import 'board.dart';
import 'bottom_panel.dart';
import 'end_screen.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final int puzzleIndex;

  const GameScreen({super.key, required this.mode, required this.puzzleIndex});

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
    game = GameState(puzzlesFor(widget.mode)[widget.puzzleIndex],
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
            mode: widget.mode,
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
                  Expanded(
                    // Izgara dışına (boş alana) dokununca seçim kalkar.
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: game.clearSelection,
                      child: Column(
                        children: [
                          _TopBar(game: game, colors: colors),
                          _InfoRow(game: game, colors: colors),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 4, 10, 8),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: _GridCard(game: game, colors: colors),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _ToolsRow(game: game, colors: colors),
                  const SizedBox(height: 4),
                  BottomPanel(game: game),
                  const SizedBox(height: 12),
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
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Geri',
            icon: Icon(Icons.arrow_back, color: colors.icon),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 48),
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
          IconButton(
            tooltip: game.paused ? 'Devam et' : 'Duraklat',
            icon: Icon(game.paused ? Icons.play_arrow : Icons.pause,
                color: colors.icon),
            onPressed:
                game.status == GameStatus.playing ? game.togglePause : null,
          ),
          IconButton(
            tooltip: 'Ayarlar',
            icon: Icon(Icons.settings_outlined, color: colors.icon),
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                  content: Text('Ayarlar sonraki adımda gelecek.'),
                  duration: Duration(seconds: 2),
                ));
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final GameState game;
  final GameColors colors;

  const _InfoRow({required this.game, required this.colors});

  @override
  Widget build(BuildContext context) {
    final modeName = game.isKiller ? 'Killer' : 'Klasik';
    final sum = game.selectionSum;
    const style = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: brandOkra,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            Expanded(
              child: Text('$modeName · #${game.puzzle.number}', style: style),
            ),
            if (sum != null) Text('Toplam: $sum', style: style),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: List.generate(GameState.maxMistakes, (k) {
                  final lost = k >= GameState.maxMistakes - game.mistakes;
                  return Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Icon(
                      lost ? Icons.favorite_border : Icons.favorite,
                      size: 18,
                      color: lost
                          ? colors.muted.withValues(alpha: 0.45)
                          : brandOkra,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yuvarlak köşeli, hafifçe yükselmiş ızgara kartı.
class _GridCard extends StatelessWidget {
  final GameState game;
  final GameColors colors;

  const _GridCard({required this.game, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: topDownShadow(colors.cardShadow, 16),
      ),
      padding: const EdgeInsets.all(7),
      child: game.paused
          ? _PausedView(game: game, colors: colors)
          : Board(game: game),
    );
  }
}

class _PausedView extends StatelessWidget {
  final GameState game;
  final GameColors colors;

  const _PausedView({required this.game, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
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
          onPressed: game.resume,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          child: const Text('Devam et'),
        ),
      ],
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
              icon: Icons.lightbulb_outline,
              label: 'İpucu',
              colors: colors,
              onTap: null,
            ),
          ),
          if (!game.isKiller)
            Expanded(
              child: _ToolButton(
                icon: Icons.edit_outlined,
                label: game.notesMode ? 'Not: Açık' : 'Not: Kapalı',
                active: game.notesMode,
                colors: colors,
                onTap: game.isPlaying ? game.toggleNotesMode : null,
              ),
            ),
          Expanded(
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
        ? colors.keyActiveText
        : (enabled ? colors.icon : colors.muted.withValues(alpha: 0.5));
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? colors.keyActive : Colors.transparent,
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: enabled ? colors.icon : colors.muted.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
