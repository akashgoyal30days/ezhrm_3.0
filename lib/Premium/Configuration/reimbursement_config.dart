import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Colors
class ReimbursementColors {
  static const Color primaryColor = Color(0xFF416CAF); // 30% blue
  static const Color textColor = Colors.black; // 10% black
  static const MaterialColor successColor =
      Colors.green; // Temporary for SnackBars
  static const MaterialColor errorColor = Colors.red; // Temporary for SnackBars
  static const Color warningColor =
      Color(0xFF416CAF); // Temporary for SnackBars
  static const Color backgroundColor = Colors.white; // 60% white
}

// Text Styles using Google Fonts Poppins
class ReimbursementTextStyles {
  static TextStyle appBarTitle = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    color: ReimbursementColors.backgroundColor, // White
  );

  static TextStyle heading = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: ReimbursementColors.textColor, // Black
  );

  static TextStyle subheading = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ReimbursementColors.primaryColor, // Blue
  );

  static TextStyle label = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: ReimbursementColors.textColor, // Black
  );

  static TextStyle dropdownItem = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: ReimbursementColors.textColor, // Black
  );

  static TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: ReimbursementColors.backgroundColor, // White
  );

  static TextStyle snackBarText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ReimbursementColors.backgroundColor, // White
  );

  static TextStyle errorText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ReimbursementColors.errorColor, // Red
  );
}

// Icons
class ReimbursementIcons {
  static const IconData menu = Icons.menu;
  static const IconData expenseType = Icons.category;
  static const IconData customer = Icons.person;
  static const IconData dateRange = Icons.date_range;
  static const IconData amount = Icons.currency_rupee;
  static const IconData description = Icons.description;
  static const IconData image = Icons.image;
  static const IconData dropdown = Icons.arrow_drop_down_circle;
  static const IconData submit = Icons.send;
  static const IconData retry = Icons.refresh;
  static const IconData success = Icons.check_circle;
  static const IconData error = Icons.error;
  static const IconData warning = Icons.warning;
}

// Theme Configuration
ThemeData getReimbursementTheme() {
  return ThemeData(
    primaryColor: ReimbursementColors.primaryColor,
    scaffoldBackgroundColor: ReimbursementColors.backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: ReimbursementColors.primaryColor, // Blue
      secondary: ReimbursementColors.primaryColor,
      onPrimary: ReimbursementColors.backgroundColor, // White
      onSurface: ReimbursementColors.textColor, // Black
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ReimbursementColors.backgroundColor, // White
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: ReimbursementColors.primaryColor.withOpacity(0.3)), // Blue
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: ReimbursementColors.primaryColor.withOpacity(0.3)), // Blue
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: ReimbursementColors.primaryColor, width: 2), // Blue
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: ReimbursementColors.errorColor, width: 1), // Red
      ),
      labelStyle: ReimbursementTextStyles.label, // Black
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ReimbursementColors.primaryColor, // Blue
        foregroundColor: ReimbursementColors.backgroundColor, // White
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: ReimbursementTextStyles.buttonText, // White
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentTextStyle: ReimbursementTextStyles.snackBarText, // White
    ),
  );
}
