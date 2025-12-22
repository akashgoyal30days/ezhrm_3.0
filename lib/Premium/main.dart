// import 'dart:convert';
// import 'dart:io';
// import 'package:ezhrm/Attendance/Attendance%20history/bloc/attendance_history_bloc.dart';
// import 'package:ezhrm/Attendance/Attendance%20history/screen/attendance_history_screen.dart';
// import 'package:ezhrm/Attendance/Get%20Today%20Attendance/bloc/get_today_attendance_bloc.dart';
// import 'package:ezhrm/Attendance/Week_Off/bloc/week_off_bloc.dart';
// import 'package:ezhrm/Attendance/geoLocation/geo_location_bloc.dart';
// import 'package:ezhrm/Attendance/mark%20attendance/bloc/mark_attendance_bloc.dart';
// import 'package:ezhrm/Attendance/req_past_attendance/bloc/req_past_attendance_bloc.dart';
// import 'package:ezhrm/Attendance/req_past_attendance/screen/ReqPastAttendanceScreen.dart'
//     hide RequestAttendanceScreen;
// import 'package:ezhrm/CSR/View_status/bloc/view_activity_status_bloc.dart';
// import 'package:ezhrm/CSR/View_status/screen/view_csr_activity_status_detail_screen.dart';
// import 'package:ezhrm/CSR/post%20activity/bloc/post_csr_activity_bloc.dart';
// import 'package:ezhrm/CSR/view%20activity/screen/view_csr_activity_screen.dart';
// import 'package:ezhrm/CSR/view%20activity/screen/view_csr_detail_screen.dart';
// import 'package:ezhrm/Comp%20off/add%20comp%20off/screen/add_comp_off.dart';
// import 'package:ezhrm/Contact%20Us/bloc/contact_us_bloc.dart';
// import 'package:ezhrm/Contact%20Us/screen/contact_us.dart';
// import 'package:ezhrm/Documents/upload_documents/screen/upload_documents.dart';
// import 'package:ezhrm/Documents/view_documents/screen/view_document.dart';
// import 'package:ezhrm/Feedback/bloc/feedback_bloc.dart';
// import 'package:ezhrm/Get%20Permissions/bloc/get_permission_bloc.dart';
// import 'package:ezhrm/Get%20Role%20Permissions/bloc/get_role_permission_bloc.dart';
// import 'package:ezhrm/Holiday/screen/holiday_screen.dart';
// import 'package:ezhrm/Payslip/bloc/get_pay_slip_bloc.dart';
// import 'package:ezhrm/Payslip/screen/GetPaySlip.dart';
// import 'package:ezhrm/Policy/screen/policy_screen.dart';
// import 'package:ezhrm/SessionHandling/session_bloc.dart';
// import 'package:ezhrm/Task_management/to_do_list/bloc/to_do_list_bloc.dart';
// import 'package:ezhrm/Task_management/to_do_list/screen/to_do_screen.dart';
// import 'package:ezhrm/Task_management/work_reporting/bloc/work_reporting_bloc.dart';
// import 'package:ezhrm/Tracking%20Location/bloc/tracking_location_bloc.dart';
// import 'package:ezhrm/advance%20salary/bloc/advance_salary_bloc.dart';
// import 'package:ezhrm/advance%20salary/screen/advance_salary_screen.dart';
// import 'package:ezhrm/apply%20loan/bloc/apply_loan_bloc.dart';
// import 'package:ezhrm/apply%20loan/screen/apply_loan.dart';
// import 'package:ezhrm/apply%20loan/screen/show_apply_loan.dart';
// import 'package:ezhrm/change%20password/bloc/change_password_bloc.dart';
// import 'package:ezhrm/change%20password/screen/change_password.dart';
// import 'package:ezhrm/dashboard/bloc/dashboard_bloc.dart';
// import 'package:ezhrm/dashboard/screen/dashboard.dart';
// import 'package:ezhrm/feedback/feedback_screen.dart';
// import 'package:ezhrm/leave/Apply%20leave/screen/apply_leave.dart';
// import 'package:ezhrm/leave/Employee%20Leave_quota/screen/leave_quota_screen.dart';
// import 'package:ezhrm/leave/Leave%20status/screen/leave_status_screen.dart';
// import 'package:ezhrm/notification.dart';
// import 'package:ezhrm/policy/bloc/policy_bloc.dart';
// import 'package:ezhrm/profile/show_user_profile/bloc/profile_bloc.dart';
// import 'package:ezhrm/profile/update_user_profile/bloc/update_user_profile_bloc.dart';
// import 'package:ezhrm/profile/update_user_profile/screen/update_user_profile.dart';
// import 'package:ezhrm/reimbursement/bloc/reimbursement_bloc.dart';
// import 'package:ezhrm/reimbursement/get%20expense%20bloc/get_expense_bloc.dart';
// import 'package:ezhrm/reimbursement/get_customers_bloc/get_customers_bloc.dart';
// import 'package:ezhrm/reimbursement/screen/reinbursement_screen.dart';
// import 'package:ezhrm/reimbursement/screen/show_reimbursement_history.dart';
// import 'package:ezhrm/splash_screen.dart';
// // import 'package:ezhrm/splash_screen.dart';
// // import 'package:ezhrm/splash_screen.dart';
// import 'package:ezhrm/work%20from%20home/bloc/work_from_home_bloc.dart';
// import 'package:ezhrm/work%20from%20home/screen/show_wfh.dart';
// import 'package:ezhrm/work%20from%20home/screen/work_from_home.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:ezhrm/Authentication/bloc/auth_bloc.dart';
// import 'package:ezhrm/Authentication/screen/login_screen.dart';
// // import 'package:ezhrm/dependency_injection/dependency_injection.dart';
// import 'package:ezhrm/documents/upload_documents/bloc/upload_documents_bloc.dart';
// import 'package:ezhrm/holiday/bloc/holiday_bloc.dart';
// import 'package:ezhrm/Authentication/User%20Information/user_details.dart';
// import 'package:ezhrm/Authentication/User%20Information/user_session.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:workmanager/workmanager.dart';
// import 'Attendance/Request Today Attendance/bloc/req_today_attendance_bloc.dart';
// import 'Attendance/Request Today Attendance/screen/ReqAttendanceScreen.dart';
// import 'CSR/View_status/screen/view_csr_activity_status_screen.dart';
// import 'CSR/post activity/screen/post_activity.dart';
// import 'CSR/view activity/bloc/view_csr_activity_bloc.dart';
// import 'Comp off/add comp off/bloc/add_comp_off_bloc.dart';
// import 'Comp off/show_comp_off/bloc/show_comp_off_bloc.dart';
// import 'Comp off/show_comp_off/screen/comp_off_history.dart';
// import 'Documents/Get Document Type/bloc/get_document_type_bloc.dart';
// import 'Documents/view_documents/bloc/view_doucments_bloc.dart';
// import 'Face Recognition/upload images/bloc/upload_images_bloc.dart';
// import 'Face Recognition/upload_image_status/bloc/upload_image_status_bloc.dart';
// import 'Fetch Notification/fetch_notification_bloc.dart';
// import 'Task_management/assigned_work/bloc/assigned_work_bloc.dart';
// // import 'dashboard/splash_screen.dart';
// import 'Task_management/assigned_work/screen/assigned_work_screen.dart';
// import 'Task_management/work_reporting/screen_1/work_reporting_screen.dart';
// import 'fcm_service.dart';
// import 'firebase_options.dart';
// import 'leave/Apply leave/bloc/apply_leave_bloc.dart';
// import 'leave/Employee Leave_quota/bloc/leave_quota_bloc.dart';
// import 'leave/Get Leave Types/bloc/get_leave_quota_bloc.dart';
// import 'leave/Leave status/bloc/leave_status_bloc.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   // Initialize FCM and request/send token
//   await FcmService.initialize();
//   await initializeNotifications();
//   setupDependencies();
//   final prefs = await SharedPreferences.getInstance();
//   bool isWorkmanagerInitialized =
//       prefs.getBool('workmanager_initialized') ?? false;
//
//   if (!isWorkmanagerInitialized) {
//     print(
//         'Work manager is not initialized.setting the local storage value to true');
//     await Workmanager().initialize(
//       callbackDispatcher, // Your top-level callbackDispatcher function
//       isInDebugMode: false, // Set to true for debugging
//     );
//     prefs.setBool('workmanager_initialized', true);
//   } else {
//     print('Main function: Work manager is already initialized');
//   }
//   runApp(MyApp());
// }
