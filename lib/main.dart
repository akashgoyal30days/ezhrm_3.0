import 'package:ezhrm/Premium/firebase_options.dart';
import 'package:ezhrm/premium_app_entry.dart';
import 'package:ezhrm/standard_app_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'Premium/fcm_service.dart';
import 'Premium/notification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Premium/Dependency_Injection/dependency_injection.dart';
import 'Premium/premium_version_routes.dart';
import 'Premium/premium_version_theme.dart';
import 'app_selector_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Premium/Documents/Get Document Type/bloc/get_document_type_bloc.dart';
import 'Premium/Documents/upload_documents/bloc/upload_documents_bloc.dart';
import 'Premium/Documents/view_documents/bloc/view_doucments_bloc.dart';
import 'Premium/Face Recognition/upload images/bloc/upload_images_bloc.dart';
import 'Premium/Face Recognition/upload_image_status/bloc/upload_image_status_bloc.dart';
import 'Premium/Fetch Notification/fetch_notification_bloc.dart';
import 'Premium/Get Permissions/bloc/get_permission_bloc.dart';
import 'Premium/Get Role Permissions/bloc/get_role_permission_bloc.dart';
import 'Premium/Holiday/bloc/holiday_bloc.dart';
import 'Premium/Contact Us/bloc/contact_us_bloc.dart';
import 'Premium/work from home/bloc/work_from_home_bloc.dart';
import 'Premium/feedback/bloc/feedback_bloc.dart';
import 'Premium/leave/Apply leave/bloc/apply_leave_bloc.dart';
import 'Premium/leave/Employee Leave_quota/bloc/leave_quota_bloc.dart';
import 'Premium/leave/Get Leave Types/bloc/get_leave_quota_bloc.dart';
import 'Premium/leave/Leave status/bloc/leave_status_bloc.dart';
import 'Premium/profile/show_user_profile/bloc/profile_bloc.dart';
import 'Premium/profile/update_user_profile/bloc/update_user_profile_bloc.dart';
import 'Premium/reimbursement/bloc/reimbursement_bloc.dart';
import 'Premium/reimbursement/get expense bloc/get_expense_bloc.dart';
import 'Premium/reimbursement/get_customers_bloc/get_customers_bloc.dart';
import 'Premium/Payslip/bloc/get_pay_slip_bloc.dart';
import 'Premium/Policy/bloc/policy_bloc.dart';
import 'Premium/SessionHandling/session_bloc.dart';
import 'Premium/Task_management/assigned_work/bloc/assigned_work_bloc.dart';
import 'Premium/Task_management/to_do_list/bloc/to_do_list_bloc.dart';
import 'Premium/Task_management/work_reporting/bloc/work_reporting_bloc.dart';
import 'Premium/Tracking Location/bloc/tracking_location_bloc.dart';
import 'Premium/advance salary/bloc/advance_salary_bloc.dart';
import 'Premium/apply loan/bloc/apply_loan_bloc.dart';
import 'Premium/change password/bloc/change_password_bloc.dart';
import 'Premium/Attendance/Attendance history/bloc/attendance_history_bloc.dart';
import 'Premium/Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import 'Premium/Attendance/Request Today Attendance/bloc/req_today_attendance_bloc.dart';
import 'Premium/Attendance/Week_Off/bloc/week_off_bloc.dart';
import 'Premium/Attendance/geoLocation/geo_location_bloc.dart';
import 'Premium/Attendance/mark attendance/bloc/mark_attendance_bloc.dart';
import 'Premium/Attendance/req_past_attendance/bloc/req_past_attendance_bloc.dart';
import 'Premium/Authentication/bloc/auth_bloc.dart';
import 'Premium/CSR/View_status/bloc/view_activity_status_bloc.dart';
import 'Premium/CSR/post activity/bloc/post_csr_activity_bloc.dart';
import 'Premium/Comp off/add comp off/bloc/add_comp_off_bloc.dart';
import 'Premium/Comp off/show_comp_off/bloc/show_comp_off_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 1. Start Firebase init (often the slowest)
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {}
  // 2. Start FCM init in parallel
  try {
    final fcmFuture = FcmService.initialize();
  } catch (e) {}
  // 3. Local notifications in parallel
  try {
    final notificationsFuture = initializeNotifications();
  } catch (e) {}
  // Await all parallels at once
  // await Future.wait([
  //   fcmFuture,
  //   notificationsFuture,
  // ]);
  runApp(const AppRouter());
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  Future<String?> _getSelectedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint('new changes');
    return prefs.getString('app_version');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getSelectedVersion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF416CAF),
                ),
              ),
            ),
          );
        }

        final version = snapshot.data ?? '';

        // If no version selected → show selector
        if (version.isEmpty) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: AppSelectorScreen(),
          );
        }

        // PREMIUM VERSION (New) — uses named routes + RouteObserver
        if (version == 'new') {
          final DebugRouteObserver debugRouteObserver = DebugRouteObserver();

          return MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>(create: (context) => getIt<AuthBloc>()),
                BlocProvider<ViewDocumentsBloc>(
                  create: (context) => getIt<ViewDocumentsBloc>(),
                ),
                BlocProvider<GetDocumentTypeBloc>(
                  create: (context) => getIt<GetDocumentTypeBloc>(),
                ),
                BlocProvider<HolidayBloc>(
                  create: (context) => getIt<HolidayBloc>(),
                ),
                BlocProvider<ContactUsBloc>(
                  create: (context) => getIt<ContactUsBloc>(),
                ),
                BlocProvider<ToDoListBloc>(
                  create: (context) => getIt<ToDoListBloc>(),
                ),
                BlocProvider<AssignedWorkBloc>(
                  create: (context) => getIt<AssignedWorkBloc>(),
                ),
                BlocProvider<AdvanceSalaryBloc>(
                  create: (context) => getIt<AdvanceSalaryBloc>(),
                ),
                BlocProvider<ApplyLoanBloc>(
                  create: (context) => getIt<ApplyLoanBloc>(),
                ),
                BlocProvider<LeaveStatusBloc>(
                  create: (context) => getIt<LeaveStatusBloc>(),
                ),
                BlocProvider<UploadDocumentsBloc>(
                  create: (context) => getIt<UploadDocumentsBloc>(),
                ),
                BlocProvider<UpdateUserProfileBloc>(
                  create: (context) => getIt<UpdateUserProfileBloc>(),
                ),
                BlocProvider<AddCompOffBloc>(
                  create: (context) => getIt<AddCompOffBloc>(),
                ),
                BlocProvider<ShowCompOffBloc>(
                  create: (context) => getIt<ShowCompOffBloc>(),
                ),
                BlocProvider<WorkFromHomeBloc>(
                  create: (context) => getIt<WorkFromHomeBloc>(),
                ),
                BlocProvider<PolicyBloc>(
                  create: (context) => getIt<PolicyBloc>(),
                ),
                BlocProvider<GetLeaveQuotaBloc>(
                  create: (context) => getIt<GetLeaveQuotaBloc>(),
                ),
                BlocProvider<WeekOffBloc>(
                  create: (context) => getIt<WeekOffBloc>(),
                ),
                BlocProvider<ViewActivityStatusBloc>(
                  create: (context) => getIt<ViewActivityStatusBloc>(),
                ),
                BlocProvider<ApplyLeaveBloc>(
                  create: (context) => getIt<ApplyLeaveBloc>(),
                ),
                BlocProvider<ChangePasswordBloc>(
                  create: (context) => getIt<ChangePasswordBloc>(),
                ),
                BlocProvider<PostCsrActivityBloc>(
                  create: (context) => getIt<PostCsrActivityBloc>(),
                ),
                BlocProvider<UploadImagesBloc>(
                  create: (context) => getIt<UploadImagesBloc>(),
                ),
                BlocProvider<ReimbursementBloc>(
                  create: (context) => getIt<ReimbursementBloc>(),
                ),
                BlocProvider<GetTodayAttendanceLogsBloc>(
                  create: (context) => getIt<GetTodayAttendanceLogsBloc>(),
                ),
                BlocProvider<ReqPastAttendanceBloc>(
                  create: (context) => getIt<ReqPastAttendanceBloc>(),
                ),
                BlocProvider<MarkAttendanceBloc>(
                  create: (context) => getIt<MarkAttendanceBloc>(),
                ),
                BlocProvider<TrackingLocationBloc>(
                  create: (context) => getIt<TrackingLocationBloc>(),
                ),
                BlocProvider<FetchNotificationBloc>(
                  create: (context) => getIt<FetchNotificationBloc>(),
                ),
                BlocProvider<LeaveQuotaBloc>(
                  create: (context) => getIt<LeaveQuotaBloc>(),
                ),
                BlocProvider<WorkReportingBloc>(
                  create: (context) => getIt<WorkReportingBloc>(),
                ),
                BlocProvider<AttendanceHistoryBloc>(
                  create: (context) => getIt<AttendanceHistoryBloc>(),
                ),
                BlocProvider<ProfileBloc>(
                  create: (context) => getIt<ProfileBloc>(),
                ),
                BlocProvider<GetPermissionBloc>(
                  create: (context) => getIt<GetPermissionBloc>(),
                ),
                BlocProvider<GetRolePermissionBloc>(
                  create: (context) => getIt<GetRolePermissionBloc>(),
                ),
                BlocProvider<GetExpenseBloc>(
                  create: (context) => getIt<GetExpenseBloc>(),
                ),
                BlocProvider<GetCustomersBloc>(
                  create: (context) => getIt<GetCustomersBloc>(),
                ),
                BlocProvider<UploadImageStatusBloc>(
                  create: (context) => getIt<UploadImageStatusBloc>(),
                ),
                BlocProvider<GeoLocationBloc>(
                  create: (context) => getIt<GeoLocationBloc>(),
                ),
                BlocProvider<GetTodayAttendanceBloc>(
                  create: (context) => getIt<GetTodayAttendanceBloc>(),
                ),
                BlocProvider<GetAllPendingRequestBloc>(
                  create: (context) => getIt<GetAllPendingRequestBloc>(),
                ),
                BlocProvider<GetTodayAttendanceBloc>(
                  create: (context) => getIt<GetTodayAttendanceBloc>(),
                ),
                BlocProvider<GetPaySlipBloc>(
                  create: (context) => getIt<GetPaySlipBloc>(),
                ),
                BlocProvider<CheckPaySlipBloc>(
                  create: (context) => getIt<CheckPaySlipBloc>(),
                ),
                BlocProvider<SessionBloc>(
                  create: (context) => getIt<SessionBloc>(),
                ),
                BlocProvider<FeedbackBloc>(
                    create: (context) => getIt<FeedbackBloc>()),
                BlocProvider<ReqTodayAttendanceBloc>(
                  create: (context) => getIt<ReqTodayAttendanceBloc>(),
                ),
                BlocProvider<RequTodayAttendanceBloc>(
                  create: (context) => getIt<RequTodayAttendanceBloc>(),
                ),
                BlocProvider<DeleteBloc>(
                  create: (context) => getIt<DeleteBloc>(),
                ),
              ],
              child: DebugNavigator(
                  child: MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'EZHRM Premium',
                theme: PremiumTheme.theme,
                themeMode: ThemeMode.light,
                navigatorObservers: [debugRouteObserver],
                routes: PremiumVersionRoutes.routes,
                home:
                    const NewAppEntry(), // This will show Splash → Login → Dashboard
              )));
        } else {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'EZHRM Standard',
            theme: ThemeData(useMaterial3: false),
            themeMode: ThemeMode.light,
            home: const OldAppEntry(), // Your old app starts here
          );
        }
      },
    );
  }
}

// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class DebugNavigator extends StatelessWidget {
  final Widget child;
  const DebugNavigator({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    debugPrint(
        "📌 Navigator built → context: $context | hash: ${context.hashCode}");
    return child;
  }
}
