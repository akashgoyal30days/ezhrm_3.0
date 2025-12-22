import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardColors {
  // 60-30-10 Color Scheme
  static const Color backgroundColor = Colors.white; // 60% white
  static const Color primaryColor = Color(0xFF416CAF); // 30% blue
  static const Color textColor = Colors.black87; // 10% black

  // Additional Colors
  static const Color secondaryTextColor =
      Colors.grey; // Avatar fallback, date text
  static const Color warningColor = Colors.orange; // Warnings
  static const Color errorColor = Colors.red; // Errors
}

class DashboardIcons {
  static const IconData menu = Icons.menu;
  static const IconData error = Icons.error_outline;
  static const IconData success = Icons.check_circle;
  static const IconData warning = Icons.warning;
}

class DashboardImages {
  static const String userAvatar = 'assets/images/user.png';
  static const String defaultAvatar = 'assets/default_avatar.png';
}

class DashboardTextStyles {
  static TextStyle appBarTitle = GoogleFonts.poppins(
    color: DashboardColors.backgroundColor,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle greeting = GoogleFonts.poppins(
    color: DashboardColors.primaryColor,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static TextStyle date = GoogleFonts.poppins(
    color: DashboardColors.secondaryTextColor,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle error = GoogleFonts.poppins(
    color: DashboardColors.textColor,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static TextStyle buttonText = GoogleFonts.poppins(
    color: DashboardColors.backgroundColor,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static TextStyle snackBarText = GoogleFonts.poppins(
    color: DashboardColors.backgroundColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}

ThemeData getDashboardTheme() {
  return ThemeData(
    primaryColor: DashboardColors.primaryColor,
    scaffoldBackgroundColor: DashboardColors.backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: DashboardColors.primaryColor,
      elevation: 0,
      titleTextStyle: DashboardTextStyles.appBarTitle,
      iconTheme: const IconThemeData(color: DashboardColors.backgroundColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DashboardColors.primaryColor,
        foregroundColor: DashboardColors.backgroundColor,
        textStyle: DashboardTextStyles.buttonText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textTheme: TextTheme(
      bodyMedium: DashboardTextStyles.error,
      titleLarge: DashboardTextStyles.appBarTitle,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: DashboardColors.errorColor,
      contentTextStyle: DashboardTextStyles.snackBarText,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
