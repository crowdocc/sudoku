import 'dart:async';
import 'dart:math' as math;

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
  final PageController _panelController = PageController();
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
    _panelController.dispose();
    super.dispose();
  }

  void _togglePanelPage() {
    _panelController.animateToPage(game.colorPage ? 0 : 1,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
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
                          _ContextRow(game: game, colors: colors),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: _GridArea(game: game, colors: colors),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _ToolsRow(
                    game: game,
                    colors: colors,
                    onTogglePage: _togglePanelPage,
                  ),
                  BottomPanel(game: game, controller: _panelController),
                  const SizedBox(height: 10),
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
    final iconColor = colors.icon;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Geri',
            iconSize: 22,
            icon: Icon(Icons.arrow_back, color: iconColor),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 48),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  game.timeText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: iconColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 12),
                for (var k = 0; k < GameState.maxMistakes; k++)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Icon(
                      k >= GameState.maxMistakes - game.mistakes
                          ? Icons.favorite_border
                          : Icons.favorite,
                      size: 13,
                      color: k >= GameState.maxMistakes - game.mistakes
                          ? colors.muted.withValues(alpha: 0.45)
                          : colors.error,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: game.paused ? 'Devam et' : 'Duraklat',
            iconSize: 22,
            icon: Icon(game.paused ? Icons.play_arrow : Icons.pause,
                color: iconColor),
            onPressed:
                game.status == GameStatus.playing ? game.togglePause : null,
          ),
          IconButton(
            tooltip: 'Ayarlar',
            iconSize: 22,
            icon: Icon(Icons.settings_outlined, color: iconColor),
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

/// Sabit yükseklikli ince bağlam satırı: killer kombinasyon çipleri ve toplam.
class _ContextRow extends StatelessWidget {
  final GameState game;
  final GameColors colors;

  const _ContextRow({required this.game, required this.colors});

  @override
  Widget build(BuildContext context) {
    final cage = game.selectedCage;
    final sum = game.selectionSum;
    return SizedBox(
      height: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: cage == null
                  ? const SizedBox.shrink()
                  : _ComboChips(game: game, colors: colors, cage: cage),
            ),
            if (sum != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  'Toplam: $sum',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.icon,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ComboChips extends StatelessWidget {
  final GameState game;
  final GameColors colors;
  final int cage;

  const _ComboChips(
      {required this.game, required this.colors, required this.cage});

  @override
  Widget build(BuildContext context) {
    final combos = game.combosForCage(cage);
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        Center(
          child: Text(
            '${game.cages[cage].sum} =',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.icon,
            ),
          ),
        ),
        for (final combo in combos)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Center(child: _chip(combo)),
          ),
      ],
    );
  }

  Widget _chip(String combo) {
    final off = game.isComboEliminated(cage, combo);
    return GestureDetector(
      onTap: () => game.toggleCombo(cage, combo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: off ? Colors.transparent : colors.key,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: colors.muted.withValues(alpha: off ? 0.25 : 0.4),
            width: 0.8,
          ),
        ),
        child: Text(
          combo,
          style: TextStyle(
            fontSize: 12,
            height: 1.1,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: off ? colors.muted.withValues(alpha: 0.5) : colors.icon,
            decoration: off ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}

/// Izgara: ayrı kart yok; bütününde çok hafif, her yöne eşit gölge.
class _GridArea extends StatelessWidget {
  final GameState game;
  final GameColors colors;

  const _GridArea({required this.game, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cell,
        boxShadow: topDownShadow(colors.gridShadow, 10),
      ),
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
  final VoidCallback onTogglePage;

  const _ToolsRow({
    required this.game,
    required this.colors,
    required this.onTogglePage,
  });

  @override
  Widget build(BuildContext context) {
    final numberFirst = game.inputMode == InputMode.numberFirst;
    final playing = game.isPlaying;
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            _Tool(
              tooltip: 'Geri al',
              colors: colors,
              onTap: game.canUndo ? game.undo : null,
              child: const Icon(Icons.undo),
            ),
            _Tool(
              tooltip: 'Silgi',
              colors: colors,
              onTap: playing ? game.erase : null,
              child: const _EraserIcon(),
            ),
            _Tool(
              tooltip: 'İpucu',
              colors: colors,
              onTap: null,
              child: const Icon(Icons.lightbulb_outline),
            ),
            if (!game.isKiller)
              _Tool(
                tooltip: 'Not modu',
                colors: colors,
                active: game.notesMode,
                onTap: playing ? game.toggleNotesMode : null,
                child: const Icon(Icons.edit_outlined),
              ),
            _Tool(
              tooltip: numberFirst ? 'Önce sayı' : 'Önce hücre',
              colors: colors,
              onTap: playing ? game.toggleInputMode : null,
              child: Icon(
                  numberFirst ? Icons.dialpad : Icons.touch_app_outlined),
            ),
            const Spacer(),
            _Tool(
              tooltip: game.colorPage ? 'Rakamlar' : 'Renkler',
              colors: colors,
              active: game.colorPage,
              onTap: onTogglePage,
              child: const Icon(Icons.palette_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

/// Küçük, soluk, etiketsiz araç ikonu. Etkinken okra renkte.
class _Tool extends StatelessWidget {
  final String tooltip;
  final GameColors colors;
  final VoidCallback? onTap;
  final bool active;
  final Widget child;

  const _Tool({
    required this.tooltip,
    required this.colors,
    required this.onTap,
    required this.child,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = active
        ? brandOkra
        : enabled
            ? colors.tool
            : colors.tool.withValues(alpha: 0.35);
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: SizedBox(
          width: 44,
          height: 40,
          child: Center(
            child: IconTheme(
              data: IconThemeData(size: 20, color: color),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Gerçek silgi şeklinde ikon: çapraz duran, iki parçalı silgi.
class _EraserIcon extends StatelessWidget {
  const _EraserIcon();

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? 20;
    return CustomPaint(
      size: Size.square(size),
      painter: _EraserPainter(theme.color ?? const Color(0xFF8C8C8C)),
    );
  }
}

class _EraserPainter extends CustomPainter {
  final Color color;

  _EraserPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.085
      ..strokeJoin = StrokeJoin.round;
    canvas.save();
    canvas.translate(s / 2, s * 0.46);
    canvas.rotate(-math.pi / 4);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: s * 0.82, height: s * 0.4),
      Radius.circular(s * 0.08),
    );
    canvas.drawRRect(body, stroke);
    // Silginin uç kısmı (dolu)
    final tip = Rect.fromLTRB(-s * 0.41, -s * 0.2, -s * 0.08, s * 0.2);
    canvas.drawRRect(
      RRect.fromRectAndCorners(tip,
          topLeft: Radius.circular(s * 0.08),
          bottomLeft: Radius.circular(s * 0.08)),
      Paint()..color = color,
    );
    canvas.restore();
    // Alt çizgi (silinen yüzey)
    canvas.drawLine(Offset(s * 0.42, s * 0.9), Offset(s * 0.92, s * 0.9),
        stroke..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _EraserPainter old) => old.color != color;
}
