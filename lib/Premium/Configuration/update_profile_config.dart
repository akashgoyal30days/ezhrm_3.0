import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class UpdateProfileConfig {
  // Colors
  static const Color primaryColor = Color(0xFF416CAF); // AppBar, buttons, icons
  static const Color textColorWhite = Colors.white;
  static const Color textColorBlack = Colors.black;
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color greyBackground = Color(0xFFF5F5F5); // Colors.grey[100]
  static const Color greyLight = Color(0xFFE0E0E0); // Colors.grey[200]
  static const Color greyBorder = Color(0xFFB0BEC5); // Colors.grey[300]
  static const Color greyIcon = Color(0xFF90A4AE); // Colors.grey[400]
  static const Color shadowColor = Colors.black;

  // Icons
  static const IconData menuIcon = Icons.menu;
  static const IconData personIcon = Icons.person;
  static const IconData calendarIcon = Icons.calendar_today;
  static const IconData phoneIcon = Icons.phone;
  static const IconData dropdownIcon = Icons.arrow_drop_down;
  static const IconData imageIcon = Icons.image;
  static const IconData uploadIcon = Icons.upload;
  static const IconData closeIcon = Icons.close;

  // Text Styles (using GoogleFonts.poppins)
  static TextStyle appBarTitleStyle = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    color: textColorWhite,
  );

  static TextStyle headerTitleStyle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textColorWhite,
  );

  static TextStyle headerSubtitleStyle = GoogleFonts.poppins(
    fontSize: 14,
    color: textColorWhite,
  );

  static TextStyle cardTitleStyle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static TextStyle noImageStyle = GoogleFonts.poppins(
    fontSize: 16,
    color: greyIcon,
  );

  static TextStyle buttonTextStyle = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textColorWhite,
  );

  static TextStyle uploadButtonLabelStyle = GoogleFonts.poppins(
    color: textColorWhite,
  );

  static TextStyle snackBarText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  // Date Format
  static final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

  // Input Decoration
  static InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      prefixIcon: Icon(icon, color: primaryColor),
    );
  }

  // Card Configuration
  static const double cardElevation = 4.0;
  static const BorderRadius cardBorderRadius =
      BorderRadius.all(Radius.circular(12));
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);

  // Button Configuration
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(
        vertical: 12, horizontal: 120), // Controls width via padding
    elevation: 4,
  );

  static ButtonStyle uploadButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(vertical: 12),
    minimumSize: const Size(double.infinity, 50),
  );

  // Spacing
  static const SizedBox formFieldSpacing = SizedBox(height: 16);
  static const SizedBox buttonSpacing = SizedBox(height: 24);

  // Box Shadows
  static List<BoxShadow> headerShadow = [
    BoxShadow(
      color: shadowColor.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 5),
    ),
  ];

  // Decorations
  static BoxDecoration headerDecoration = BoxDecoration(
    color: primaryColor,
    borderRadius: cardBorderRadius,
    boxShadow: headerShadow,
  );

  static BoxDecoration imagePlaceholderDecoration = BoxDecoration(
    color: greyLight,
    borderRadius: cardBorderRadius,
    border: Border.all(color: greyBorder),
  );

  static BoxDecoration imageIconContainerDecoration = BoxDecoration(
    color: textColorWhite.withOpacity(0.2),
    borderRadius: BorderRadius.circular(8),
  );

  static BoxDecoration closeButtonDecoration = BoxDecoration(
    color: textColorWhite.withOpacity(0.8),
    shape: BoxShape.circle,
  );
}
