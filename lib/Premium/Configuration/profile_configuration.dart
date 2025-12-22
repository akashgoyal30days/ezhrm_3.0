import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileConfig {
  // Colors
  static const Color primaryColor = Color(0xFF416CAF);
  static const Color backgroundColor =
      Colors.white; // Changed to specific shade
  static const Color cardColor = Colors.white;
  static const Color errorColor = Colors.red;
  static const Color textColorDark = Colors.black;
  static const Color textColorLight = Colors.white;
  static const Color greyTextColor = Colors.grey;

  // Icons
  static const IconData errorIcon = Icons.error_outline;
  static const IconData menu = Icons.menu;
  static const IconData edit = Icons.edit;
  static const IconData firstNameIcon = Icons.person;
  static const IconData lastNameIcon = Icons.person;
  static const IconData genderIcon = Icons.wc;
  static const IconData dobIcon = Icons.cake;
  static const IconData emailIcon = Icons.email;
  static const IconData phoneIcon = Icons.phone;
  static const IconData joiningDateIcon = Icons.calendar_today;
  static const IconData designationIcon = Icons.account_box;

  // Images
  static const String defaultProfileImage = 'assets/default_profile.png';

  // Text Styles using Google Fonts Poppins
  static TextStyle get appBarTitleStyle => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColorLight,
      );

  static TextStyle get profileNameStyle => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColorLight,
      );

  static TextStyle get employeeCodeStyle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textColorLight.withOpacity(0.9),
      );

  static TextStyle get sectionTitleStyle => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      );

  static TextStyle get fieldLabelStyle => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: greyTextColor,
      );

  static TextStyle get fieldValueStyle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textColorDark,
      );

  static TextStyle get errorTextStyle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: errorColor,
      );

  static TextStyle snackBarText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static TextStyle get buttonTextStyle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textColorLight,
      );

  // Box Shadows
  static List<BoxShadow> get avatarShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ];

  // Decorations
  static BoxDecoration get headerDecoration => const BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      );

  static BoxDecoration get iconContainerDecoration => BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      );

  static BoxDecoration get avatarContainerDecoration => BoxDecoration(
        color: cardColor,
        shape: BoxShape.circle,
        boxShadow: avatarShadow,
      );
}
