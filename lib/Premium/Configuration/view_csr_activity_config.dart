import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ViewCsrActivityConfig {
  // Colors (60-30-10 Rule)
  static const Color primaryColor = Color(0xFF416CAF); // 30% blue
  static const Color backgroundColor = Colors.white; // 60% white
  static const Color textColorLight = Colors.white;
  static const Color textColorDark = Colors.black87; // 10% black
  static const Color darkCardColor = Colors.grey; // Dark theme card background
  static const Color successColor = Colors.green; // Accent for success
  static const Color errorColor = Colors.red; // Accent for errors
  static const Color warningColor = Colors.orange; // Accent for warnings
  static const Color greyIcon = Colors.grey;

  // Icons
  static const IconData menuIcon = Icons.menu;
  static const IconData refreshIcon = Icons.refresh;
  static const IconData lightThemeIcon = Icons.wb_sunny;
  static const IconData darkThemeIcon = Icons.nightlight_round;
  static const IconData volunteerIcon = Icons.volunteer_activism_outlined;
  static const IconData addActivity = Icons.add_photo_alternate;
  static const IconData retry = Icons.refresh;
  static const IconData errorIcon = Icons.error_outline;
  static const IconData warningIcon = Icons.warning;
  static const IconData successIcon = Icons.check_circle;

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

ThemeData getViewCsrActivityTheme(bool isDark) {
  return ThemeData(
    brightness: isDark ? Brightness.dark : Brightness.light,
    primaryColor: ViewCsrActivityConfig.primaryColor,
    scaffoldBackgroundColor: isDark
        ? ViewCsrActivityConfig.darkCardColor
        : ViewCsrActivityConfig.backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: ViewCsrActivityConfig.primaryColor,
      elevation: 0,
      titleTextStyle: ViewCsrActivityConfig.appBarTitleStyle,
      iconTheme: IconThemeData(color: ViewCsrActivityConfig.textColorLight),
    ),
    textTheme: TextTheme(
      headlineSmall: ViewCsrActivityConfig.subheadingStyle.copyWith(
        color: isDark
            ? ViewCsrActivityConfig.textColorLight
            : ViewCsrActivityConfig.textColorDark,
      ),
      bodyMedium: ViewCsrActivityConfig.labelStyle.copyWith(
        color: isDark
            ? ViewCsrActivityConfig.textColorLight
            : ViewCsrActivityConfig.textColorDark,
      ),
      bodySmall: ViewCsrActivityConfig.labelStyle.copyWith(
        fontSize: 14,
        color: isDark
            ? ViewCsrActivityConfig.textColorLight.withOpacity(0.7)
            : ViewCsrActivityConfig.greyIcon,
      ),
      labelMedium: ViewCsrActivityConfig.buttonTextStyle,
      labelSmall: ViewCsrActivityConfig.snackBarTextStyle,
    ),
    iconTheme: IconThemeData(
      color: isDark
          ? ViewCsrActivityConfig.textColorLight
          : ViewCsrActivityConfig.textColorDark,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ViewCsrActivityConfig.primaryColor,
        foregroundColor: ViewCsrActivityConfig.textColorLight,
        textStyle: ViewCsrActivityConfig.buttonTextStyle,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(ViewCsrActivityConfig.borderRadius),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ViewCsrActivityConfig.errorColor,
      contentTextStyle: ViewCsrActivityConfig.snackBarTextStyle,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    cardColor: isDark
        ? ViewCsrActivityConfig.darkCardColor
        : ViewCsrActivityConfig.backgroundColor,
    dividerColor: isDark
        ? ViewCsrActivityConfig.darkCardColor
        : ViewCsrActivityConfig.backgroundColor,
  );
}
