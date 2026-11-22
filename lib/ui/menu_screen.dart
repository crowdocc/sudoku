import 'package:flutter/material.dart';

import '../game/puzzles.dart';
import 'app_theme.dart';
import 'game_screen.dart';

/// Geçici ana menü: sadece deneme bulmacalarını listeler.
/// Asıl mod/zorluk/bulmaca listesi ekranları sonraki adımda gelecek.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sudoku',
          style: TextStyle(color: brandOkra, fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Deneme bulmacaları',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Geçici ekran. Menüler sonraki adımda gelecek.',
                style: TextStyle(color: muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < testPuzzles.length; i++)
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: ListTile(
                    title: Text('Bulmaca #${testPuzzles[i].number}'),
                    subtitle: Text(
                      '${testPuzzles[i].givens.split('').where((c) => c != '0').length} verilen sayı',
                    ),
                    trailing: const Icon(Icons.chevron_right, color: brandOkra),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => GameScreen(puzzleIndex: i),
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
