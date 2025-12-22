// config.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Colors
class AppColors {
  static const Color primaryColor = Color(0xFF416CAF); // Your blue color
  static const Color headerBackground = Color(0xFF416CAF);
  static const Color textColor = Colors.black87;
  static const Color subTextColor = Colors.grey;
  static const Color iconColor = Colors.grey;
}

// Text Styles
class AppTextStyles {
  static TextStyle menuTitle = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500, // Bold for main menu items
    color: AppColors.textColor,
  );

  static TextStyle subMenuTitle = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500, // Semi-bold for submenu items
    color: AppColors.textColor,
  );

  static TextStyle headerName = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle headerEmail = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );
}

// Icons
class AppIcons {
  static const IconData dashboard = Icons.dashboard;
  static const IconData markAttendance = Icons.fingerprint;
  static const IconData requestAttendance = Icons.request_page;
  static const IconData attendanceHistory = Icons.history;
  static const IconData applyLeave = Icons.event;
  static const IconData leaveStatus = Icons.check_circle;
  static const IconData leaveQuota = Icons.pie_chart;
  static const IconData holidayList = Icons.calendar_today;
  static const IconData workFromHome = Icons.home_work;
  static const IconData compOff = Icons.swap_horiz;
  static const IconData csr = Icons.volunteer_activism;
  static const IconData postActivity = Icons.post_add;
  static const IconData viewActivity = Icons.visibility;
  static const IconData taskManagement = Icons.task;
  static const IconData toDoList = Icons.list;
  static const IconData assignedWork = Icons.assignment;
  static const IconData workReporting = Icons.report;
  static const IconData reimbursement = Icons.attach_money;
  static const IconData advanceSalary = Icons.money;
  static const IconData loan = Icons.account_balance;
  static const IconData salarySlip = Icons.receipt;
  static const IconData uploadDocuments = Icons.upload;
  static const IconData viewDocuments = Icons.visibility;
  static const IconData policies = Icons.policy;
  static const IconData faceRecognition = Icons.face;
  static const IconData feedback = Icons.feedback;
  static const IconData changePassword = Icons.lock;
  static const IconData contactUs = Icons.contact_support;
  static const IconData checkUpdates = Icons.update;
  static const IconData logout = Icons.logout;
  static const IconData person = Icons.person;
}
