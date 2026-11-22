import 'package:flutter/material.dart';

import '../game/puzzles.dart';
import 'app_theme.dart';
import 'game_screen.dart';

/// Ana giriş ekranı: mod seçimi.
class ModeScreen extends StatelessWidget {
  const ModeScreen({super.key});

  void _open(BuildContext context, GameMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PuzzleListScreen(mode: mode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    Widget modeButton(String label, String sub, GameMode mode) {
      return Container(
        height: 84,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: topDownShadow(colors.cardShadow, 14),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _open(context, mode),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: brandOkra,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(sub,
                            style: TextStyle(fontSize: 13, color: colors.muted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: brandOkra, size: 28),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sudoku',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: brandOkra,
                    ),
                  ),
                  const SizedBox(height: 48),
                  modeButton('Klasik', 'Klasik sudoku', GameMode.classic),
                  const SizedBox(height: 18),
                  modeButton('Killer', 'Kafesli sudoku', GameMode.killer),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Geçici bulmaca listesi (zorluk ve gerçek liste sonraki adımlarda).
class PuzzleListScreen extends StatelessWidget {
  final GameMode mode;

  const PuzzleListScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    final puzzles = puzzlesFor(mode);
    final title = mode == GameMode.classic ? 'Klasik' : 'Killer';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(color: brandOkra, fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Deneme bulmacaları (geçici liste)',
                style: TextStyle(color: colors.muted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < puzzles.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: topDownShadow(colors.cardShadow, 10),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    title: Text('Bulmaca #${puzzles[i].number}'),
                    trailing:
                        const Icon(Icons.chevron_right, color: brandOkra),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => GameScreen(mode: mode, puzzleIndex: i),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
