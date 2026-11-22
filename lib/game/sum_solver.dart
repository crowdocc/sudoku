import 'puzzles.dart';

/// Seçili hücrelerin toplamı, bilinen toplamlar (dolu hücreler, satır/sütun/kutu = 45,
/// kafes toplamları) eklenip çıkarılarak kesin hesaplanabiliyorsa döndürülür.
/// Hesaplanamıyorsa null döner.
///
/// Yöntem: her bilinen toplam bir denklemdir. Seçimin göstergesi bu denklemlerin
/// doğrusal birleşimiyse toplam aynı birleşimle bulunur. Böylece örtüşmeler ve
/// 45 kuralı türü hesaplar çift sayım olmadan doğru çıkar.
int? knownSelectionSum({
  required Set<int> selection,
  required List<int?> knownValues,
  required List<Cage> cages,
}) {
  if (selection.isEmpty) return null;
  const n = 81;
  const eps = 1e-7;

  final basisRows = <List<double>>[];
  final basisPivots = <int>[];
  final basisRhs = <double>[];

  void addConstraint(Iterable<int> cells, double rhs) {
    final v = List<double>.filled(n, 0);
    for (final c in cells) {
      v[c] += 1;
    }
    var r = rhs;
    for (var k = 0; k < basisRows.length; k++) {
      final f = v[basisPivots[k]];
      if (f.abs() < eps) continue;
      final row = basisRows[k];
      for (var j = 0; j < n; j++) {
        v[j] -= f * row[j];
      }
      r -= f * basisRhs[k];
    }
    var pivot = -1;
    for (var j = 0; j < n; j++) {
      if (v[j].abs() > eps) {
        pivot = j;
        break;
      }
    }
    if (pivot == -1) return;
    final p = v[pivot];
    for (var j = 0; j < n; j++) {
      v[j] /= p;
    }
    basisRows.add(v);
    basisPivots.add(pivot);
    basisRhs.add(r / p);
  }

  for (var i = 0; i < n; i++) {
    final value = knownValues[i];
    if (value != null) addConstraint(<int>[i], value.toDouble());
  }
  for (var u = 0; u < 9; u++) {
    addConstraint(List<int>.generate(9, (k) => u * 9 + k), 45);
    addConstraint(List<int>.generate(9, (k) => k * 9 + u), 45);
    final br = (u ~/ 3) * 3;
    final bc = (u % 3) * 3;
    addConstraint(
      List<int>.generate(9, (k) => (br + k ~/ 3) * 9 + bc + k % 3),
      45,
    );
  }
  for (final cage in cages) {
    addConstraint(cage.cells, cage.sum.toDouble());
  }

  final s = List<double>.filled(n, 0);
  for (final c in selection) {
    s[c] = 1;
  }
  var total = 0.0;
  for (var k = 0; k < basisRows.length; k++) {
    final f = s[basisPivots[k]];
    if (f.abs() < eps) continue;
    final row = basisRows[k];
    for (var j = 0; j < n; j++) {
      s[j] -= f * row[j];
    }
    total += f * basisRhs[k];
  }
  for (var j = 0; j < n; j++) {
    if (s[j].abs() > 1e-5) return null;
  }
  return total.round();
}
