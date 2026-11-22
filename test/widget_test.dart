import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/game/game_state.dart';
import 'package:sudoku/game/puzzles.dart';
import 'package:sudoku/game/sum_solver.dart';
import 'package:sudoku/main.dart';

int firstEmpty(GameState g) => g.values.indexWhere((v) => v == 0);

void main() {
  testWidgets('Uygulama mod seçimiyle açılır', (tester) async {
    await tester.pumpWidget(const SudokuApp());
    expect(find.text('Klasik'), findsOneWidget);
    expect(find.text('Killer'), findsOneWidget);
  });

  test('Bulmacalar çözümleri ve kafesleriyle uyumlu', () {
    for (final p in [...classicPuzzles, ...killerPuzzles]) {
      expect(p.givens.length, 81);
      expect(p.solution.length, 81);
      for (var i = 0; i < 81; i++) {
        if (p.givens[i] != '0') expect(p.givens[i], p.solution[i]);
      }
      if (p.mode == GameMode.killer) {
        final covered = <int>[];
        for (final c in p.cages) {
          covered.addAll(c.cells);
          final total =
              c.cells.map((i) => int.parse(p.solution[i])).reduce((a, b) => a + b);
          expect(total, c.sum);
        }
        covered.sort();
        expect(covered, List<int>.generate(81, (i) => i));
      }
    }
  });

  test('Doğru sayı yerleşir ve ilgili notlar silinir', () {
    final g = GameState(classicPuzzles[0]);
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
    g.dispose();
  });

  test('Seçili hücreye tekrar dokununca ya da dışarı dokununca seçim kalkar', () {
    final g = GameState(classicPuzzles[0]);
    g.tapCell(10);
    expect(g.selection, {10});
    g.tapCell(10);
    expect(g.selection, isEmpty);
    g.tapCell(11);
    g.clearSelection();
    expect(g.selection, isEmpty);
    g.dispose();
  });

  test('Üç hatada oyun biter', () {
    final g = GameState(classicPuzzles[0]);
    final i = firstEmpty(g);
    g.tapCell(i);
    final wrongs = List.generate(9, (k) => k + 1)
        .where((d) => d != g.solution[i])
        .toList();
    g.pressNumber(wrongs[0]);
    g.undo();
    expect(g.mistakes, 1);
    g.pressNumber(wrongs[1]);
    g.pressNumber(wrongs[2]);
    expect(g.mistakes, 3);
    expect(g.status, GameStatus.lost);
    g.dispose();
  });

  test('Boyama: ekle, kaldır, birden fazla renk', () {
    final g = GameState(classicPuzzles[0]);
    g.dragStart(0);
    g.dragTo(1);
    g.toggleColor(2);
    expect(g.hasColor(0, 2) && g.hasColor(1, 2), isTrue);
    g.toggleColor(4);
    expect(g.hasColor(0, 4), isTrue);
    g.toggleColor(2);
    expect(g.hasColor(0, 2), isFalse);
    g.clearColors();
    expect(g.colors[0], 0);
    g.dispose();
  });

  test('Killer: aday takımı not girer, rakam takımı sayı girer', () {
    final g = GameState(killerPuzzles[0]);
    g.tapCell(0);
    g.pressNumber(5, asCandidate: true);
    expect(g.hasNote(0, 5), isTrue);
    g.pressNumber(g.solution[0]);
    expect(g.values[0], g.solution[0]);
    g.dispose();
  });

  test('Toplam gösterimi dokümandaki kurallara uyar', () {
    final p = killerPuzzles[0];
    final cages = p.cages;
    final known = List<int?>.filled(81, null);
    final a = cages[0];
    final b = cages[1];
    final both = {...a.cells, ...b.cells};
    expect(knownSelectionSum(selection: both, knownValues: known, cages: cages),
        a.sum + b.sum);
    final extra = List.generate(81, (i) => i).firstWhere((i) =>
        !both.contains(i) && cages.firstWhere((c) => c.cells.contains(i)).cells.length > 1);
    expect(
        knownSelectionSum(
            selection: {...both, extra}, knownValues: known, cages: cages),
        isNull);
    final sol = p.solution.split('').map(int.parse).toList();
    final known2 = List<int?>.of(known)..[extra] = sol[extra];
    expect(
        knownSelectionSum(
            selection: {...both, extra}, knownValues: known2, cages: cages),
        a.sum + b.sum + sol[extra]);
    expect(
        knownSelectionSum(
            selection: Set<int>.of(List.generate(9, (k) => k * 9 + 4)),
            knownValues: known,
            cages: cages),
        45);
  });

  test('Bütün hücreler doğru doldurulunca kazanılır', () {
    final g = GameState(killerPuzzles[1]);
    for (var i = 0; i < 81; i++) {
      if (g.values[i] == 0) {
        g.tapCell(i);
        g.pressNumber(g.solution[i]);
        g.clearSelection();
      }
    }
    expect(g.status, GameStatus.won);
    g.dispose();
  });

  test('Silgi sayıyı, notları ve renkleri siler; verilen sayıyı silmez', () {
    final g = GameState(classicPuzzles[0]);
    final e = firstEmpty(g);
    final givenCell = g.given.indexWhere((x) => x);
    g.tapCell(e);
    g.toggleNotesMode();
    g.pressNumber(3);
    g.toggleNotesMode();
    g.toggleColor(1);
    g.pressNumber(g.solution[e]);
    g.erase();
    expect(g.values[e], 0);
    expect(g.notes[e], 0);
    expect(g.colors[e], 0);
    g.tapCell(givenCell);
    g.toggleColor(0);
    g.erase();
    expect(g.values[givenCell], g.solution[givenCell]);
    expect(g.colors[givenCell], 0);
    g.dispose();
  });

  test('Önce sayı: hücre seçmez, yerleştirir, tekrar dokununca siler', () {
    final g = GameState(classicPuzzles[0]);
    g.toggleInputMode();
    final e = firstEmpty(g);
    final d = g.solution[e];
    g.pressNumber(d);
    g.tapCell(e);
    expect(g.selection, isEmpty);
    expect(g.values[e], d);
    g.tapCell(e);
    expect(g.values[e], 0);
    expect(g.mistakes, 0);
    g.dispose();
  });

  test('Önce sayı (killer adaylar): dokunma not açar/kapar, kaydırma not ekler', () {
    final g = GameState(killerPuzzles[0]);
    g.toggleInputMode();
    g.pressNumber(4, asCandidate: true);
    g.tapCell(0);
    expect(g.hasNote(0, 4), isTrue);
    g.tapCell(0);
    expect(g.hasNote(0, 4), isFalse);
    g.dragStart(10);
    g.dragTo(11);
    g.dragTo(12);
    expect([10, 11, 12].every((i) => g.hasNote(i, 4)), isTrue);
    expect(g.selection, isEmpty);
    g.pressNumber(4);
    g.dragStart(20);
    g.dragTo(21);
    expect(g.values[20], 0);
    expect(g.values[21], 0);
    g.dispose();
  });

  test('Kafes kombinasyonları ve eleme', () {
    final g = GameState(killerPuzzles[0]);
    final k = g.cages.indexWhere((c) => c.cells.length == 2 && c.sum == 13) ;
    if (k >= 0) {
      expect(g.combosForCage(k), ['49', '58', '67']);
    }
    g.tapCell(g.cages[0].cells.first);
    final cage = g.selectedCage!;
    final combos = g.combosForCage(cage);
    expect(combos, isNotEmpty);
    g.toggleCombo(cage, combos.first);
    expect(g.isComboEliminated(cage, combos.first), isTrue);
    g.toggleCombo(cage, combos.first);
    expect(g.isComboEliminated(cage, combos.first), isFalse);
    g.dispose();
  });
}
