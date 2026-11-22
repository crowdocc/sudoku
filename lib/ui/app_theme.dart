import 'package:flutter/material.dart';

/// Marka rengi (okra). Hücrelerde, seçim ve vurgularda kullanılmaz.
const Color brandOkra = Color(0xFFB8963E);

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colors = isDark ? GameColors.dark : GameColors.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: brandOkra,
    brightness: brightness,
  ).copyWith(
    primary: brandOkra,
    onPrimary: const Color(0xFF1C1C1C),
    surface: colors.background,
    onSurface: isDark ? const Color(0xFFEDEDED) : const Color(0xFF1E1E1E),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: colors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}

/// Tepeden bakış: ofsetsiz, her yöne eşit yumuşak gölge.
List<BoxShadow> topDownShadow(Color color, double blur) => [
      BoxShadow(color: color, blurRadius: blur, offset: Offset.zero),
    ];

/// Oyun ekranının renkleri. Hücre, seçim ve vurgular nötr tonlardadır.
class GameColors {
  final Color background;
  final Color card;
  final Color cardShadow;
  final Color gap;
  final Color cell;
  final Color cellShadow;
  final Color peer;
  final Color selected;
  final Color selectedBorder;
  final Color boxLine;
  final Color givenText;
  final Color userText;
  final Color noteText;
  final Color error;
  final Color cageLine;
  final Color cageText;
  final Color panel;
  final Color key;
  final Color keyShadow;
  final Color keyText;
  final Color engrave;
  final Color keyActive;
  final Color keyActiveText;
  final Color icon;
  final Color muted;
  final double paintAlpha;

  const GameColors({
    required this.background,
    required this.card,
    required this.cardShadow,
    required this.gap,
    required this.cell,
    required this.cellShadow,
    required this.peer,
    required this.selected,
    required this.selectedBorder,
    required this.boxLine,
    required this.givenText,
    required this.userText,
    required this.noteText,
    required this.error,
    required this.cageLine,
    required this.cageText,
    required this.panel,
    required this.key,
    required this.keyShadow,
    required this.keyText,
    required this.engrave,
    required this.keyActive,
    required this.keyActiveText,
    required this.icon,
    required this.muted,
    required this.paintAlpha,
  });

  static const light = GameColors(
    background: Color(0xFFEBEBEA),
    card: Color(0xFFF6F6F6),
    cardShadow: Color(0x2E000000),
    gap: Color(0xFFDCDCDC),
    cell: Color(0xFFFFFFFF),
    cellShadow: Color(0x14000000),
    peer: Color(0xFFEBEBEB),
    selected: Color(0xFFD0D0D0),
    selectedBorder: Color(0xFF6A6A6A),
    boxLine: brandOkra,
    givenText: Color(0xFF1E1E1E),
    userText: Color(0xFF5C5C5C),
    noteText: Color(0xFF6E6E6E),
    error: Color(0xFFD32F2F),
    cageLine: Color(0xFF8E8E8E),
    cageText: Color(0xFF454545),
    panel: Color(0xFFE2E2E1),
    key: Color(0xFFF8F8F8),
    keyShadow: Color(0x33000000),
    keyText: Color(0xFF2A2A2A),
    engrave: Color(0xE6FFFFFF),
    keyActive: Color(0xFF333333),
    keyActiveText: Color(0xFFFFFFFF),
    icon: Color(0xFF3A3A3A),
    muted: Color(0xFF8A8A8A),
    paintAlpha: 0.55,
  );

  static const dark = GameColors(
    background: Color(0xFF0E0E0E),
    card: Color(0xFF1A1A1A),
    cardShadow: Color(0xB3000000),
    gap: Color(0xFF121212),
    cell: Color(0xFF1F1F1F),
    cellShadow: Color(0x80000000),
    peer: Color(0xFF2B2B2B),
    selected: Color(0xFF3E3E3E),
    selectedBorder: Color(0xFFBDBDBD),
    boxLine: brandOkra,
    givenText: Color(0xFFA8A8A8),
    userText: Color(0xFFF5F5F5),
    noteText: Color(0xFF9A9A9A),
    error: Color(0xFFFF6B6B),
    cageLine: Color(0xFF7A7A7A),
    cageText: Color(0xFFB5B5B5),
    panel: Color(0xFF161616),
    key: Color(0xFF282828),
    keyShadow: Color(0xB3000000),
    keyText: Color(0xFFD8D8D8),
    engrave: Color(0xB3000000),
    keyActive: Color(0xFFE0E0E0),
    keyActiveText: Color(0xFF121212),
    icon: Color(0xFFD0D0D0),
    muted: Color(0xFF8A8A8A),
    paintAlpha: 0.5,
  );

  /// Boyama paleti (9 renk).
  static const List<Color> palette = [
    Color(0xFFE57373), // kırmızı
    Color(0xFFFFB74D), // turuncu
    Color(0xFFFFE066), // sarı
    Color(0xFF81C784), // yeşil
    Color(0xFF4DB6AC), // turkuaz
    Color(0xFF64B5F6), // mavi
    Color(0xFF9575CD), // mor
    Color(0xFFF06292), // pembe
    Color(0xFFA1887F), // kahve
  ];

  static GameColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
