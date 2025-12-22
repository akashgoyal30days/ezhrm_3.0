import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AssignedWorkConfig {
  // Colors (60-30-10 Rule)
  static const Color primaryColor = Color(0xFF416CAF); // 30% blue
  static const Color backgroundColor = Colors.white; // 60% white
  static const Color textColorLight = Colors.white;
  static const Color textColorDark = Colors.black87; // 10% black
  static const Color successColor = Color(0xFF416CAF); // Accent for completed
  static const Color errorColor = Colors.red; // Accent for overdue
  static const Color warningColor = Colors.red; // Accent for pending
  static const Color inProgressColor = Colors.orange; // Accent for in progress

  // Icons
  static const IconData menuIcon = Icons.menu;
  static const IconData errorIcon = Icons.error_outline;
  static const IconData successIcon = Icons.check_circle;
  static const IconData warningIcon = Icons.warning;
  static const IconData refreshIcon = Icons.refresh;

  // Text Styles
  static TextStyle get appBarTitle => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColorLight,
      );

  static TextStyle get label => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textColorDark,
      );

  static TextStyle get statusText => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColorLight,
      );

  static TextStyle get subheading => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColorDark,
      );

  static TextStyle get snackBarText => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColorLight,
      );

  static TextStyle get buttonText => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColorLight,
      );

  // Card Configuration
  static const double cardElevation = 3.0;

  // Status Color Mapping
  static Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return successColor;
      case 'in progress':
        return inProgressColor;
      case 'pending':
        return warningColor;
      case 'overdue':
        return errorColor;
      default:
        return Colors.grey;
    }
  }
}

ThemeData getAssignedWorkTheme() {
  return ThemeData(
    primaryColor: AssignedWorkConfig.primaryColor,
    scaffoldBackgroundColor: AssignedWorkConfig.backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: AssignedWorkConfig.primaryColor,
      elevation: 0,
      titleTextStyle: AssignedWorkConfig.appBarTitle,
      iconTheme: IconThemeData(color: AssignedWorkConfig.textColorLight),
    ),
    textTheme: TextTheme(
      headlineSmall: AssignedWorkConfig.subheading,
      bodyMedium: AssignedWorkConfig.label,
      labelSmall: AssignedWorkConfig.statusText,
      labelMedium: AssignedWorkConfig.buttonText,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AssignedWorkConfig.primaryColor,
        foregroundColor: AssignedWorkConfig.textColorLight,
        textStyle: AssignedWorkConfig.buttonText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AssignedWorkConfig.errorColor,
      contentTextStyle: AssignedWorkConfig.snackBarText,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
