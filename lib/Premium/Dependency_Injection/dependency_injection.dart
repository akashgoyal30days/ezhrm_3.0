// import 'package:ezhrm/work%20from%20home/screen/work_from_home_scree/n.dart';
import 'package:get_it/get_it.dart';
import '../Attendance/Attendance history/bloc/attendance_history_bloc.dart';
import '../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../Attendance/Request Today Attendance/bloc/req_today_attendance_bloc.dart';
import '../Attendance/Week_Off/bloc/week_off_bloc.dart';
import '../Attendance/geoLocation/geo_location_bloc.dart';
import '../Attendance/mark attendance/bloc/mark_attendance_bloc.dart';
import '../Attendance/req_past_attendance/bloc/req_past_attendance_bloc.dart';
// import '../Attendance/req_past_attendance/screen/ReqPastAttendanceScreen.dart';
import '../Authentication/User Information/user_details.dart';
import '../Authentication/User Information/user_session.dart';
import '../Authentication/bloc/auth_bloc.dart';
import '../Authentication/password_setup_screen.dart';
import '../Authentication/password_verification_screen.dart';
import '../CSR/View_status/bloc/view_activity_status_bloc.dart';
// import '../CSR/View_status/screen/view_activity_status_screen.dart';
import '../CSR/post activity/bloc/post_csr_activity_bloc.dart';
import '../CSR/view activity/bloc/view_csr_activity_bloc.dart';
import '../Comp off/add comp off/bloc/add_comp_off_bloc.dart';
import '../Comp off/show_comp_off/bloc/show_comp_off_bloc.dart';
import '../Configuration/ApiService.dart';
import '../Configuration/ApiUrlConfig.dart';
import '../Contact Us/bloc/contact_us_bloc.dart';
import '../Documents/Get Document Type/bloc/get_document_type_bloc.dart';
import '../Documents/upload_documents/bloc/upload_documents_bloc.dart';
import '../Documents/view_documents/bloc/view_doucments_bloc.dart';
import '../Face Recognition/upload images/bloc/upload_images_bloc.dart';
// import '../Face Recognition/upload images/screen/upload_image_screen.dart';
import '../Face Recognition/upload_image_status/bloc/upload_image_status_bloc.dart';
// import '../Face Recognition/upload_image_status/screen/upload_image_status_screen.dart';
// import '../Get Permissions/screen/show_permissions.dart';
import '../Fetch Notification/fetch_notification_bloc.dart';
import '../Get Permissions/bloc/get_permission_bloc.dart';
import '../Get Role Permissions/bloc/get_role_permission_bloc.dart';
import '../Holiday/bloc/holiday_bloc.dart';
import '../Payslip/bloc/get_pay_slip_bloc.dart';
import '../Payslip/screen/GetPaySlip.dart';
import '../Policy/bloc/policy_bloc.dart';
import '../SessionHandling/session_bloc.dart';
import '../Task_management/assigned_work/bloc/assigned_work_bloc.dart';
// import '../Task_management/assigned_work/screen/assigned_work.dart';
import '../Task_management/to_do_list/bloc/to_do_list_bloc.dart';
// import '../Tracking Location/screen/tracking_location.dart';
// import '../apply loan/screen/apply_loan.dart';
import '../Task_management/work_reporting/bloc/work_reporting_bloc.dart';
import '../Tracking Location/bloc/tracking_location_bloc.dart';
import '../advance salary/bloc/advance_salary_bloc.dart';
import '../apply loan/bloc/apply_loan_bloc.dart';
import '../change password/bloc/change_password_bloc.dart';
import '../dashboard/location_service.dart';
import '../feedback/bloc/feedback_bloc.dart';
import '../leave/Apply leave/bloc/apply_leave_bloc.dart';
import '../leave/Employee Leave_quota/bloc/leave_quota_bloc.dart';
// import '../leave/Employee Leave_quota/screen/show_leave_quota.dart/';
import '../leave/Get Leave Types/bloc/get_leave_quota_bloc.dart';
import '../leave/Leave status/bloc/leave_status_bloc.dart';
import '../profile/show_user_profile/bloc/profile_bloc.dart';
import '../profile/update_user_profile/bloc/update_user_profile_bloc.dart';
import '../reimbursement/bloc/reimbursement_bloc.dart';
import '../reimbursement/get expense bloc/get_expense_bloc.dart';
import '../reimbursement/get_customers_bloc/get_customers_bloc.dart';
import '../work from home/bloc/work_from_home_bloc.dart';
// import '../leave/Leave status/screen/show_leave_status.dart';

final GetIt getIt = GetIt.instance;

