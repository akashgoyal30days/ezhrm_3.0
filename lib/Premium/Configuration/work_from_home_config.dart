import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class WorkFromHomeConfig {
  // Colors (60% white, 30% blue, 10% black)
  static const Color primaryColor = Color(0xFF416CAF); // 30% blue
  static const Color backgroundColor = Colors.white; // 60% white
  static const Color textColorLight = Colors.white;
  static const Color textColorDark = Colors.black; // 10% black
  static const Color errorColor = Colors.red;
  static const Color successColor = Color(0xFF416CAF);
  static const Color warningColor = Colors.orange;

  // Icons
  static const IconData menuIcon = Icons.menu;
  static const IconData calendarIcon = Icons.calendar_today;
  static const IconData reasonIcon = Icons.description;
  static const IconData successIcon = Icons.check_circle;
  static const IconData errorIcon = Icons.error_outline;
  static const IconData warningIcon = Icons.warning;

  // Typography
  static final TextStyle appBarTitleStyle = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textColorLight,
  );

  static final TextStyle subheadingTextStyle = GoogleFonts.poppins(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: textColorDark,
  );

  static final TextStyle buttonTextStyle = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textColorLight,
  );

  static final TextStyle snackBarTextStyle = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textColorLight,
  );

  static final TextStyle labelTextStyle = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textColorDark,
  );

  // Date Format
  static final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

  // Card Elevation
  static const double cardElevation = 4.0;

  // Input Decoration
  static InputDecoration inputDecoration(
      String label, IconData icon, double baseFontSize) {
    return InputDecoration(
      labelText: label,
      labelStyle: labelTextStyle.copyWith(fontSize: baseFontSize * 0.9),
      prefixIcon: Icon(
        icon,
        color: primaryColor,
        size: baseFontSize * 1.2,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(baseFontSize * 0.5),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(baseFontSize * 0.5),
        borderSide: BorderSide(color: primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(baseFontSize * 0.5),
        borderSide: BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(baseFontSize * 0.5),
        borderSide: BorderSide(color: errorColor),
      ),
      contentPadding: EdgeInsets.symmetric(
        vertical: baseFontSize * 0.75,
        horizontal: baseFontSize,
      ),
    );
  }
}
