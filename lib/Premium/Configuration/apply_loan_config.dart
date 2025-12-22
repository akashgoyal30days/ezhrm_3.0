import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ApplyLoanColors {
  // 60-30-10 Color Scheme
  static const Color backgroundColor = Colors.white; // 60% white
  static const Color primaryColor = Color(0xFF416CAF); // 30% blue
  static const Color textColor = Colors.black87; // 10% black

  // Status Colors
  static const Color warningColor = Colors.orange; // Pending status
  static const Color errorColor = Colors.red; // Rejected status, errors
}

class ApplyLoanIcons {
  static const IconData menu = Icons.menu;
  static const IconData retry = Icons.refresh;
  static const IconData add = Icons.add;
  static const IconData info = Icons.info_outline;
  static const IconData error = Icons.error;
  static const IconData success = Icons.check_circle;
  static const IconData warning = Icons.warning;
}

class ApplyLoanTextStyles {
  static TextStyle appBarTitle = GoogleFonts.poppins(
    color: ApplyLoanColors.backgroundColor,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle label = GoogleFonts.poppins(
    color: ApplyLoanColors.textColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle subheading = GoogleFonts.poppins(
    color: ApplyLoanColors.textColor,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static TextStyle buttonText = GoogleFonts.poppins(
    color: ApplyLoanColors.backgroundColor,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static TextStyle snackBarText = GoogleFonts.poppins(
    color: ApplyLoanColors.backgroundColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}

ThemeData getApplyLoanTheme() {
  return ThemeData(
    primaryColor: ApplyLoanColors.primaryColor,
    scaffoldBackgroundColor: ApplyLoanColors.backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: ApplyLoanColors.primaryColor,
      elevation: 0,
      titleTextStyle: ApplyLoanTextStyles.appBarTitle,
      iconTheme: const IconThemeData(color: ApplyLoanColors.backgroundColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ApplyLoanColors.primaryColor,
        foregroundColor: ApplyLoanColors.backgroundColor,
        textStyle: ApplyLoanTextStyles.buttonText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: ApplyLoanColors.primaryColor,
      foregroundColor: ApplyLoanColors.backgroundColor,
    ),
    textTheme: TextTheme(
      bodyMedium: ApplyLoanTextStyles.label,
      titleLarge: ApplyLoanTextStyles.appBarTitle,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ApplyLoanColors.errorColor,
      contentTextStyle: ApplyLoanTextStyles.snackBarText,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
