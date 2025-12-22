import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../Authentication/User Information/user_details.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Authentication/bloc/auth_bloc.dart';
import '../../../Authentication/screen/login_screen.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../Dependency_Injection/dependency_injection.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../../../SideMenuBar/screen/sidebar.dart';
import '../../../dashboard/location_service.dart';
import '../../../dashboard/screen/dashboard.dart';
import '../../../success_dialog.dart';
import '../../Employee Leave_quota/bloc/leave_quota_bloc.dart';
import '../../Leave status/bloc/leave_status_bloc.dart';
import '../bloc/apply_leave_bloc.dart';

class ApplyLeavePage extends StatefulWidget {
  const ApplyLeavePage({super.key});

  @override
  State<ApplyLeavePage> createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends State<ApplyLeavePage> {
  final _formKey = GlobalKey<FormState>();

  String? selectedLeaveType;
  String? selectedEmailCreditType;
  DateTime? fromDate;
  DateTime? toDate;
  TextEditingController reasonController = TextEditingController();
  double? selectedAvailableQuota;
  double? selectedUnderProcessQuota;
  PlatformFile? selectedFile;
  List<DateTime> appliedLeaveDates = [];
  List<String> weekOffDays = [];
  String? leaveSetting;
  String? isApplyInAdvance;

  // Initialize with only the base options.
  List<String> emailCreditTypes = ['Full Day', 'Half Day'];
  List<Map<String, dynamic>> leaveTypesFromApi = [];
  Map<String, int> leaveTypeMap = {};

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  void initState() {
    super.initState();
    getIt<LeaveQuotaBloc>().add(FetchEmployeeLeaveQuota());
    getIt<LeaveStatusBloc>().add(FetchLeaveStatus());
  }

  // ✨ NEW: Helper function to determine if a date is selectable.
  bool _isSelectable(DateTime date) {
    // 1. Check if the date has already been applied for leave.
    final isAlreadyApplied = appliedLeaveDates.any((appliedDate) =>
        date.year == appliedDate.year &&
        date.month == appliedDate.month &&
        date.day == appliedDate.day);
    if (isAlreadyApplied) {
      return false; // Cannot select already applied dates.
    }

    // 2. Determine the integer values for week off days.
    List<int> weekOffDayIntegers;
    if (weekOffDays.isEmpty) {
      // If the bloc data is empty, default to Sunday as the week off.
      weekOffDayIntegers = [DateTime.sunday];
    } else {
      // Otherwise, use the week off days fetched from the bloc.
      weekOffDayIntegers = weekOffDays
          .map((day) {
            switch (day.toLowerCase()) {
              case 'monday':
                return DateTime.monday;
              case 'tuesday':
                return DateTime.tuesday;
              case 'wednesday':
                return DateTime.wednesday;
              case 'thursday':
                return DateTime.thursday;
              case 'friday':
                return DateTime.friday;
              case 'saturday':
                return DateTime.saturday;
              case 'sunday':
                return DateTime.sunday;
              default:
                return -1; // Invalid day, will be filtered out.
            }
          })
          .where((dayInt) => dayInt != -1)
          .toList();
    }

    // // 3. Check if the current date's weekday is in the list of week offs.
    // if (weekOffDayIntegers.contains(date.weekday)) {
    //   return false; // Cannot select week off days.
    // }

    // If all checks pass, the date is selectable.
    return true;
  }

  Future<void> _pickFromDate() async {
    DateTime firstDate = DateTime.now();
    final DateTime lastDate = DateTime(2101);

    if (isApplyInAdvance == null || isApplyInAdvance == '0') {
      firstDate = DateTime(1900);
    }

    DateTime initial = fromDate ?? DateTime.now();

    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    int maxAttempts = 365;
    int attempts = 0;
    while (!_isSelectable(initial)) {
      initial = initial.add(const Duration(days: 1));
      attempts++;
      if (attempts >= maxAttempts || initial.isAfter(lastDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No valid dates available. All dates are either booked or week offs.')),
        );
        return;
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      // ✨ CHANGED: Using the new centralized logic function.
      selectableDayPredicate: _isSelectable,
    );

    if (picked != null) {
      setState(() {
        fromDate = picked;
        if (selectedEmailCreditType == 'Half Day' ||
            selectedEmailCreditType == 'Short Leave') {
          toDate = picked;
        } else if (toDate != null && toDate!.isBefore(fromDate!)) {
          toDate = null;
        }
      });
    }
  }

  Future<void> _pickToDate() async {
    if (selectedEmailCreditType == 'Half Day' ||
        selectedEmailCreditType == 'Short Leave') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'To date is not required for $selectedEmailCreditType leave')),
      );
      return;
    }

    DateTime firstDate = fromDate ?? DateTime.now();
    final DateTime lastDate = DateTime(2101);

    if (isApplyInAdvance == null && fromDate == null) {
      firstDate = DateTime(1900);
    }

    DateTime initial = toDate ?? firstDate;

    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    int maxAttempts = 365;
    int attempts = 0;
    while (!_isSelectable(initial)) {
      initial = initial.add(const Duration(days: 1));
      attempts++;
      if (initial.isAfter(lastDate) || attempts >= maxAttempts) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No valid dates available. All dates are either booked or week offs.'),
          ),
        );
        return;
      }
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      // ✨ CHANGED: Using the new centralized logic function here as well.
      selectableDayPredicate: _isSelectable,
    );

    if (picked != null) {
      setState(() {
        toDate = picked;
      });
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'doc', 'docx'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFile = result.files.first;
      });
    }
  }

  void _updateQuotas(
      String? leaveTypeName, List<Map<String, dynamic>> leaveData) {
    if (leaveTypeName != null) {
      final selectedData = leaveData.firstWhere(
        (item) => item['leave_type_name']?.toString() == leaveTypeName,
        orElse: () => {},
      );

      setState(() {
        selectedAvailableQuota = (selectedData['available_quota'] != null)
            ? double.tryParse(selectedData['available_quota'].toString())
            : null;
        selectedUnderProcessQuota = (selectedData['under_process'] != null)
            ? double.tryParse(selectedData['under_process'].toString())
            : null;
        isApplyInAdvance = selectedData['is_apply_in_advance']?.toString();
      });
    } else {
      setState(() {
        selectedAvailableQuota = null;
        selectedUnderProcessQuota = null;
        isApplyInAdvance = null;
      });
    }
  }

  void _submitLeave() {
    if (_formKey.currentState!.validate()) {
      if (fromDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select the From date')),
        );
        return;
      }

      if (selectedEmailCreditType == 'Full Day' && toDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select the To date for Full Day leave')),
        );
        return;
      }

      double totalDays;
      if (selectedEmailCreditType == 'Half Day') {
        totalDays = 0.5;
      } else if (selectedEmailCreditType == 'Short Leave') {
        totalDays = 0.25;
      } else {
        // totalDays = toDate!.difference(fromDate!).inDays + 1.0;
        totalDays = countDaysExcludingSundays(fromDate!, toDate!)
            .toDouble(); // excluding sundays value
      }

      if (totalDays < 0.25) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Total leave days must be at least 0.25')),
        );
        return;
      }

      final String endDateString = (selectedEmailCreditType == 'Half Day' ||
              selectedEmailCreditType == 'Short Leave')
          ? fromDate!.toIso8601String()
          : toDate!.toIso8601String();

      getIt<ApplyLeaveBloc>().add(ApplyLeave(
        employee_id: null,
        quota_id: leaveTypeMap[selectedLeaveType] ?? 0,
        credit_type: selectedEmailCreditType!,
        start_date: fromDate!.toIso8601String(),
        end_date: endDateString,
        total_days: totalDays,
        reason: reasonController.text,
      ));
    }
  }

  //calculate except sundays
  int countDaysExcludingSundays(DateTime start, DateTime end) {
    int count = 0;
    for (int i = 0; i <= end.difference(start).inDays; i++) {
      DateTime current = start.add(Duration(days: i));
      if (current.weekday != DateTime.sunday) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final padding = isSmallScreen ? 16.0 : 24.0;
    final fontScale = isSmallScreen ? 0.9 : 1.0;

    return MultiBlocListener(
      listeners: [
        BlocListener<SessionBloc, SessionState>(
          listener: (context, state) {
            if (state is SessionExpiredState || state is UserNotFoundState) {
              getIt<UserSession>().clearUserCredentials();
              getIt<UserDetails>().clearUserDetails();

              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session expired. Please login again.'),
                  backgroundColor: Colors.red,
                ),
              );

              Future.delayed(const Duration(seconds: 2), () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      userSession: getIt<UserSession>(),
                      userDetails: getIt<UserDetails>(),
                      apiUrlConfig: getIt<ApiUrlConfig>(),
                    ),
                  ),
                  (route) => false,
                );
              });
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is LogoutSuccess) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully.'),
                  backgroundColor: Color(0xFF416CAF),
                ),
              );

              Future.delayed(const Duration(seconds: 2), () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      userSession: getIt<UserSession>(),
                      userDetails: getIt<UserDetails>(),
                      apiUrlConfig: getIt<ApiUrlConfig>(),
                    ),
                  ),
                  (route) => false,
                );
              });
            } else if (state is LogoutFailure) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error logging out.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        BlocListener<ApplyLeaveBloc, ApplyLeaveState>(
          listener: (context, state) {
            if (state is ApplyLeaveLoading) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );
            } else {
              Navigator.of(context, rootNavigator: true).maybePop();
            }

            if (state is ApplyLeaveSuccess) {
              // Show success dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => SuccessDialog(
                  title: 'Leave Applied Successfully',
                  message:
                      'Your leave application has been\nsuccessfully submitted.',
                  buttonText: 'Done',
                  onPressed: () {
                    // 1. Reset form FIRST (clear all fields)
                    setState(() {
                      selectedLeaveType = null;
                      selectedEmailCreditType = null;
                      fromDate = null;
                      toDate = null;
                      reasonController.clear();
                      selectedFile = null;
                      selectedAvailableQuota = null;
                      selectedUnderProcessQuota = null;
                      isApplyInAdvance = null;
                    });

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HomeScreen(
                              userSession: getIt<UserSession>(),
                              userDetails: getIt<UserDetails>(),
                              apiUrlConfig: getIt<ApiUrlConfig>(),
                              locationService: getIt<
                                  LocationService>())), // route name from your routes table
                          (Route<dynamic> route) =>
                      false, // removes all previous routes
                    );
                    // 2. Re-fetch fresh data from server
                    getIt<LeaveQuotaBloc>().add(FetchEmployeeLeaveQuota());
                    getIt<LeaveStatusBloc>().add(FetchLeaveStatus());
                  },
                ),
              );
              debugPrint('Print statement called after the dialog box closing');
            } else if (state is ApplyLeaveFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        BlocListener<LeaveQuotaBloc, LeaveQuotaState>(
          listener: (context, state) {
            if (state is LeaveQuotaSuccess) {
              setState(() {
                leaveTypesFromApi = state.employeeLeaveQuota;
                leaveTypeMap = {
                  for (var item in leaveTypesFromApi)
                    if (item['leave_type_name'] != null &&
                        item['leave_quota_id'] != null)
                      item['leave_type_name'].toString():
                          int.parse(item['leave_quota_id'].toString()),
                };

                if (selectedLeaveType == null && leaveTypesFromApi.isNotEmpty) {
                  selectedLeaveType =
                      leaveTypesFromApi.first['leave_type_name']?.toString();
                  _updateQuotas(selectedLeaveType, leaveTypesFromApi);
                }
                // If user had a leave type selected before, keep it and update quota
                else if (selectedLeaveType != null) {
                  _updateQuotas(selectedLeaveType, leaveTypesFromApi);
                }
              });
            }
          },
        ),
        BlocListener<LeaveStatusBloc, LeaveStatusState>(
          listener: (context, state) {
            if (state is LeaveStatusSuccess) {
              setState(() {
                leaveSetting = state.setting;
                final updatedCreditTypes = ['Full Day', 'Half Day'];
                if (leaveSetting == '1') {
                  updatedCreditTypes.add('Short Leave');
                }

                emailCreditTypes = updatedCreditTypes;

                if (selectedEmailCreditType != null &&
                    !emailCreditTypes.contains(selectedEmailCreditType)) {
                  selectedEmailCreditType = null;
                }

                appliedLeaveDates = state.fetchedLeaveData
                    .where((leave) =>
                        leave.status == 'Pending' || leave.status == 'Approved')
                    .expand((leave) {
                  final start = DateTime.parse(leave.startDate);
                  final end = DateTime.parse(leave.endDate);
                  final days = end.difference(start).inDays + 1;
                  return List.generate(
                      days, (index) => start.add(Duration(days: index)));
                }).toList();
              });
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Apply Leave',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16 * fontScale,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.chevron_left, color: Colors.black),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => HomeScreen(
                          userSession: getIt<UserSession>(),
                          userDetails: getIt<UserDetails>(),
                          apiUrlConfig: getIt<ApiUrlConfig>(),
                          locationService: getIt<LocationService>(),
                        )),
                (route) => false,
              );
            },
          ),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                color: Colors.black,
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          ],
          elevation: isSmallScreen ? 0 : 1,
        ),
        drawer: const CustomSidebar(),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxWidth:
                        constraints.maxWidth > 800 ? 800 : constraints.maxWidth,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BlocBuilder<LeaveQuotaBloc, LeaveQuotaState>(
                          builder: (context, state) {
                            if (state is LeaveQuotaLoading) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (state is LeaveQuotaFailure) {
                              return Center(
                                  child: Text('Error: ${state.errorMessage}'));
                            }

                            return Row(
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: padding * 0.5),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Available: ${selectedAvailableQuota?.toStringAsFixed(2) ?? '--'}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14 * fontScale,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: padding * 0.75),
                                Flexible(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: padding * 0.5),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade700,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Under Process: ${selectedUnderProcessQuota?.toStringAsFixed(2) ?? '--'}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14 * fontScale,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: padding),
                        Text(
                          'Select Leave Type',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16 * fontScale,
                          ),
                        ),
                        SizedBox(height: padding * 0.375),
                        DropdownButtonFormField<String>(
                          initialValue: selectedLeaveType,
                          hint: const Text('Select'),
                          items: leaveTypesFromApi
                              .where((item) => item['leave_type_name'] != null)
                              .map((item) => DropdownMenuItem<String>(
                                    value: item['leave_type_name'].toString(),
                                    child: Text(
                                      item['leave_type_name'].toString(),
                                      style:
                                          TextStyle(fontSize: 14 * fontScale),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedLeaveType = val;
                              _updateQuotas(val, leaveTypesFromApi);
                            });
                          },
                          validator: (val) => val == null ? 'Required' : null,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: padding * 0.75,
                              vertical: padding * 0.5,
                            ),
                          ),
                        ),
                        SizedBox(height: padding),
                        Text(
                          'Email Credit Type',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16 * fontScale,
                          ),
                        ),
                        SizedBox(height: padding * 0.375),
                        DropdownButtonFormField<String>(
                          initialValue: selectedEmailCreditType,
                          hint: const Text('Select'),
                          items: emailCreditTypes
                              .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(
                                      e,
                                      style:
                                          TextStyle(fontSize: 14 * fontScale),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedEmailCreditType = val;
                              if ((val == 'Half Day' || val == 'Short Leave') &&
                                  fromDate != null) {
                                toDate = fromDate;
                              }
                            });
                          },
                          validator: (val) => val == null ? 'Required' : null,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: padding * 0.75,
                              vertical: padding * 0.5,
                            ),
                          ),
                        ),
                        SizedBox(height: padding),
                        Text(
                          'Select Date',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16 * fontScale,
                          ),
                        ),
                        SizedBox(height: padding * 0.375),
                        Row(
                          children: [
                            Flexible(
                              child: GestureDetector(
                                onTap: _pickFromDate,
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                      hintText: 'From',
                                      suffixIcon: const Icon(
                                        Icons.calendar_today,
                                        color: Colors.blue,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: padding * 0.75,
                                        vertical: padding * 0.5,
                                      ),
                                    ),
                                    controller: TextEditingController(
                                        text: formatDate(fromDate)),
                                    validator: (_) =>
                                        fromDate == null ? 'Required' : null,
                                    style: TextStyle(fontSize: 14 * fontScale),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: padding * 0.75),
                            Flexible(
                              child: GestureDetector(
                                onTap: (selectedEmailCreditType == 'Half Day' ||
                                        selectedEmailCreditType ==
                                            'Short Leave')
                                    ? null
                                    : _pickToDate,
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                      hintText: 'To',
                                      suffixIcon: const Icon(
                                        Icons.calendar_today,
                                        color: Colors.blue,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: padding * 0.75,
                                        vertical: padding * 0.5,
                                      ),
                                    ),
                                    controller: TextEditingController(
                                        text: formatDate(toDate)),
                                    validator: (_) =>
                                        (selectedEmailCreditType ==
                                                    'Half Day' ||
                                                selectedEmailCreditType ==
                                                    'Short Leave')
                                            ? null
                                            : toDate == null
                                                ? 'Required'
                                                : null,
                                    style: TextStyle(fontSize: 14 * fontScale),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: padding),
                        Text(
                          'Reason for leave',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16 * fontScale,
                          ),
                        ),
                        SizedBox(height: padding * 0.375),
                        TextFormField(
                          controller: reasonController,
                          maxLines: 5,
                          validator: (val) => val == null || val.isEmpty
                              ? 'Please enter reason'
                              : null,
                          decoration: InputDecoration(
                            hintText: 'Share your reason here',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.all(padding * 0.75),
                          ),
                          style: TextStyle(fontSize: 14 * fontScale),
                        ),
                        SizedBox(height: padding),
                        Text(
                          'Choose Document',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16 * fontScale,
                          ),
                        ),
                        SizedBox(height: padding * 0.375),
                        GestureDetector(
                          onTap: _pickDocument,
                          child: Container(
                            height: screenHeight * 0.15,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Center(
                              child: selectedFile == null
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.upload_file,
                                          color: Colors.blue,
                                          size: 30 * fontScale,
                                        ),
                                        SizedBox(height: padding * 0.5),
                                        Text(
                                          'Upload File',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 14 * fontScale,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.insert_drive_file,
                                          color: Colors.blue,
                                          size: 30 * fontScale,
                                        ),
                                        SizedBox(height: padding * 0.5),
                                        Text(
                                          selectedFile!.name,
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 14 * fontScale,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(height: padding * 2),
                        SizedBox(
                          width: double.infinity,
                          height: 48 * fontScale,
                          child: ElevatedButton(
                            onPressed: _submitLeave,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Colors.blue,
                              padding:
                                  EdgeInsets.symmetric(vertical: padding * 0.5),
                            ),
                            child: Text(
                              'Apply Leave',
                              style: TextStyle(
                                fontSize: 16 * fontScale,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
