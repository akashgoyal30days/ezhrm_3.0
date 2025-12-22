import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PostCsrActivityConfig {
  // Colors (60-30-10 Rule)
  static const Color primaryColor = Color(0xFF416CAF); // 30% blue
  static const Color backgroundColor = Colors.white; // 60% white
  static const Color textColorLight = Colors.white;
  static const Color textColorDark = Colors.black87; // 10% black
  static const Color successColor = Colors.green; // Accent for success
  static const Color errorColor = Colors.red; // Accent for errors
  static const Color warningColor = Colors.orange; // Accent for warnings
  static const Color greyIcon = Colors.grey;

  // Icons
  static const IconData menuIcon = Icons.menu;
  static const IconData descriptionIcon = Icons.description;
  static const IconData imageIcon = Icons.image;
  static const IconData uploadIcon = Icons.upload;
  static const IconData submitIcon = Icons.send;
  static const IconData successIcon = Icons.check_circle;
  static const IconData errorIcon = Icons.error_outline;
  static const IconData warningIcon = Icons.warning;
  static const IconData closeIcon = Icons.close;

  // Text Styles
  static TextStyle get appBarTitleStyle => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColorLight,
      );

  static TextStyle get labelStyle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textColorDark,
      );

  static TextStyle get subheadingStyle => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColorDark,
      );

  static TextStyle get snackBarTextStyle => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColorLight,
      );

  static TextStyle get buttonTextStyle => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColorLight,
      );

  static TextStyle get noImageStyle => GoogleFonts.poppins(
        fontSize: 14,
        color: greyIcon,
      );

  static TextStyle get errorTextStyle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textColorDark,
      );

  // Box Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ];

  // Border Radius
  static const double borderRadius = 12.0;
}

ThemeData getPostCsrActivityTheme() {
  return ThemeData(
    primaryColor: PostCsrActivityConfig.primaryColor,
    scaffoldBackgroundColor: PostCsrActivityConfig.backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: PostCsrActivityConfig.primaryColor,
      elevation: 0,
      titleTextStyle: PostCsrActivityConfig.appBarTitleStyle,
      iconTheme: IconThemeData(color: PostCsrActivityConfig.textColorLight),
    ),
    textTheme: TextTheme(
      headlineSmall: PostCsrActivityConfig.subheadingStyle,
      bodyMedium: PostCsrActivityConfig.labelStyle,
      labelMedium: PostCsrActivityConfig.buttonTextStyle,
      labelSmall: PostCsrActivityConfig.snackBarTextStyle,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PostCsrActivityConfig.primaryColor,
        foregroundColor: PostCsrActivityConfig.textColorLight,
        textStyle: PostCsrActivityConfig.buttonTextStyle,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(PostCsrActivityConfig.borderRadius),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: PostCsrActivityConfig.errorColor,
      contentTextStyle: PostCsrActivityConfig.snackBarTextStyle,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PostCsrActivityConfig.borderRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PostCsrActivityConfig.borderRadius),
        borderSide: BorderSide(
          color: PostCsrActivityConfig.primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PostCsrActivityConfig.borderRadius),
        borderSide: BorderSide(
          color: PostCsrActivityConfig.errorColor,
          width: 1,
        ),
      ),
      filled: true,
      fillColor: PostCsrActivityConfig.backgroundColor,
      labelStyle: PostCsrActivityConfig.labelStyle,
    ),
  );
}
