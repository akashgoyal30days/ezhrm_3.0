import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AddCompOffConfig {
  // Colors
  static const Color primaryColor =
      Color(0xFF416CAF); // AppBar, button, and icon color
  static const Color textColorWhite = Colors.white;
  static const Color textColorBlack = Colors.black;
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;

  // Icons
  static const IconData menuIcon = Icons.menu;
  static const IconData warning = Icons.warning;
  static const IconData calendarIcon = Icons.calendar_today;
  static const IconData earnedTypeIcon = Icons.category;
  static const IconData hoursEarnedIcon = Icons.hourglass_empty;
  static const IconData dropdownIcon = Icons.arrow_drop_down;
  static const IconData reasonIcon = Icons.description;

  // Text Styles (using GoogleFonts.poppins)
  static TextStyle appBarTitleStyle = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    fontSize: 24,
    color: textColorWhite,
  );

  static TextStyle formTitleStyle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static TextStyle buttonTextStyle = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.bold,
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
      labelStyle: GoogleFonts.poppins(
        fontSize: 16, // Customize font size
        fontWeight: FontWeight.w500, // Customize weight (e.g., medium)
        color: textColorBlack, // Use a color from your config or a custom one
      ),
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
  static ButtonStyle buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  // Spacing
  static const SizedBox formFieldSpacing = SizedBox(height: 16);
  static const SizedBox buttonSpacing = SizedBox(height: 24);
}
