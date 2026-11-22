import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/game/game_state.dart';
import 'package:sudoku/game/puzzles.dart';
import 'package:sudoku/main.dart';

int firstEmpty(GameState g) => g.values.indexWhere((v) => v == 0);

int wrongDigitFor(GameState g, int i) =>
    List.generate(9, (k) => k + 1).firstWhere((d) => d != g.solution[i]);

void main() {
  testWidgets('Uygulama açılır ve deneme listesi görünür', (tester) async {
    await tester.pumpWidget(const SudokuApp());
    expect(find.text('Deneme bulmacaları'), findsOneWidget);
  });

  test('Deneme bulmacaları çözümleriyle uyumlu', () {
    for (final p in testPuzzles) {
      expect(p.givens.length, 81);
      expect(p.solution.length, 81);
      for (var i = 0; i < 81; i++) {
        if (p.givens[i] != '0') expect(p.givens[i], p.solution[i]);
      }
    }
  });

  test('Doğru sayı yerleşir ve ilgili notlar silinir', () {
    final g = GameState(testPuzzles[0]);
    final i = firstEmpty(g);
    final d = g.solution[i];
    final peer = List.generate(81, (j) => j).firstWhere(
        (j) => j != i && GameState.sameUnit(i, j) && g.values[j] == 0);
    g.tapCell(peer);
    g.toggleNotesMode();
    g.pressNumber(d);
    expect(g.hasNote(peer, d), isTrue);
    g.toggleNotesMode();
    g.tapCell(i);
    g.pressNumber(d);
    expect(g.values[i], d);
    expect(g.hasNote(peer, d), isFalse);
    expect(g.mistakes, 0);
    g.dispose();
  });

  test('Üç hatada oyun biter, geri al hata sayısını düşürmez', () {
    final g = GameState(testPuzzles[0]);
    final i = firstEmpty(g);
    g.tapCell(i);
    g.pressNumber(wrongDigitFor(g, i));
    expect(g.mistakes, 1);
    expect(g.isWrong(i), isTrue);
    g.undo();
    expect(g.values[i], 0);
    expect(g.mistakes, 1);
    final wrongs = List.generate(9, (k) => k + 1)
        .where((d) => d != g.solution[i])
        .toList();
    g.pressNumber(wrongs[0]);
    g.pressNumber(wrongs[1]);
    expect(g.mistakes, 3);
    expect(g.status, GameStatus.lost);
    g.dispose();
  });

  test('Bütün hücreler doğru doldurulunca kazanılır', () {
    final g = GameState(testPuzzles[0]);
    for (var i = 0; i < 81; i++) {
      if (g.values[i] == 0) {
        g.tapCell(i);
        g.pressNumber(g.solution[i]);
      }
    }
    expect(g.status, GameStatus.won);
    g.dispose();
  });
}
