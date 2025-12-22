import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginConfig {
  // Colors
  static const Color primaryColor =
      Color(0xFF416CAF); // Updated to requested color
  static const Color secondaryColor =
      Color(0xFF1E3A70); // Darker shade for gradient
  static const Color accentColor = Color(0xFF64B5F6); // Light blue accent
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Colors.black;
  static const Color subtitleColor =
      Color(0xFF757575); // Darker grey for better contrast
  static const Color buttonTextColor = Colors.white;
  static const Color errorColor = Color(0xFFE53935); // Slightly softer red

  // Text Styles
  static TextStyle titleStyle = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    letterSpacing: 0.5,
  );

  static TextStyle subtitleStyle = GoogleFonts.poppins(
    fontSize: 16,
    color: subtitleColor,
    letterSpacing: 0.3,
  );

  static TextStyle buttonTextStyle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: buttonTextColor,
    letterSpacing: 0.5,
  );

  static TextStyle forgotPasswordStyle = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: primaryColor,
    decoration: TextDecoration.underline,
    decorationThickness: 1.5,
  );

  static TextStyle snackBarText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  // Image Paths
  static const String appLogo = 'assets/images/ezhrmlogo.webp';

  // Icons
  static const IconData usernameIcon = Icons.person_outline;
  static const IconData passwordIcon = Icons.lock_outline;
  static const IconData error = Icons.error_outline;
  static const IconData visibility = Icons.visibility;
  static const IconData arrow = Icons.arrow_forward;
  static const IconData visibilityOff = Icons.visibility_off;
  static const IconData errorImageIcon = Icons.image_not_supported;
}
