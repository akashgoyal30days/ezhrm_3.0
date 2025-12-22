import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ViewDocumentsConfig {
  // Colors (60-30-10 Rule)
  static const Color primaryColor = Color(0xFF416CAF); // 30% blue
  static const Color backgroundColor = Colors.white; // 60% white
  static const Color textColorLight = Colors.white;
  static const Color textColorDark = Colors.black; // 10% black
  static const Color errorColor = Colors.red; // Accent
  static const Color successColor = Color(0xFF416CAF); // Accent
  static const Color pendingColor = Colors.orange; // Blue shade for 30% blue
  static const Color unknownColor = Colors.grey; // Accent
  static const Color warningColor = Colors.orange; // Accent for token errors

  // Icons
  static const IconData menuIcon = Icons.menu;
  static const IconData refreshIcon = Icons.refresh;
  static const IconData emptyIcon = Icons.folder_open;
  static const IconData errorIcon = Icons.error_outline;
  static const IconData successIcon = Icons.check_circle;
  static const IconData warningIcon = Icons.warning;
  static const IconData noImageIcon = Icons.image_not_supported;
  static const IconData documentIcon = Icons.edit_document;

  // Text Styles
  static TextStyle get appBarTitleStyle => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColorLight,
      );

  static TextStyle get snackBarTextStyle => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColorLight,
      );

  static TextStyle get chipTextStyle => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColorLight,
      );

  static TextStyle get imageErrorStyle => GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.normal,
        color: textColorDark,
      );
}
