import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Colors
class PolicyColors {
  static const Color primaryColor = Color(0xFF416CAF); // 30% blue
  static const Color textColor = Colors.black87; // 10% black
  static const MaterialColor successColor =
      Colors.green; // Temporary for SnackBars
  static const MaterialColor errorColor = Colors.red; // Temporary for SnackBars
  static const MaterialColor warningColor =
      Colors.red; // Temporary for SnackBars
  static const Color backgroundColor = Colors.white; // 60% white
  static const Color cardColor = Colors.white; // 60% white
}

// Text Styles
class PolicyTextStyles {
  static TextStyle appBarTitle = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    color: PolicyColors.backgroundColor, // White (10%)
    fontSize: 20,
  );

  static TextStyle cardTitle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: PolicyColors.primaryColor, // Blue (30%)
  );

  static TextStyle cardDescription = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: PolicyColors.textColor, // Black (10%)
  );

  static TextStyle noData = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: PolicyColors.textColor, // Black (10%)
  );

  static TextStyle error = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: PolicyColors.errorColor, // Red (temporary)
  );

  static TextStyle snackBarText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: PolicyColors.backgroundColor, // White (10%)
  );

  static TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: PolicyColors.backgroundColor, // White (10%)
  );
}

// Icons
class PolicyIcons {
  static const IconData menu = Icons.menu;
  static const IconData retry = Icons.refresh;
  static const IconData success = Icons.check_circle;
  static const IconData error = Icons.error;
  static const IconData warning = Icons.warning;
}

// Theme Configuration
ThemeData getPolicyTheme() {
  return ThemeData(
    primaryColor: PolicyColors.primaryColor,
    scaffoldBackgroundColor: PolicyColors.backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: PolicyColors.primaryColor, // Blue (30%)
      secondary: PolicyColors.primaryColor,
      onPrimary: PolicyColors.backgroundColor, // White (10%)
      onSurface: PolicyColors.textColor, // Black (10%)
      error: PolicyColors.errorColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: PolicyColors.primaryColor,
      foregroundColor: PolicyColors.backgroundColor,
      elevation: 0,
      titleTextStyle: PolicyTextStyles.appBarTitle,
    ),
    cardTheme: CardThemeData(
      elevation: 3,
      color: PolicyColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PolicyColors.primaryColor, // Blue (30%)
        foregroundColor: PolicyColors.backgroundColor, // White (10%)
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: PolicyTextStyles.buttonText,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentTextStyle: PolicyTextStyles.snackBarText,
      backgroundColor: PolicyColors.errorColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PolicyColors.backgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: PolicyColors.primaryColor.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: PolicyColors.primaryColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: PolicyColors.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PolicyColors.errorColor, width: 1),
      ),
      labelStyle: PolicyTextStyles.cardDescription,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    ),
  );
}
