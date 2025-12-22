import 'package:ezhrm/Premium/reimbursement/screen/reinbursement_screen.dart';
import 'package:ezhrm/Premium/reimbursement/screen/show_reimbursement_history.dart';
import 'package:ezhrm/Premium/work%20from%20home/screen/show_wfh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'Attendance/Attendance history/screen/attendance_history_screen.dart';
import 'Attendance/Request Today Attendance/screen/ReqAttendanceScreen.dart';
import 'Attendance/mark attendance/screen/mark_attendance_screen.dart';
import 'Attendance/req_past_attendance/screen/req_past_history.dart';
import 'Authentication/User Information/user_details.dart';
import 'Authentication/User Information/user_session.dart';
import 'CSR/View_status/screen/view_csr_activity_status_screen.dart';
import 'CSR/post activity/screen/post_activity.dart';
import 'CSR/view activity/bloc/view_csr_activity_bloc.dart';
import 'CSR/view activity/screen/view_csr_activity_screen.dart';
import 'Comp off/add comp off/screen/add_comp_off.dart';
import 'Comp off/show_comp_off/screen/comp_off_history.dart';
import 'Configuration/ApiService.dart';
import 'Configuration/ApiUrlConfig.dart';
import 'Contact Us/screen/contact_us.dart';
import 'Dependency_Injection/dependency_injection.dart';
import 'Documents/upload_documents/screen/upload_documents.dart';
import 'Documents/view_documents/screen/view_document.dart';
import 'Face Recognition/upload images/screen/face_recognition.dart';
import 'Holiday/screen/holiday_screen.dart';
import 'Payslip/screen/GetPaySlip.dart';
import 'Policy/screen/policy_screen.dart';
import 'SessionHandling/session_bloc.dart';
import 'Task_management/assigned_work/screen/assigned_work_screen.dart';
import 'Task_management/to_do_list/screen/to_do_screen.dart';
import 'Task_management/work_reporting/screen_1/work_reporting_screen.dart';
import 'advance salary/screen/advance_salary_screen.dart';
import 'apply loan/screen/apply_loan.dart';
import 'apply loan/screen/show_apply_loan.dart';
import 'dashboard/location_service.dart';
import 'dashboard/screen/dashboard.dart';
import 'feedback/feedback_screen.dart';
import 'leave/Apply leave/screen/apply_leave.dart';
import 'leave/Employee Leave_quota/screen/leave_quota_screen.dart';
import 'leave/Leave status/screen/leave_status_screen.dart';

class PremiumVersionRoutes {
  static final routes = <String, WidgetBuilder>{
    '/dashboard': (_) => HomeScreen(
          userSession: getIt<UserSession>(),
          userDetails: getIt<UserDetails>(),
          apiUrlConfig: getIt<ApiUrlConfig>(),
          locationService: getIt<LocationService>(),
        ),
    '/mark-attendance': (_) => CheckInScreen(
          userSession: getIt<UserSession>(),
          userDetails: getIt<UserDetails>(),
          apiUrlConfig: getIt<ApiUrlConfig>(),
          isCheckOutMode: false,
        ),
    '/attendance-history': (_) => AttendanceHistoryPage(),
    '/post-activity': (_) => const PostCsrActivityScreen(),
    '/upload-documents': (_) => const UploadDocumentScreen(),
    '/apply-leave': (_) => ApplyLeavePage(),
    '/holiday-list': (_) => HolidayListScreen(),
    '/work-from-home': (_) => WorkFromHomeScreen(),
    '/view-document': (_) => ViewDocumentScreen(),
    '/leave-quota': (_) => LeaveQuotaScreen(),
    '/leave-status': (_) => LeaveStatusScreen(),
    '/comp-off': (_) => CompOffScreen(),
    '/show-comp-off': (_) => CompOffHistoryScreen(),
    '/feedback': (_) => FeedbackScreen(),
    '/request-past-attendance': (_) => ReqPastAttendanceHistoryScreen(),
    '/reimbursement': (_) => ApplyReimbursementScreen(
        userSession: getIt<UserSession>(), userDetails: getIt<UserDetails>()),
    '/getReimbursement': (_) => ReimbursementHistoryScreen(),
    '/contact-us': (_) => ContactUsScreen(),
    '/salary-slip': (_) => PaySlipScreen(apiUrlConfig: getIt<ApiUrlConfig>()),
    '/face-recognition': (_) => FaceRecognitionScreen(),
    '/apply-loan': (_) => ApplyLoanScreen(),
    '/show-loan': (_) => ShowApplyLoanScreen(
        userSession: getIt<UserSession>(), userDetails: getIt<UserDetails>()),
    '/policy': (_) => PoliciesScreen(),
    '/to-do': (_) => ToDoListScreen(),
    '/assigned-work': (_) => AssignWorkScreen(),
    '/work-reporting': (_) => WorkReportingScreen(),
    '/request-attendance': (_) => RequestAttendanceScreen(),
    '/advance-salary-screen': (_) => AdvanceSalaryScreen(),
    '/view-csr-activity-status': (_) => ViewCsrActivityStatusScreen(),
    '/view-csr-activity': (context) => BlocProvider(
          create: (_) => ViewCsrActivityBloc(
            apiService:
                getIt<ApiService>(), // or however you provide your dependencies
            userSession: getIt<UserSession>(),
            apiUrlConfig: getIt<ApiUrlConfig>(),
            sessionBloc: BlocProvider.of<SessionBloc>(context),
          )..add(ViewCsrActivity()), // Optional: fetch data immediately
          child: const ViewCsrActivityScreen(),
        ),
  };
}
