import 'dart:async';

import 'package:flutter/foundation.dart';

import 'puzzles.dart';
import 'sum_solver.dart';

enum InputMode { cellFirst, numberFirst }

enum GameStatus { playing, won, lost }

class _Snapshot {
  final List<int> values;
  final List<int> notes;
  final List<int> colors;

  const _Snapshot(this.values, this.notes, this.colors);
}

/// Bir sudoku oyununun (klasik veya killer) tüm durumu ve kuralları.
class GameState extends ChangeNotifier {
  static const int maxMistakes = 3;
  static const int paletteSize = 9;

  final Puzzle puzzle;
  final GameMode mode;
  final List<int> solution;
  final List<bool> given;
  final List<int> values;
  final List<Cage> cages;

  /// Her hücrenin kafes numarası (klasikte -1).
  final List<int> cageOf;

  /// Not bit maskesi: (1 << d) biti d notunun varlığını gösterir.
  final List<int> notes;

  /// Boya bit maskesi: (1 << k) biti k. rengin varlığını gösterir (k = 0..8).
  final List<int> colors;

  final Set<int> selection = <int>{};
  InputMode inputMode;
  bool notesMode = false;

  /// Önce-sayı modunda seçili rakam ve (killer'da) aday takımından mı seçildiği.
  int? activeNumber;
  bool activeIsNote = false;

  /// Alt panelde Renkler sayfası açık mı.
  bool colorPage = false;

  int mistakes = 0;
  GameStatus status = GameStatus.playing;
  bool paused = false;
  int elapsedSeconds = 0;

  /// Seçimin kesin bilinen toplamı (en az iki hücre seçiliyse), yoksa null.
  int? selectionSum;

  Timer? _timer;
  final List<_Snapshot> _undoStack = <_Snapshot>[];

  GameState(this.puzzle, {this.inputMode = InputMode.cellFirst})
      : mode = puzzle.mode,
        solution = _digits(puzzle.solution),
        values = _digits(puzzle.givens),
        given = _digits(puzzle.givens).map((d) => d != 0).toList(),
        cages = puzzle.cages,
        cageOf = List<int>.filled(81, -1),
        notes = List<int>.filled(81, 0),
        colors = List<int>.filled(81, 0) {
    for (var k = 0; k < cages.length; k++) {
      for (final c in cages[k].cells) {
        cageOf[c] = k;
      }
    }
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

  bool get isKiller => mode == GameMode.killer;

  bool get isPlaying => status == GameStatus.playing && !paused;

  bool get canUndo => _undoStack.isNotEmpty && isPlaying;

  bool isWrong(int i) => values[i] != 0 && values[i] != solution[i];

  /// Verilen ya da doğru girilmiş hücreler değiştirilemez.
  bool isLocked(int i) =>
      given[i] || (values[i] != 0 && values[i] == solution[i]);

  bool hasNote(int i, int d) => (notes[i] & (1 << d)) != 0;

  bool hasColor(int i, int k) => (colors[i] & (1 << k)) != 0;

  /// Bir rakamdan ızgaraya daha kaç tane doğru yerleştirilebileceği.
  int remaining(int d) {
    var count = 0;
    for (var i = 0; i < 81; i++) {
      if (values[i] == d && solution[i] == d) count++;
    }
    return 9 - count;
  }

  /// Seçili hücrelerin hepsinde bu renk var mı (Renkler sayfasında işaret için).
  bool selectionHasColor(int k) =>
      selection.isNotEmpty && selection.every((i) => hasColor(i, k));

  /// Vurgulanacak sayı: önce-sayı modunda seçili rakam, yoksa seçili hücredeki sayı.
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

  /// Süre dışındaki her değişiklikten sonra çağrılır.
  void _changed() {
    _updateSum();
    notifyListeners();
  }

  void _updateSum() {
    if (selection.length < 2 || selection.any(isWrong)) {
      selectionSum = null;
      return;
    }
    final known = List<int?>.generate(81, (i) => isLocked(i) ? values[i] : null);
    selectionSum = knownSelectionSum(
      selection: selection,
      knownValues: known,
      cages: cages,
    );
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
    final applying = !colorPage &&
        inputMode == InputMode.numberFirst &&
        activeNumber != null;
    if (applying) {
      selection
        ..clear()
        ..add(i);
      _apply(activeNumber!, <int>{i}, isKiller ? activeIsNote : notesMode);
    } else if (selection.length == 1 && selection.contains(i)) {
      selection.clear();
    } else {
      selection
        ..clear()
        ..add(i);
    }
    _changed();
  }

  /// Izgara dışına dokunulunca seçim ve vurgular kalkar.
  void clearSelection() {
    if (selection.isEmpty && activeNumber == null) return;
    selection.clear();
    activeNumber = null;
    _changed();
  }

  bool get _dragEnabled =>
      colorPage ||
      !(inputMode == InputMode.numberFirst && activeNumber != null);

  void dragStart(int i) {
    if (!isPlaying || !_dragEnabled) return;
    selection
      ..clear()
      ..add(i);
    _changed();
  }

  void dragTo(int i) {
    if (!isPlaying || !_dragEnabled) return;
    if (selection.add(i)) _changed();
  }

  // ---------- Araçlar ----------

  void setColorPage(bool value) {
    if (colorPage == value) return;
    colorPage = value;
    notifyListeners();
  }

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
    _changed();
  }

  /// Rakam tuşu. [asCandidate]: killer'daki Adaylar takımından basıldı.
  void pressNumber(int d, {bool asCandidate = false}) {
    if (!isPlaying) return;
    final asNote = isKiller ? asCandidate : notesMode;
    if (inputMode == InputMode.numberFirst) {
      if (activeNumber == d && activeIsNote == asCandidate) {
        activeNumber = null;
      } else {
        activeNumber = d;
        activeIsNote = asCandidate;
      }
      _changed();
      return;
    }
    if (selection.isEmpty) return;
    _apply(d, selection, asNote);
    _changed();
  }

  void _apply(int d, Set<int> cells, bool asNote) {
    if (cells.length > 1) {
      // Çoklu seçim: rakam her zaman not olarak eklenir / kaldırılır.
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

    if (asNote) {
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

  /// Renk tuşu: seçili hücrelerin hepsinde varsa kaldırır, yoksa ekler.
  void toggleColor(int k) {
    if (!isPlaying || selection.isEmpty) return;
    final allHave = selectionHasColor(k);
    _pushUndo();
    for (final i in selection) {
      colors[i] = allHave ? colors[i] & ~(1 << k) : colors[i] | (1 << k);
    }
    _changed();
  }

  void clearColors() {
    if (!isPlaying) return;
    final targets = selection.where((i) => colors[i] != 0).toList();
    if (targets.isEmpty) return;
    _pushUndo();
    for (final i in targets) {
      colors[i] = 0;
    }
    _changed();
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
    _changed();
  }

  void undo() {
    if (!canUndo) return;
    final s = _undoStack.removeLast();
    values.setAll(0, s.values);
    notes.setAll(0, s.notes);
    colors.setAll(0, s.colors);
    _changed();
  }

  void _pushUndo() {
    _undoStack.add(_Snapshot(
      List<int>.of(values),
      List<int>.of(notes),
      List<int>.of(colors),
    ));
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