void setupDependencies() {
  print('setupDependencies called at ${DateTime.now()}');
  print(
      'GetIt instance in setupDependencies: $getIt (hashCode: ${getIt.hashCode})');

  // PREVENT DOUBLE REGISTRATION — THIS IS THE KEY FIX
  if (getIt.isRegistered<ApiUrlConfig>()) {
    print('Dependencies already registered — skipping entire setup');
    return;
  }

  // Register dependencies
  getIt.registerLazySingleton(() => ApiUrlConfig());
  getIt.registerLazySingleton(
      () => ApiService(apiUrlConfig: getIt<ApiUrlConfig>()));
  getIt.registerLazySingleton(() => UserSession());
  getIt.registerLazySingleton(() => UserDetails());
  // Add checkedInNotifier
  getIt.registerLazySingleton(() => SessionBloc());

  // getIt.registerLazySingleton(() => ViewDocumentsScreen(
  //   userSession : getIt<UserSession>(),
  //   userDetails : getIt<UserDetails>(),
  //   apiUrlConfig: getIt<ApiUrlConfig>(),
  // ));
  // Register UploadDocumentsBloc as a singleton
  getIt.registerFactory<UploadDocumentsBloc>(
    () => UploadDocumentsBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>(),
    ),
  );

  // getIt.registerLazySingleton(() => UploadDocumentsScreen(
  //   userSession : getIt<UserSession>(),
  //   userDetails : getIt<UserDetails>(),
  //   apiUrlConfig: getIt<ApiUrlConfig>(),
  // ));

  getIt.registerLazySingleton<ApplyLeaveBloc>(() => ApplyLeaveBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      leaveQuotaBloc: getIt<LeaveQuotaBloc>(),
      leaveStatusBloc: getIt<LeaveStatusBloc>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton(() => RequTodayAttendanceBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton(() => GetAllPendingRequestBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton(() => GeoLocationBloc(
        apiService: getIt<ApiService>(),
        userSession: getIt<UserSession>(),
        apiUrlConfig: getIt<ApiUrlConfig>(),
        sessionBloc: getIt<SessionBloc>(),
      ));

  // getIt.registerLazySingleton(() => ApplyLeaveScreen(
  //   userSession : getIt<UserSession>(),
  //   userDetails : getIt<UserDetails>(),
  //
  // ));

  getIt.registerLazySingleton<LeaveQuotaBloc>(() => LeaveQuotaBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton<GetTodayAttendanceLogsBloc>(() =>
      GetTodayAttendanceLogsBloc(
          apiService: getIt<ApiService>(),
          userSession: getIt<UserSession>(),
          apiUrlConfig: getIt<ApiUrlConfig>(),
          sessionBloc: getIt<SessionBloc>()));
  // getIt.registerLazySingleton(() => LeaveQuotaScreen(
  //   userSession : getIt<UserSession>(),
  //   userDetails : getIt<UserDetails>(),
  // ));
  getIt.registerLazySingleton(() => DeleteBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>(),
      leaveStatusBloc: getIt<LeaveStatusBloc>()));
  getIt.registerLazySingleton<FeedbackBloc>(() => FeedbackBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton(() => GetLeaveQuotaBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton(() => LocationService(
      apiUrlConfig: getIt<ApiUrlConfig>(),
      userSession: getIt<UserSession>(),
      userDetails: getIt<UserDetails>(),
      getTodayAttendanceBloc: getIt<GetTodayAttendanceBloc>()));

  getIt.registerLazySingleton(() => MarkAttendanceBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      getTodayAttendanceBloc: getIt<GetTodayAttendanceBloc>(),
      sessionBloc: getIt<SessionBloc>()));

  // getIt.registerLazySingleton(() => MarkAttendanceScreen(
  //     userSession: getIt<UserSession>(),
  //     userDetails: getIt<UserDetails>(),
  //     apiUrlConfig: getIt<ApiUrlConfig>(),
  //   locationService: getIt<LocationService>(),
  // ));

  getIt.registerLazySingleton(() => LeaveStatusBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));
  // getIt.registerLazySingleton(() => LeaveStatusScreen(
  //   userSession : getIt<UserSession>(),
  //   userDetails : getIt<UserDetails>(),
  // ));

  getIt.registerLazySingleton(() => PolicyBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));
  // getIt.registerLazySingleton(() => PolicyScreen(
  //   userSession: getIt<UserSession>(),
  //   userDetails: getIt<UserDetails>(),
  // ));

  getIt.registerLazySingleton<ProfileBloc>(() => ProfileBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));
  // getIt.registerLazySingleton(() => ProfileScreen(
  //   userSession : getIt<UserSession>(),
  //   userDetails : getIt<UserDetails>(),
  //   apiUrlConfig: getIt<ApiUrlConfig>(),
  // ));

  getIt
      .registerLazySingleton<UpdateUserProfileBloc>(() => UpdateUserProfileBloc(
          apiService: getIt<ApiService>(),
          userSession: getIt<UserSession>(),
          apiUrlConfig: getIt<ApiUrlConfig>(),
          profileBloc: getIt<ProfileBloc>(), // Inject ProfileBloc
          sessionBloc: getIt<SessionBloc>()));
  // getIt.registerLazySingleton(() => UpdateProfileScreen(
  //   userSession : getIt<UserSession>(),
  //   userDetails : getIt<UserDetails>(),
  // ));

  getIt.registerLazySingleton(() => AuthBloc(
        apiService: getIt<ApiService>(),
        userSession: getIt<UserSession>(),
        userDetails: getIt<UserDetails>(),
        apiUrlConfig: getIt<ApiUrlConfig>(),
      ));
  // getIt.registerLazySingleton(() => LoginPage(
  //   userSession : getIt<UserSession>(),
  //   userDetails : getIt<UserDetails>(),
  //   apiUrlConfig: getIt<ApiUrlConfig>(),
  // ));

  getIt.registerLazySingleton(() => AddCompOffBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>(),
      showCompOffBloc: getIt<ShowCompOffBloc>()));
  getIt.registerLazySingleton(() => ShowCompOffBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));
  getIt.registerLazySingleton(() => FetchNotificationBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      userDetails: getIt<UserDetails>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));
  // getIt.registerLazySingleton(() => AddCompOffScreen(
  //   userSession : getIt<UserSession>(),
  //   userDetails : getIt<UserDetails>(),
  // ));

  getIt.registerLazySingleton(() => ContactUsBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));
  // getIt.registerLazySingleton(() => ContactUsPage(
  //   userSession : getIt<UserSession>(),
  //   userDetails : getIt<UserDetails>(),
  //   apiUrlConfig: getIt<ApiUrlConfig>(),
  // ));

  getIt.registerLazySingleton(() => HolidayBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));
  // getIt.registerLazySingleton(() => HolidayScreen(
  //   userSession : getIt<UserSession>(),
  //   userDetails : getIt<UserDetails>(),
  // ));

  getIt.registerLazySingleton(() => WorkFromHomeBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));
  // getIt.registerLazySingleton(() => WorkFromHomeScreen(
  //   userSession : getIt<UserSession>(),
  //   userDetails : getIt<UserDetails>(),
  //   apiUrlConfig: getIt<ApiUrlConfig>(),
  // ));

  getIt.registerLazySingleton(() => PostCsrActivityBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));
  // getIt.registerLazySingleton(() => PostCsrActivityScreen(
  //   userSession : getIt<UserSession>(),
  //   userDetails : getIt<UserDetails>(),
  // ));

  getIt.registerLazySingleton(() => ViewCsrActivityBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));
  // getIt.registerLazySingleton(() => ViewCsrActivityScreen(
  //   userSession : getIt<UserSession>(),
  //   userDetails : getIt<UserDetails>(),
  //   apiUrlConfig: getIt<ApiUrlConfig>(),
  // ));

  getIt.registerLazySingleton(() => ViewDocumentsBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerFactory<GetDocumentTypeBloc>(
    () => GetDocumentTypeBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>(),
    ),
  );

  getIt.registerLazySingleton(() => PasswordSetupScreen(
        userDetails: getIt<UserDetails>(),
      ));

  getIt.registerLazySingleton(() => PasswordVerificationScreen(
        userDetails: getIt<UserDetails>(),
      ));

  getIt.registerLazySingleton(() => ReqPastAttendanceBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton(() => ReqTodayAttendanceBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton(() => TrackingLocationBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton<AttendanceHistoryBloc>(() =>
      AttendanceHistoryBloc(
          apiService: getIt<ApiService>(),
          userSession: getIt<UserSession>(),
          apiUrlConfig: getIt<ApiUrlConfig>(),
          sessionBloc: getIt<SessionBloc>()));

  // getIt.registerLazySingleton(() => RequestAttendanceScreen(
  //   userSession: getIt<UserSession>(),
  //   userDetails: getIt<UserDetails>(),
  // ));
  //
  // getIt.registerLazySingleton(() => WeekOffScreen(
  //   userSession: getIt<UserSession>(),
  //   userDetails: getIt<UserDetails>(),
  // ));
  //
  // getIt.registerLazySingleton(() => AttendanceHistoryScreen(
  //   userSession: getIt<UserSession>(),
  //   userDetails: getIt<UserDetails>(),
  // ));
  //
  // getIt.registerLazySingleton(() => AttendanceCalendar(
  //   userSession: getIt<UserSession>(),
  //   userDetails: getIt<UserDetails>(),
  // ));

  getIt.registerLazySingleton(() => WeekOffBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton(() => ViewActivityStatusBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  // getIt.registerLazySingleton(() => ViewCsrActivityStatusScreen(
  //   userSession: getIt<UserSession>(),
  //   userDetails: getIt<UserDetails>(),
  //   apiUrlConfig: getIt<ApiUrlConfig>(),
  // ));

  // getIt.registerLazySingleton(() => UploadImagesScreen(
  //   userSession: getIt<UserSession>(),
  //   userDetails: getIt<UserDetails>()
  // ));
  //
  // getIt.registerLazySingleton(() => UploadImageStatusScreen(
  //     userSession: getIt<UserSession>(),
  //     userDetails: getIt<UserDetails>()
  // ));

  getIt.registerLazySingleton(() => ChangePasswordBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      userDetails: getIt<UserDetails>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  // getIt.registerLazySingleton(() => ChangePasswordScreen(
  //   userSession: getIt<UserSession>(),
  //   userDetails: getIt<UserDetails>(),
  //   apiUrlConfig: getIt<ApiUrlConfig>(),
  // ));

  getIt.registerLazySingleton(() => GetPermissionBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton(() => WorkReportingBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  // getIt.registerLazySingleton(() => WorkReportingScreen(
  //   userSession: getIt<UserSession>(),
  //   userDetails: getIt<UserDetails>(),
  // ));
  //
  // getIt.registerLazySingleton(() => GetPermissionScreen(
  //   userSession: getIt<UserSession>(),
  //   userDetails: getIt<UserDetails>(),
  // ));

  getIt.registerLazySingleton(() => UploadImagesBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton(() => ToDoListBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  // getIt.registerLazySingleton(() => ToDoListScreen(
  //   userSession: getIt<UserSession>(),
  //   userDetails: getIt<UserDetails>(),
  // ));

  getIt.registerLazySingleton(() => AssignedWorkBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  // getIt.registerLazySingleton(() => AssignedWorkScreen(
  //   userSession: getIt<UserSession>(),
  //   userDetails: getIt<UserDetails>(),
  // ));

  getIt.registerLazySingleton(() => UploadImageStatusBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton(() => GetRolePermissionBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton(() => ReimbursementBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton(() => GetExpenseBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton(() => GetCustomersBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton(() => AdvanceSalaryBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton(() => ApplyLoanBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton(() => GetTodayAttendanceBloc(
      apiService: getIt<ApiService>(),
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      sessionBloc: getIt<SessionBloc>()));

  // getIt.registerLazySingleton(() => RolePermissionsScreen(
  //   userSession: getIt<UserSession>(),
  //   userDetails: getIt<UserDetails>(),
  // ));
  // getIt.registerLazySingleton(() => LocationTrackingScreen(
  //   userSession: getIt<UserSession>(),
  // ));

  // getIt.registerLazySingleton(() => ReimbursementScreen(
  //   userSession: getIt<UserSession>(),
  //   userDetails: getIt<UserDetails>(),
  // ));
  //
  // getIt.registerLazySingleton(() => ShowApplyLoanScreen(
  //   userSession: getIt<UserSession>(),
  //   userDetails: getIt<UserDetails>(),
  // ));
  //
  // getIt.registerLazySingleton(() => ApplyLoanScreen(
  //   userSession: getIt<UserSession>(),
  //   userDetails: getIt<UserDetails>(),
  // ));
  //
  // getIt.registerLazySingleton(() => AttendanceScreen(
  //   userSession: getIt<UserSession>(),
  //   userDetails: getIt<UserDetails>(),
  //   apiUrlConfig: getIt<ApiUrlConfig>(),
  // ));

  getIt.registerLazySingleton(() => GetPaySlipBloc(
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      apiService: getIt<ApiService>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton(() => CheckPaySlipBloc(
      userSession: getIt<UserSession>(),
      apiUrlConfig: getIt<ApiUrlConfig>(),
      apiService: getIt<ApiService>(),
      sessionBloc: getIt<SessionBloc>()));

  getIt.registerLazySingleton(
      () => PaySlipScreen(apiUrlConfig: getIt<ApiUrlConfig>()));
}
