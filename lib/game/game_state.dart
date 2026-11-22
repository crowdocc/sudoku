import 'dart:async';

import 'package:flutter/foundation.dart';

import 'puzzles.dart';

enum InputMode { cellFirst, numberFirst }

enum GameStatus { playing, won, lost }

class _Snapshot {
  final List<int> values;
  final List<int> notes;

  const _Snapshot(this.values, this.notes);
}

/// Klasik sudoku oyununun tüm durumu ve kuralları.
class GameState extends ChangeNotifier {
  static const int maxMistakes = 3;

  final Puzzle puzzle;
  final List<int> solution;
  final List<bool> given;
  final List<int> values;

  /// Her hücre için not bit maskesi: (1 << d) biti d notunun varlığını gösterir.
  final List<int> notes;

  final Set<int> selection = <int>{};
  InputMode inputMode;
  bool notesMode = false;
  int? activeNumber;
  int mistakes = 0;
  GameStatus status = GameStatus.playing;
  bool paused = false;
  int elapsedSeconds = 0;

  Timer? _timer;
  final List<_Snapshot> _undoStack = <_Snapshot>[];

  GameState(this.puzzle, {this.inputMode = InputMode.cellFirst})
      : solution = _digits(puzzle.solution),
        values = _digits(puzzle.givens),
        given = _digits(puzzle.givens).map((d) => d != 0).toList(),
        notes = List<int>.filled(81, 0) {
    _startTimer();
  }

  static List<int> _digits(String s) =>
      s.split('').map((c) => int.parse(c)).toList();

  // ---------- Yardımcılar ----------

  static int rowOf(int i) => i ~/ 9;
  static int colOf(int i) => i % 9;
  static int boxOf(int i) => (i ~/ 27) * 3 + (i % 9) ~/ 3;

  static bool sameUnit(int a, int b) =>
      rowOf(a) == rowOf(b) || colOf(a) == colOf(b) || boxOf(a) == boxOf(b);

  bool get isPlaying => status == GameStatus.playing && !paused;

  bool get canUndo => _undoStack.isNotEmpty && isPlaying;

  bool isWrong(int i) => values[i] != 0 && values[i] != solution[i];

  /// Verilen ya da doğru girilmiş hücreler değiştirilemez.
  bool isLocked(int i) =>
      given[i] || (values[i] != 0 && values[i] == solution[i]);

  bool hasNote(int i, int d) => (notes[i] & (1 << d)) != 0;

  /// Bir sayı ızgarada 9 kez doğru yerleştirildiyse tamamlanmıştır.
  bool isNumberComplete(int d) {
    var count = 0;
    for (var i = 0; i < 81; i++) {
      if (values[i] == d && solution[i] == d) count++;
    }
    return count >= 9;
  }

  /// Vurgulanacak sayı: önce-sayı modunda seçili sayı, yoksa seçili hücredeki sayı.
  int? get highlightNumber {
    if (inputMode == InputMode.numberFirst && activeNumber != null) {
      return activeNumber;
    }
    if (selection.length == 1) {
      final v = values[selection.first];
      if (v != 0) return v;
    }
    return null;
  }

  String get timeText {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  // ---------- Süre ----------

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds++;
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void pause() {
    if (status != GameStatus.playing || paused) return;
    paused = true;
    _stopTimer();
    notifyListeners();
  }

  void resume() {
    if (status != GameStatus.playing || !paused) return;
    paused = false;
    _startTimer();
    notifyListeners();
  }

  void togglePause() {
    if (paused) {
      resume();
    } else {
      pause();
    }
  }

  // ---------- Seçim ----------

  void tapCell(int i) {
    if (!isPlaying) return;
    selection
      ..clear()
      ..add(i);
    if (inputMode == InputMode.numberFirst && activeNumber != null) {
      _apply(activeNumber!, <int>{i});
    }
    notifyListeners();
  }

  bool get _dragEnabled =>
      !(inputMode == InputMode.numberFirst && activeNumber != null);

  void dragStart(int i) {
    if (!isPlaying || !_dragEnabled) return;
    selection
      ..clear()
      ..add(i);
    notifyListeners();
  }

  void dragTo(int i) {
    if (!isPlaying || !_dragEnabled) return;
    if (selection.add(i)) notifyListeners();
  }

  // ---------- Araçlar ----------

  void toggleNotesMode() {
    if (!isPlaying) return;
    notesMode = !notesMode;
    notifyListeners();
  }

  void toggleInputMode() {
    if (!isPlaying) return;
    inputMode = inputMode == InputMode.cellFirst
        ? InputMode.numberFirst
        : InputMode.cellFirst;
    activeNumber = null;
    notifyListeners();
  }

  void pressNumber(int d) {
    if (!isPlaying) return;
    if (inputMode == InputMode.numberFirst) {
      activeNumber = activeNumber == d ? null : d;
      notifyListeners();
      return;
    }
    if (selection.isEmpty) return;
    _apply(d, selection);
    notifyListeners();
  }

  void _apply(int d, Set<int> cells) {
    if (cells.length > 1) {
      // Çoklu seçim: sayı her zaman not olarak eklenir / kaldırılır.
      final targets = cells.where((i) => values[i] == 0).toList();
      if (targets.isEmpty) return;
      final allHave = targets.every((i) => hasNote(i, d));
      _pushUndo();
      for (final i in targets) {
        notes[i] = allHave ? notes[i] & ~(1 << d) : notes[i] | (1 << d);
      }
      return;
    }

    final i = cells.first;
    if (isLocked(i)) return;

    if (notesMode) {
      if (values[i] != 0) return;
      _pushUndo();
      notes[i] ^= (1 << d);
      return;
    }

    if (values[i] == d) return;
    _pushUndo();
    values[i] = d;
    if (d == solution[i]) {
      for (var j = 0; j < 81; j++) {
        if (j != i && sameUnit(i, j)) notes[j] &= ~(1 << d);
      }
      _checkWin();
    } else {
      mistakes++;
      if (mistakes >= maxMistakes) _finish(GameStatus.lost);
    }
  }

  void erase() {
    if (!isPlaying) return;
    final targets = selection
        .where((i) => !isLocked(i) && (values[i] != 0 || notes[i] != 0))
        .toList();
    if (targets.isEmpty) return;
    _pushUndo();
    for (final i in targets) {
      if (values[i] != 0) {
        values[i] = 0;
      } else {
        notes[i] = 0;
      }
    }
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    final s = _undoStack.removeLast();
    values.setAll(0, s.values);
    notes.setAll(0, s.notes);
    notifyListeners();
  }

  void _pushUndo() {
    _undoStack.add(_Snapshot(List<int>.of(values), List<int>.of(notes)));
  }

  void _checkWin() {
    for (var i = 0; i < 81; i++) {
      if (values[i] != solution[i]) return;
    }
    _finish(GameStatus.won);
  }

  void _finish(GameStatus result) {
    status = result;
    activeNumber = null;
    _stopTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
