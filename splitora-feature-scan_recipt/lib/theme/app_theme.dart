import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._(); // prevent instantiation

  // ---------------------------------------------------------------------------
  // Core Brand Colors
  // ---------------------------------------------------------------------------
  static const Color gradientStart = Color(0xFF00C6FF); // cyan
  static const Color gradientEnd = Color(0xFF0072FF); // blue
  static const Color appBarColor = Color(0xFF0072FF);
  static const Color buttonForeground = Color(0xFF2575FC);
  static const Color fabIconColor = Color(0xFF0072FF);

  // ---------------------------------------------------------------------------
  // Text Colors
  // ---------------------------------------------------------------------------
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textTertiary = Colors.white60;
  static const Color errorColor = Colors.redAccent;
  static const Color successColor = Colors.greenAccent;

  // ---------------------------------------------------------------------------
  // Status / Bill Colors
  // ---------------------------------------------------------------------------
  static const Color owesColor = Colors.redAccent; // "You owe"
  static const Color owedColor = Colors.greenAccent; // "Owes you"

  // ---------------------------------------------------------------------------
  // Chat Message Bubble Colors
  // ---------------------------------------------------------------------------
  static const Color sentMessageBg = Colors.white;
  static const Color sentMessageText = Colors.black87;
  static const Color sentMessageMeta = Colors.black54;
  static Color get receivedMessageBg => Colors.white.withOpacity(0.2);
  static const Color receivedMessageText = Colors.white;
  static const Color receivedMessageMeta = Colors.white60;

  // ---------------------------------------------------------------------------
  // Component Colors (non-const — use withOpacity)
  // ---------------------------------------------------------------------------
  static Color get cardBackground => Colors.white.withOpacity(0.1);
  static Color get cardBorder => Colors.white.withOpacity(0.2);
  static Color get inputFill => Colors.white.withOpacity(0.1);
  static Color get inputFillDense => Colors.white.withOpacity(0.2);
  static Color get disabledButtonBackground => Colors.white.withOpacity(0.5);
  static Color get avatarImageBackground => Colors.white.withOpacity(0.3);

  // ---------------------------------------------------------------------------
  // Component Colors (const)
  // ---------------------------------------------------------------------------
  static const Color disabledButtonForeground = Colors.grey;
  static const Color avatarBackground = Colors.white24;
  static const Color iconColor = Colors.white70;
  static const Color readOnlyFill = Colors.black12;
  static const Color fabBackground = Colors.white;

  // ---------------------------------------------------------------------------
  // Bottom Navigation
  // ---------------------------------------------------------------------------
  static const Color navSelected = Colors.white;
  static const Color navUnselected = Colors.white60;

  // ---------------------------------------------------------------------------
  // Checkbox
  // ---------------------------------------------------------------------------
  static const Color checkboxActive = Colors.white;
  static const Color checkboxCheck = Color(0xFF2575FC);

  // ---------------------------------------------------------------------------
  // Gradient
  // ---------------------------------------------------------------------------
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  // ---------------------------------------------------------------------------
  // Reusable Decorations
  // ---------------------------------------------------------------------------

  /// Full-screen gradient background used on every scaffold body.
  static const BoxDecoration backgroundDecoration = BoxDecoration(
    gradient: backgroundGradient,
  );

  /// Frosted-glass card (border-radius 20) used on auth screens.
  static BoxDecoration get glassCardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: cardBorder),
  );

  /// Rounded card (border-radius 15) used for list tiles and bill cards.
  static BoxDecoration get listTileDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: cardBorder),
  );

  // ---------------------------------------------------------------------------
  // App-wide ThemeData
  // ---------------------------------------------------------------------------
  static ThemeData get themeData =>
      ThemeData(textTheme: GoogleFonts.quicksandTextTheme());
}
