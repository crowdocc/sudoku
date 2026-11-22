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
  final Color gridShadow;
  final Color cell;
  final Color cellLine;
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
  final Color key;
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
    required this.selected,
    required this.selectedBorder,
    required this.boxLine,
    required this.givenText,
    required this.userText,
    required this.noteText,
    required this.error,
    required this.cageLine,
    required this.cageText,
    required this.key,
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
    background: Color(0xFFEDEDEC),
    gridShadow: Color(0x24000000),
    cell: Color(0xFFFFFFFF),
    cellLine: Color(0xFFE6E6E6),
    peer: Color(0xFFEDEDED),
    selected: Color(0xFFD3D3D3),
    selectedBorder: Color(0xFF6A6A6A),
    boxLine: Color(0x99B8963E),
    givenText: Color(0xFF1E1E1E),
    userText: Color(0xFF5C5C5C),
    noteText: Color(0xFF6E6E6E),
    error: Color(0xFFD32F2F),
    cageLine: Color(0xFF505050),
    cageText: Color(0xFF3A3A3A),
    key: Color(0xFFF9F9F9),
    keyShadow: Color(0x33000000),
    keyText: Color(0xFF2A2A2A),
    engrave: Color(0xE6FFFFFF),
    keyActive: Color(0xFF333333),
    keyActiveText: Color(0xFFFFFFFF),
    icon: Color(0xFF3A3A3A),
    muted: Color(0xFF8A8A8A),
    tool: Color(0xFF8C8C8C),
    paintAlpha: 0.55,
  );

  static const dark = GameColors(
    background: Color(0xFF101010),
    gridShadow: Color(0x99000000),
    cell: Color(0xFF1B1B1B),
    cellLine: Color(0xFF262626),
    peer: Color(0xFF2A2A2A),
    selected: Color(0xFF3D3D3D),
    selectedBorder: Color(0xFFBDBDBD),
    boxLine: Color(0x8CB8963E),
    givenText: Color(0xFFA8A8A8),
    userText: Color(0xFFF5F5F5),
    noteText: Color(0xFF9A9A9A),
    error: Color(0xFFFF6B6B),
    cageLine: Color(0xFFE4E4E4),
    cageText: Color(0xFFE0E0E0),
    key: Color(0xFF262626),
    keyShadow: Color(0xB3000000),
    keyText: Color(0xFFD8D8D8),
    engrave: Color(0xB3000000),
    keyActive: Color(0xFFE0E0E0),
    keyActiveText: Color(0xFF121212),
    icon: Color(0xFFD0D0D0),
    muted: Color(0xFF8A8A8A),
    tool: Color(0xFF8A8A8A),
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
