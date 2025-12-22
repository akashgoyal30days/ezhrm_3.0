import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Colors
class LeaveQuotaColors {
  static const Color primaryColor = Color(0xFF416CAF); // 30% blue
  static const Color textColor = Colors.black87; // 10% black
  static const MaterialColor successColor =
      Colors.green; // Temporary for SnackBars
  static const MaterialColor errorColor = Colors.red; // Temporary for SnackBars
  static const MaterialColor warningColor =
      Colors.orange; // Temporary for SnackBars
  static const Color backgroundColor = Colors.white; // 60% white
}

// Text Styles using Google Fonts Poppins
class LeaveQuotaTextStyles {
  static TextStyle appBarTitle = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    color: LeaveQuotaColors.backgroundColor, // White (10%)
  );

  static TextStyle heading = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: LeaveQuotaColors.textColor, // Black (10%)
  );

  static TextStyle subheading = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: LeaveQuotaColors.primaryColor, // Blue (30%)
  );

  static TextStyle label = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: LeaveQuotaColors.textColor, // Black (10%)
  );

  static TextStyle quotaText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: LeaveQuotaColors.textColor, // Black (10%)
  );

  static TextStyle snackBarText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: LeaveQuotaColors.backgroundColor, // White (10%)
  );

  static TextStyle errorText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: LeaveQuotaColors.errorColor, // Red (temporary)
  );

  static TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: LeaveQuotaColors.backgroundColor, // White (10%)
  );
}

// Icons
class LeaveQuotaIcons {
  static const IconData menu = Icons.menu;
  static const IconData retry = Icons.refresh;
  static const IconData success = Icons.check_circle;
  static const IconData error = Icons.error;
  static const IconData warning = Icons.warning;
  static const IconData quota = Icons.event_available; // For assigned quota
  static const IconData availed = Icons.event_busy; // For availed quota
  static const IconData lapsed = Icons.event_note; // For lapsed quota
  static const IconData available = Icons.event; // For available quota
}

// Theme Configuration
ThemeData getLeaveQuotaTheme() {
  return ThemeData(
    primaryColor: LeaveQuotaColors.primaryColor,
    scaffoldBackgroundColor: LeaveQuotaColors.backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: LeaveQuotaColors.primaryColor, // Blue (30%)
      secondary: LeaveQuotaColors.primaryColor,
      onPrimary: LeaveQuotaColors.backgroundColor, // White (10%)
      onSurface: LeaveQuotaColors.textColor, // Black (10%)
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LeaveQuotaColors.backgroundColor, // White (60%)
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color:
                LeaveQuotaColors.primaryColor.withOpacity(0.3)), // Blue (30%)
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color:
                LeaveQuotaColors.primaryColor.withOpacity(0.3)), // Blue (30%)
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: LeaveQuotaColors.primaryColor, width: 2), // Blue (30%)
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: LeaveQuotaColors.errorColor, width: 1), // Red (temporary)
      ),
      labelStyle: LeaveQuotaTextStyles.label, // Black (10%)
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LeaveQuotaColors.primaryColor, // Blue (30%)
        foregroundColor: LeaveQuotaColors.backgroundColor, // White (10%)
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: LeaveQuotaTextStyles.buttonText, // White (10%)
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentTextStyle: LeaveQuotaTextStyles.snackBarText, // White (10%)
    ),
  );
}
