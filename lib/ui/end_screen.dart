import 'package:flutter/material.dart';

import '../game/puzzles.dart';
import 'app_theme.dart';
import 'game_screen.dart';

class EndScreen extends StatelessWidget {
  final bool won;
  final GameMode mode;
  final int puzzleIndex;
  final String timeText;
  final int mistakes;

  const EndScreen({
    super.key,
    required this.won,
    required this.mode,
    required this.puzzleIndex,
    required this.timeText,
    required this.mistakes,
  });

  void _openGame(BuildContext context, int index) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => GameScreen(mode: mode, puzzleIndex: index)),
    );
  }

  void _toMenu(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final puzzles = puzzlesFor(mode);
    final next = (puzzleIndex + 1) % puzzles.length;
    final number = puzzles[puzzleIndex].number;

    final buttons = <Widget>[
      if (won) ...[
        FilledButton(
          onPressed: () => _openGame(context, next),
          child: const Text('Sonraki bulmaca'),
        ),
        OutlinedButton(
          onPressed: () => _toMenu(context),
          child: const Text('Ana menü'),
        ),
      ] else ...[
        FilledButton(
          onPressed: () => _openGame(context, puzzleIndex),
          child: const Text('Yeniden başla'),
        ),
        OutlinedButton(
          onPressed: () => _toMenu(context),
          child: const Text('Ana menüye dön'),
        ),
        OutlinedButton(
          onPressed: () => _openGame(context, next),
          child: const Text('Sonraki bulmaca'),
        ),
      ],
    ];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    won
                        ? Icons.emoji_events_outlined
                        : Icons.sentiment_dissatisfied_outlined,
                    size: 72,
                    color: brandOkra,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    won ? 'Tebrikler!' : 'Oyun bitti',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    won
                        ? 'Bulmaca #$number çözüldü'
                        : '3 hata yapıldı. Bulmaca #$number kaybedildi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted),
                  ),
                  if (won) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Süre: $timeText',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                    if (mistakes == 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: brandOkra, size: 20),
                          const SizedBox(width: 6),
                          Text('Hatasız', style: TextStyle(color: muted)),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(height: 32),
                  for (final b in buttons)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(height: 50, child: b),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
