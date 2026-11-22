import 'package:flutter/material.dart';

/// Marka rengi (okra). Oyun ekranında ve ızgarada kullanılmaz.
const Color brandOkra = Color(0xFFB8963E);

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: brandOkra,
    brightness: brightness,
  ).copyWith(
    primary: brandOkra,
    onPrimary: const Color(0xFF1C1C1C),
    surface: isDark ? const Color(0xFF121212) : Colors.white,
    onSurface: isDark ? const Color(0xFFEDEDED) : const Color(0xFF1E1E1E),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}

/// Oyun ekranının nötr (beyaz–gri–siyah) renkleri.
class GameColors {
  final Color background;
  final Color board;
  final Color peer;
  final Color selected;
  final Color thinLine;
  final Color thickLine;
  final Color givenText;
  final Color userText;
  final Color noteText;
  final Color error;
  final Color padButton;
  final Color padActive;
  final Color padActiveText;
  final Color icon;
  final Color muted;

  const GameColors({
    required this.background,
    required this.board,
    required this.peer,
    required this.selected,
    required this.thinLine,
    required this.thickLine,
    required this.givenText,
    required this.userText,
    required this.noteText,
    required this.error,
    required this.padButton,
    required this.padActive,
    required this.padActiveText,
    required this.icon,
    required this.muted,
  });

  static const light = GameColors(
    background: Color(0xFFFFFFFF),
    board: Color(0xFFFFFFFF),
    peer: Color(0xFFEDEDED),
    selected: Color(0xFFD4D4D4),
    thinLine: Color(0xFFCFCFCF),
    thickLine: Color(0xFF2E2E2E),
    givenText: Color(0xFF1E1E1E),
    userText: Color(0xFF5C5C5C),
    noteText: Color(0xFF6E6E6E),
    error: Color(0xFFD32F2F),
    padButton: Color(0xFFF2F2F2),
    padActive: Color(0xFF2E2E2E),
    padActiveText: Color(0xFFFFFFFF),
    icon: Color(0xFF3A3A3A),
    muted: Color(0xFF8A8A8A),
  );

  static const dark = GameColors(
    background: Color(0xFF121212),
    board: Color(0xFF161616),
    peer: Color(0xFF262626),
    selected: Color(0xFF3A3A3A),
    thinLine: Color(0xFF2E2E2E),
    thickLine: Color(0xFFA0A0A0),
    givenText: Color(0xFFA8A8A8),
    userText: Color(0xFFF5F5F5),
    noteText: Color(0xFF9A9A9A),
    error: Color(0xFFFF6B6B),
    padButton: Color(0xFF222222),
    padActive: Color(0xFFE0E0E0),
    padActiveText: Color(0xFF121212),
    icon: Color(0xFFD0D0D0),
    muted: Color(0xFF8A8A8A),
  );

  static GameColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
