class ApiUrlConfig {
  String authKey = '4F21zrjoAASqz25690Zpqf67UyY';
  String? token = '';
  // String baseUrl = 'https://api.ezhrm.in/index.php/';
  String baseUrl = 'https://api.ezhrm.in/';
  // String baseUrl = 'https://hrmapi.bbills.win/';
  // String imageBaseUrl = 'https://hrmapi.bbills.win/';
  String imageBaseUrl = 'https://api.ezhrm.in/';
  String csrimageBaseUrl = 'https://api.ezhrm.in/';
  // String googleSignIn = 'https://login.ezhrm.in/controller/process/app/user_glogin.php';
  String googleSignIn = 'https://api.ezhrm.in/api/login-social';
  String imageLogin = 'http://173.249.31.55:8080/login';
  String loginPath = 'api/login';
  Map<String, String> loginHeader = {'Content-Type': 'application/json'};

  String logoutPath = 'api/logout';
  Map<String, String> logoutHeader = {
    // to be added in the bloc code yet
  };

  String fetchUserDataPath = 'userDetail';
  Map<String, String> fetchUserDataHeader = {
    'Client-Service': 'COHAPPRT',
    'Auth-Key': '4F21zrjoAASqz25690Zpqf67UyY',
    'uid': '1',
    'token': '678765c545a5b',
    'rurl': 'login.etribes.in',
    'Cookie': 'ci_session=86j7g1jb5p92bfnmo6r9om6uelbraoe6'
  };

  String uploadDocumentsPath = 'api/documents';
  Map<String, String> uploadDocumentsHeader = {};

  String viewDocumentsPath = 'api/documents/';

  String getEmployeeDetails = 'api/getEmployee/';

  String updateUserPasswordPath = 'userDetail/update_password';

  String updateProfileDetailsPath = 'userDetail/update_user';

  String getHolidaysPath = 'api/holidays';

  String getEmployeeLeaveQuotaPath = 'api/employee-quota/';

  String getCompanyInfoPath = 'api/company-info/';

  String applyLeavePath = 'api/apply-leave';

  String getLeaveTypesPath = 'api/leave-quota';

  String updateEmployeeDetailsPath = 'api/updateEmployee/';

  String showEmployeeLeaveStatusPath = 'api/apply-leave/';

  String addCompOffPath = 'api/comp-off';

  String showCompOffPath = 'api/comp-off/';

  String requestWorkFromHomePath = 'api/work-from-home';

  String getCompanyPolicyPath = 'api/company-policy';

  String postCsrActivity = 'api/timeline';

  String getCsrActivity = 'api/timeline';

  String forgotPassword = 'api/forgot-password';

  String documentType = 'api/documentType';

  String reqPastAttendancePath = 'api/employee-attendance';

  String reqTodayAttendancePath = 'api/request-attendance';

  String showAttendanceHistoryPath = 'api/empAttendanceHistory/';

  String getWeekOffPath = 'api/weekly-off-days/';

  String viewActivityStatus = 'api/timeline/';

  String changePasswordPath = 'api/change-password/';

  String uploadImagesPath = 'api/employee-face-images';

  String getFaceImageStatusPath = 'api/get-face-images/';

  String toDoListPath = 'api/getRandomTasksbyid/';

  String toDoListUpdatePath = 'api/updateRandomTasks/';

  String getAssignedWork = 'api/getEmployeeTasks/';

  String updateAssignedWork = 'api/updateEmployeeTasks/';

  String getPermissions = 'api/getAttendanceSetting/';

  String getWorkReporting = 'api/get-work-reporting/';

  String updateWorkReporting = 'api/update-work-reporting/';

  String addWorkReporting = 'api/add-work-reporting';

  String getRolePermission = 'api/roles-permission/';

  String addReimbursement = 'api/applyReimbursement';

  String getExpenses = 'api/expense';

  String getCustomers = 'api/getCustomer';

  String applyAdvanceSalary = 'api/advance-salary';

  String applyLoan = 'api/apply-loan';

  String getApplyLoan = 'api/employee-loan/';

  String getAdvanceSalary = 'api/advance-salary/';

  String addLocation = 'api/addTrackLocation';

  String getTimeInterval = 'api/get-track-location/';

  String getTodayAttendance = 'api/empTodayAttendance/';

  String markTodayAttendance = 'api/mark-device-attendance';

  String getWorkFromHome = 'api/work-from-home/';

  // String locationSending = 'https://hrmapi.bbills.win/index.php/api/addTrackLocation';
  String locationSending = 'https://api.ezhrm.in/api/addTrackLocation';

  String paySlip = 'api/get-payslips-data/';

  String checkPaySlip = 'api/payslips/';

  String feedback = 'api/send-feedback';

  String deleteEmployeeLeave = 'api/apply-leave/';

  String faceVerifyApi = 'http://173.249.31.55:8080/user/vector/match';

  String requTodayAttendance = 'api/request-attendance/';

  String geoLocation = 'api/geo-locations';

  String fetchNotificationPath = 'api/getNotification/';

  String getTodayAttendanceLog = 'api/getTodayAttendanceLog/';

  String getPendingRequest = 'api/getPendingRequest/';

  String getPastPendingRequest = 'api/getPendingAttendance/';

  String getReimbursment = 'api/reimbursementGet/';
}
