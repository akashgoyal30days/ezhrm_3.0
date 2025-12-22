import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ToDoListConfig {
  // Colors (60-30-10 Rule)
  static const Color primaryColor = Color(0xFF416CAF); // 30% blue
  static const Color backgroundColor = Colors.white; // 60% white
  static const Color textColorLight = Colors.white;
  static const Color textColorDark = Colors.black; // 10% black
  static const Color successColor = Color(0xFF416CAF); // Accent
  static const Color errorColor = Colors.red; // Accent
  static const Color warningColor = Colors.orange; // Accent for token errors
  static const Color pendingColor =
      Colors.orange; // Blue-grey for pending status

  // Icons
  static const IconData menuIcon = Icons.menu;
  static const IconData taskIcon = Icons.task_alt;
  static const IconData successIcon = Icons.check_circle;
  static const IconData errorIcon = Icons.error_outline;
  static const IconData warningIcon = Icons.warning;
  static const IconData refreshIcon = Icons.refresh;

  // Text Styles
  static TextStyle get appBarTitleStyle => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColorLight,
      );

  static TextStyle get taskTitleStyle => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryColor, // 30% blue
      );

  static TextStyle get chipTextStyle => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColorLight,
      );

  static TextStyle get snackBarTextStyle => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColorLight,
      );

  static TextStyle get errorTextStyle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColorDark, // 10% black
      );

  static TextStyle get emptyTextStyle => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColorDark, // 10% black
      );

  // Card Configuration
  static const double cardElevation = 3.0;

  // Status Color Mapping
  static Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return successColor;
      case 'pending':
        return pendingColor;
      case 'overdue':
        return errorColor;
      default:
        return pendingColor;
    }
  }
}
