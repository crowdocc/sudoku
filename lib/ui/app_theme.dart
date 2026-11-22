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

/// Oyun ekranının renkleri. Zemin okra tonlu; seçim ve vurgularda okra yok.
class GameColors {
  final Color background;
  final Color gridShadow;
  final Color cell;
  final Color cellLine;
  final Color peer;
  final Color sameNumber;
  final Color selected;
  final Color selectedBorder;
  final Color selectedText;
  final Color boxLine;
  final Color givenText;
  final Color userText;
  final Color noteText;
  final Color error;
  final Color cageLine;
  final Color cageText;
  final Color key;
  final Color keyBorder;
  final Color keyShadow;
  final Color keyText;
  final Color engrave;
  final Color keyActive;
  final Color keyActiveText;
  final Color icon;
  final Color muted;
  final Color tool;
  final double paintAlpha;

  const GameColors({
    required this.background,
    required this.gridShadow,
    required this.cell,
    required this.cellLine,
    required this.peer,
    required this.sameNumber,
    required this.selected,
    required this.selectedBorder,
    required this.selectedText,
    required this.boxLine,
    required this.givenText,
    required this.userText,
    required this.noteText,
    required this.error,
    required this.cageLine,
    required this.cageText,
    required this.key,
    required this.keyBorder,
    required this.keyShadow,
    required this.keyText,
    required this.engrave,
    required this.keyActive,
    required this.keyActiveText,
    required this.icon,
    required this.muted,
    required this.tool,
    required this.paintAlpha,
  });

  static const light = GameColors(
    background: Color(0xFFF3EFE6),
    gridShadow: Color(0x1F000000),
    cell: Color(0xFFFBF8F2),
    cellLine: Color(0xFFE2DCCF),
    peer: Color(0xFFEFE8DA),
    sameNumber: Color(0xFFE2D8C3),
    selected: Color(0xFFBCD0E8),
    selectedBorder: Color(0xFF5F86B8),
    selectedText: Color(0xFF1A1A1A),
    boxLine: Color(0xFFB8963E),
    givenText: Color(0xFF1E1E1E),
    userText: Color(0xFF5C5C5C),
    noteText: Color(0xFF6A6A6A),
    error: Color(0xFFD32F2F),
    cageLine: Color(0xFF4A4538),
    cageText: Color(0xFF4A4538),
    key: Color(0xFFFFFDF8),
    keyBorder: Color(0xFFDDD6C7),
    keyShadow: Color(0x29000000),
    keyText: Color(0xFF2A2A2A),
    engrave: Color(0xE6FFFFFF),
    keyActive: Color(0xFF4A4538),
    keyActiveText: Color(0xFFFFFFFF),
    icon: Color(0xFF3A3A3A),
    muted: Color(0xFF8A8578),
    tool: Color(0xFF8C877B),
    paintAlpha: 0.55,
  );

  static const dark = GameColors(
    background: Color(0xFF2A2824),
    gridShadow: Color(0x59000000),
    cell: Color(0xFF22201C),
    cellLine: Color(0xFF383530),
    peer: Color(0xFF3A362E),
    sameNumber: Color(0xFF4B463B),
    selected: Color(0xFF3E5F8A),
    selectedBorder: Color(0xFF6A8DBA),
    selectedText: Color(0xFFFFFFFF),
    boxLine: Color(0xFFB8963E),
    givenText: Color(0xFFB4B4B4),
    userText: Color(0xFFF5F5F5),
    noteText: Color(0xFFA3A3A3),
    error: Color(0xFFFF6B6B),
    cageLine: Color(0xFFEDE7DA),
    cageText: Color(0xFFEDE7DA),
    key: Color(0xFF35322C),
    keyBorder: Color(0xFF1C1A17),
    keyShadow: Color(0x73000000),
    keyText: Color(0xFFE4E0D8),
    engrave: Color(0x99000000),
    keyActive: Color(0xFFD9D4C8),
    keyActiveText: Color(0xFF22201C),
    icon: Color(0xFFD6D1C6),
    muted: Color(0xFF8F8A80),
    tool: Color(0xFF9A958B),
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
