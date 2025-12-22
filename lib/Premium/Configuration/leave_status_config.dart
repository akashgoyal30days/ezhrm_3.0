import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Colors
class LeaveStatusColors {
  static const Color primaryColor = Color(0xFF416CAF); // 30% blue
  static const Color textColor = Colors.black87; // 10% black
  static const MaterialColor successColor =
      Colors.green; // Temporary for SnackBars and status
  static const MaterialColor errorColor =
      Colors.red; // Temporary for SnackBars and status
  static const MaterialColor warningColor =
      Colors.red; // Temporary for SnackBars and status
  static const Color backgroundColor = Colors.white; // 60% white
}

// Text Styles using Google Fonts Poppins
class LeaveStatusTextStyles {
  static TextStyle appBarTitle = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    color: LeaveStatusColors.backgroundColor, // White (10%)
  );

  static TextStyle heading = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: LeaveStatusColors.textColor, // Black (10%)
  );

  static TextStyle subheading = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: LeaveStatusColors.primaryColor, // Blue (30%)
  );

  static TextStyle label = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: LeaveStatusColors.textColor, // Black (10%)
  );

  static TextStyle statusText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: LeaveStatusColors.backgroundColor, // White (10%) for status badges
  );

  static TextStyle snackBarText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: LeaveStatusColors.backgroundColor, // White (10%)
  );

  static TextStyle errorText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: LeaveStatusColors.errorColor, // Red (temporary)
  );

  static TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: LeaveStatusColors.backgroundColor, // White (10%)
  );
}

// Icons
class LeaveStatusIcons {
  static const IconData menu = Icons.menu;
  static const IconData retry = Icons.refresh;
  static const IconData success = Icons.check_circle;
  static const IconData error = Icons.error;
  static const IconData warning = Icons.warning;
  static const IconData approved =
      Icons.check_circle_outline; // For approved status
  static const IconData pending = Icons.hourglass_empty; // For pending status
  static const IconData rejected = Icons.cancel; // For rejected status
  static const IconData creditType = Icons.credit_card;
  static const IconData dateRange = Icons.date_range;
  static const IconData totalDays = Icons.calculate;
  static const IconData reason = Icons.description;
}

// Theme Configuration
ThemeData getLeaveStatusTheme() {
  return ThemeData(
    primaryColor: LeaveStatusColors.primaryColor,
    scaffoldBackgroundColor: LeaveStatusColors.backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: LeaveStatusColors.primaryColor, // Blue (30%)
      secondary: LeaveStatusColors.primaryColor,
      onPrimary: LeaveStatusColors.backgroundColor, // White (10%)
      onSurface: LeaveStatusColors.textColor, // Black (10%)
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LeaveStatusColors.backgroundColor, // White (60%)
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color:
                LeaveStatusColors.primaryColor.withOpacity(0.3)), // Blue (30%)
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color:
                LeaveStatusColors.primaryColor.withOpacity(0.3)), // Blue (30%)
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: LeaveStatusColors.primaryColor, width: 2), // Blue (30%)
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: LeaveStatusColors.errorColor, width: 1), // Red (temporary)
      ),
      labelStyle: LeaveStatusTextStyles.label, // Black (10%)
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LeaveStatusColors.primaryColor, // Blue (30%)
        foregroundColor: LeaveStatusColors.backgroundColor, // White (10%)
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: LeaveStatusTextStyles.buttonText, // White (10%)
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentTextStyle: LeaveStatusTextStyles.snackBarText, // White (10%)
    ),
  );
}
