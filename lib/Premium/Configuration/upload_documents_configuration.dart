import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadDocumentsConfig {
  // Colors
  static const Color primaryColor = Color(0xFF416CAF);
  static const Color backgroundColor =
      Colors.white; // For shades like grey[100]
  static const Color cardColor = Colors.white;
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;
  static const Color textColorLight = Colors.white;
  static const Color textColorDark = Colors.black;
  static const Color greyTextColor = Colors.grey;

  // Icons
  static const IconData menuIcon = Icons.menu;
  static const IconData uploadFileIcon = Icons.upload_file;
  static const IconData calendarIcon = Icons.calendar_today;
  static const IconData eventIcon = Icons.event;
  static const IconData dropdownIcon = Icons.arrow_drop_down;
  static const IconData imageIcon = Icons.image;
  static const IconData closeIcon = Icons.close;
  static const IconData uploadIcon = Icons.upload;
  static const IconData warning = Icons.warning;

  // Images
  // No static images used in this screen, but you can add them here if needed

  // Text Styles using Google Fonts Poppins
  static TextStyle get appBarTitleStyle => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColorLight,
      );

  static TextStyle get headerTitleStyle => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textColorLight,
      );

  static TextStyle get headerSubtitleStyle => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textColorLight,
      );

  static TextStyle get sectionTitleStyle => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      );

  static TextStyle get fieldValueStyle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textColorDark,
      );

  static TextStyle get errorTextStyle => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: errorColor,
      );

  static TextStyle get placeholderTextStyle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: greyTextColor,
      );

  static TextStyle get buttonTextStyle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textColorLight,
      );

  static TextStyle snackBarText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static TextStyle get elevatedButtonTextStyle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textColorLight,
      );

  // Box Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ];

  // Decorations
  static BoxDecoration get headerDecoration => BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: cardShadow,
      );

  static BoxDecoration get iconContainerDecoration => BoxDecoration(
        color: textColorLight.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      );

  static BoxDecoration get imagePlaceholderDecoration => BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: backgroundColor),
      );

  static BoxDecoration get closeButtonDecoration => BoxDecoration(
        color: cardColor.withOpacity(0.8),
        shape: BoxShape.circle,
      );

  // Input Decoration Theme
  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
        labelStyle: GoogleFonts.poppins(color: greyTextColor),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: primaryColor),
          borderRadius: BorderRadius.circular(8),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      );
}
