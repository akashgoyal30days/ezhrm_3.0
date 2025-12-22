import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Colors
class ApplyLeaveColors {
  static const Color primaryColor = Color(0xFF416CAF); // 30% blue
  static const Color textColor =
      Colors.black; // 10% black (changed from 0xFF333333)
  static const MaterialColor successColor =
      Colors.green; // Temporary for SnackBars
  static const MaterialColor errorColor = Colors.red; // Temporary for SnackBars
  static const MaterialColor warningColor =
      Colors.orange; // Temporary for SnackBars
  static const Color backgroundColor = Colors.white; // 60% white
}

// Text Styles using Google Fonts Poppins
class ApplyLeaveTextStyles {
  static TextStyle appBarTitle = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    color: ApplyLeaveColors.backgroundColor, // White
  );

  static TextStyle heading = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: ApplyLeaveColors.textColor, // Black
  );

  static TextStyle subheading = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ApplyLeaveColors.primaryColor, // Blue (changed from hintColor)
  );

  static TextStyle label = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: ApplyLeaveColors.textColor, // Black
  );

  static TextStyle dropdownItem = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ApplyLeaveColors.textColor, // Black
  );

  static TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: ApplyLeaveColors.backgroundColor, // White
  );

  static TextStyle snackBarText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ApplyLeaveColors.backgroundColor, // White
  );

  static TextStyle errorText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ApplyLeaveColors.errorColor, // Red (temporary)
  );
}

// Icons
class ApplyLeaveIcons {
  static const IconData menu = Icons.menu;
  static const IconData leaveType = Icons.calendar_today;
  static const IconData creditType = Icons.credit_card;
  static const IconData dateRange = Icons.date_range;
  static const IconData totalDays = Icons.calculate;
  static const IconData reason = Icons.description;
  static const IconData remarks = Icons.note_add;
  static const IconData dropdown = Icons.arrow_drop_down_circle;
  static const IconData submit = Icons.send;
  static const IconData retry = Icons.refresh;
  static const IconData success = Icons.check_circle;
  static const IconData error = Icons.error;
  static const IconData warning = Icons.warning;
  static const IconData add = Icons.add;
}

// Theme Configuration
ThemeData getApplyLeaveTheme() {
  return ThemeData(
    primaryColor: ApplyLeaveColors.primaryColor,
    scaffoldBackgroundColor: ApplyLeaveColors.backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: ApplyLeaveColors.primaryColor, // Blue
      secondary: ApplyLeaveColors.primaryColor,
      onPrimary: ApplyLeaveColors.backgroundColor, // White
      onSurface: ApplyLeaveColors.textColor, // Black
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ApplyLeaveColors.backgroundColor, // White
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: ApplyLeaveColors.primaryColor.withOpacity(0.3)), // Blue
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: ApplyLeaveColors.primaryColor.withOpacity(0.3)), // Blue
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: ApplyLeaveColors.primaryColor, width: 2), // Blue
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: ApplyLeaveColors.errorColor, width: 1), // Red
      ),
      labelStyle: ApplyLeaveTextStyles.label, // Black
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ApplyLeaveColors.primaryColor, // Blue
        foregroundColor: ApplyLeaveColors.backgroundColor, // White
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: ApplyLeaveTextStyles.buttonText, // White
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentTextStyle: ApplyLeaveTextStyles.snackBarText, // White
    ),
  );
}
