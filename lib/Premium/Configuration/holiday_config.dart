import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Colors
class HolidayColors {
  static const Color primaryColor = Color(0xFF416CAF); // 30% blue
  static const Color textColor = Colors.black87; // 10% black
  static const MaterialColor successColor =
      Colors.green; // Temporary for SnackBars
  static const MaterialColor errorColor = Colors.red; // Temporary for SnackBars
  static const MaterialColor warningColor =
      Colors.orange; // Temporary for SnackBars
  static const Color backgroundColor = Colors.white; // 60% white
  static const Color cardColor = Colors.white; // 60% white
}

// Text Styles
class HolidayTextStyles {
  static TextStyle appBarTitle = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    color: HolidayColors.backgroundColor, // White (10%)
    fontSize: 20,
  );

  static TextStyle heading = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: HolidayColors.primaryColor, // Blue (30%)
  );

  static TextStyle subheading = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: HolidayColors.primaryColor, // Blue (30%)
  );

  static TextStyle label = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: HolidayColors.textColor, // Black (10%)
  );

  static TextStyle caption = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: HolidayColors.textColor, // Black (10%)
  );

  static TextStyle snackBarText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: HolidayColors.backgroundColor, // White (10%)
  );

  static TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: HolidayColors.backgroundColor, // White (10%)
  );
}

// Icons
class HolidayIcons {
  static const IconData menu = Icons.menu;
  static const IconData retry = Icons.refresh;
  static const IconData success = Icons.check_circle;
  static const IconData error = Icons.error;
  static const IconData warning = Icons.warning;
  static const IconData calendar = Icons.calendar_today;
  static const IconData holiday = Icons.celebration;
}

// Theme Configuration
ThemeData getHolidayTheme() {
  return ThemeData(
    primaryColor: HolidayColors.primaryColor,
    scaffoldBackgroundColor: HolidayColors.backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: HolidayColors.primaryColor, // Blue (30%)
      secondary: HolidayColors.primaryColor,
      onPrimary: HolidayColors.backgroundColor, // White (10%)
      onSurface: HolidayColors.textColor, // Black (10%)
      error: HolidayColors.errorColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: HolidayColors.primaryColor,
      foregroundColor: HolidayColors.backgroundColor,
      elevation: 0,
      titleTextStyle: HolidayTextStyles.appBarTitle,
    ),
    cardTheme: CardThemeData(
      elevation: 3,
      color: HolidayColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: HolidayColors.primaryColor, // Blue (30%)
        foregroundColor: HolidayColors.backgroundColor, // White (10%)
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: HolidayTextStyles.buttonText,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentTextStyle: HolidayTextStyles.snackBarText,
      backgroundColor: HolidayColors.errorColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HolidayColors.backgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: HolidayColors.primaryColor.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: HolidayColors.primaryColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: HolidayColors.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: HolidayColors.errorColor, width: 1),
      ),
      labelStyle: HolidayTextStyles.label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    ),
  );
}
