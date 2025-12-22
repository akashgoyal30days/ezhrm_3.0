import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../Authentication/User Information/user_details.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Authentication/bloc/auth_bloc.dart';
import '../../Authentication/screen/login_screen.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../Configuration/reimbursement_config.dart';
import '../../Dependency_Injection/dependency_injection.dart';
import '../../Documents/Get Document Type/modal/document_type_modal.dart';
import '../../SessionHandling/session_bloc.dart';
import '../../SideMenuBar/screen/sidebar.dart';
import '../../dashboard/location_service.dart';
import '../../dashboard/screen/dashboard.dart';
import '../../profile/show_user_profile/bloc/profile_bloc.dart';
import '../../success_dialog.dart';
import '../bloc/reimbursement_bloc.dart';
import '../get expense bloc/get_expense_bloc.dart';
import '../get_customers_bloc/get_customers_bloc.dart';
import 'package:file_picker/file_picker.dart';

class ApplyReimbursementScreen extends StatefulWidget {
  final UserSession userSession;
  final UserDetails userDetails;

  const ApplyReimbursementScreen({
    required this.userSession,
    required this.userDetails,
    super.key,
  });
  @override
  _ApplyReimbursementScreenState createState() =>
      _ApplyReimbursementScreenState();
}

class _ApplyReimbursementScreenState extends State<ApplyReimbursementScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedExpenseType;
  String? _selectedCustomer;
  DateTime? _selectedDate;
  DateTime? _joiningDate;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _hasNavigated = false;
  bool _hasShownSnackBar = false;
  DocumentTypeModel? selectedDocumentType;
  File? selectedFile;
  String? selectedFileExtension;

  void _showImageDialog(File imageFile) {
    if (selectedFileExtension?.toLowerCase() == 'pdf' ||
        selectedFileExtension?.toLowerCase() == 'doc' ||
        selectedFileExtension?.toLowerCase() == 'docx') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview not available for PDF or DOC files.'),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(imageFile, fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    getIt<GetExpenseBloc>().add(GetExpense());
    getIt<GetCustomersBloc>().add(GetCustomers());
    // Fetch profile data to get joining_date
    getIt<ProfileBloc>().add(FetchProfileEvent());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    // Use joining_date if available and before now, otherwise fallback to a default (e.g., 2000)
    final DateTime firstDate =
        _joiningDate != null && _joiningDate!.isBefore(now)
            ? _joiningDate!
            : DateTime(2000);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: now,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showSessionExpiredSnackBar(BuildContext context, double baseFontSize) {
    if (_hasShownSnackBar || _hasNavigated || !mounted) return;
    setState(() {
      _hasShownSnackBar = true;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Session expired. Please log in again.',
                style: GoogleFonts.poppins(
                  fontSize: baseFontSize * 0.9,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (_hasNavigated || !mounted) return;
      setState(() {
        _hasNavigated = true;
      });

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

  Future<void> _navigateBackToDashboard(BuildContext context) async {
    if (_hasNavigated || !mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF416CAF)),
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.of(context).pop();
      setState(() {
        _hasNavigated = true;
      });
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            userSession: getIt<UserSession>(),
            userDetails: getIt<UserDetails>(),
            apiUrlConfig: getIt<ApiUrlConfig>(),
            locationService: getIt<LocationService>(),
          ),
        ),
        (route) => false,
      );
    }
  }

  void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
    SnackBarAction? action,
  }) {
    final baseFontSize = MediaQuery.of(context).size.width * 0.04;
    final padding = baseFontSize;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: padding),
            Expanded(
              child: Text(
                message,
                style: ReimbursementTextStyles.snackBarText.copyWith(
                  fontSize: baseFontSize * 0.9,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      final String date = _selectedDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
          : '';

      String expenseAgainstId = '';
      String expenseClientId = '';

      if (_selectedExpenseType == 'Client') {
        expenseAgainstId = '';
        expenseClientId = _selectedCustomer ?? '';
      } else if (_selectedExpenseType == 'Company expenses') {
        expenseAgainstId = 'Company'; // 👈 pass "Company" here
        expenseClientId = '';
      } else {
        expenseAgainstId = _selectedExpenseType ?? '';
        expenseClientId = '';
      }

      debugPrint("Submitting Reimbursement Form with values:");
      debugPrint("Date: $date");
      debugPrint("Amount: ${_amountController.text}");
      debugPrint("Expense Type: $_selectedExpenseType");
      debugPrint("Expense Against ID: $expenseAgainstId");
      debugPrint("Expense Client ID: $expenseClientId");
      debugPrint("Description: ${_descriptionController.text}");
      debugPrint("Document: $selectedFile");

      getIt<ReimbursementBloc>().add(
        AddReimbursement(
          date: date,
          amount: _amountController.text,
          expense_against_id: expenseAgainstId,
          expense_client_id: expenseClientId,
          description: _descriptionController.text,
          document: selectedFile,
        ),
      );
    } else {
      debugPrint("Form validation failed. Required fields missing.");
      _showSnackBar(
        context,
        message: 'Please fill all required fields',
        backgroundColor: ReimbursementColors.warningColor,
        icon: ReimbursementIcons.warning,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isNarrowScreen = MediaQuery.of(context).size.width < 600;
    final double dynamicPadding = MediaQuery.of(context).size.width * 0.05;
    final double dynamicSpacing = MediaQuery.of(context).size.height * 0.015;
    final double dynamicButtonHeight =
        (MediaQuery.of(context).size.height * 0.06).clamp(48, 60);
    final double dynamicImageHeight =
        (MediaQuery.of(context).size.height * 0.2).clamp(120, 200);
    final baseFontSize = MediaQuery.of(context).size.width * 0.04;

    return MultiBlocListener(
      listeners: [
        // Listen for session-related states (expired or user not found)
        BlocListener<SessionBloc, SessionState>(
          listener: (context, state) {
            if (state is SessionExpiredState || state is UserNotFoundState) {
              // Clear user credentials and details
              getIt<UserSession>().clearUserCredentials();
              getIt<UserDetails>().clearUserDetails();

              // Show session expired message
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session expired. Please login again.'),
                  backgroundColor: Colors.red,
                ),
              );

              // Navigate to LoginScreen after a 2-second delay
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
                  (route) => false, // Remove all previous routes
                );
              });
            }
          },
        ),
        // Listen for authentication-related states (logout success or failure)
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is LogoutSuccess) {
              // Show logout success message
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully.'),
                  backgroundColor: Color(0xFF416CAF),
                ),
              );

              // Navigate to LoginScreen after a 2-second delay
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
                  (route) => false, // Remove all previous routes
                );
              });
            } else if (state is LogoutFailure) {
              // Show logout failure message
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
      ],
      child: Container(
        color: Colors.white,
        // padding: EdgeInsets.only(top: 30.0),
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              "Apply Reimbursement",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.white,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.pop(context),
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
          ),
          drawer: const CustomSidebar(),
          body: Container(
            decoration: const BoxDecoration(
              color: ReimbursementColors.backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(dynamicPadding),
              child: MultiBlocListener(
                listeners: [
                  BlocListener<SessionBloc, SessionState>(
                    listener: (context, state) {
                      if (state is SessionExpiredState) {
                        widget.userSession.clearUserCredentials();
                        widget.userDetails.clearUserDetails();
                        _showSessionExpiredSnackBar(context, baseFontSize);
                      } else if (state is UserNotFoundState) {
                        print(
                            'HRMDashboard: User not found, clearing credentials and navigating to login');
                        widget.userSession.clearUserCredentials();
                        widget.userDetails.clearUserDetails();
                        _showSessionExpiredSnackBar(context, baseFontSize);
                      }
                    },
                  ),
                  BlocListener<AuthBloc, AuthState>(
                    listener: (context, state) {
                      if (state is LogoutSuccess) {
                        if (_hasShownSnackBar || _hasNavigated || !mounted) {
                          return;
                        }
                        setState(() {
                          _hasShownSnackBar = true;
                        });
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.warning, color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'LogOut Successfully',
                                    style: GoogleFonts.poppins(
                                      fontSize: baseFontSize * 0.9,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF416CAF),
                            duration: const Duration(seconds: 2),
                          ),
                        );

                        Future.delayed(const Duration(seconds: 2), () {
                          if (_hasNavigated || !mounted) return;
                          setState(() {
                            _hasNavigated = true;
                          });

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
                        if (_hasShownSnackBar || _hasNavigated || !mounted) {
                          return;
                        }
                        setState(() {
                          _hasShownSnackBar = true;
                        });

                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.warning, color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Error in log out.',
                                    style: GoogleFonts.poppins(
                                      fontSize: baseFontSize * 0.9,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  BlocListener<ProfileBloc, ProfileState>(
                    listener: (context, state) {
                      if (state is FetchProfileSuccess) {
                        try {
                          final profileData = state.profileData.first;
                          final joiningDateStr =
                              profileData['joining_date'] as String?;
                          if (joiningDateStr != null) {
                            setState(() {
                              _joiningDate = DateTime.parse(joiningDateStr);
                              debugPrint('Joining date fetched: $_joiningDate');
                            });
                          } else {
                            debugPrint('No joining_date found in profile data');
                          }
                        } catch (e) {
                          debugPrint('Error parsing joining_date: $e');
                        }
                      }
                    },
                  ),
                  BlocListener<ReimbursementBloc, ReimbursementState>(
                    listener: (context, state) {
                      if (state is ReimbursementSuccess) {
                        setState(() {
                          _selectedExpenseType = null;
                          _selectedCustomer = null;
                          _selectedDate = null;
                          _amountController.clear();
                          _descriptionController.clear();
                          selectedFile = null;
                        });
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => SuccessDialog(
                            title: 'Success',
                            message:
                                'Your reimbursement request has been submitted successfully.',
                            buttonText: 'Proceed ',
                            onPressed: () => Navigator.pop(
                                context), // This will be handled inside the dialog already
                          ),
                        );
                      } else if (state is ReimbursementFailure) {
                        if (_hasShownSnackBar || _hasNavigated || !mounted) {
                          return;
                        }
                        setState(() {
                          _hasShownSnackBar = true;
                        });

                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.warning, color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Failed to apply for reimbursement',
                                    style: GoogleFonts.poppins(
                                      fontSize: baseFontSize * 0.9,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  BlocListener<GetExpenseBloc, GetExpenseState>(
                    listener: (context, state) {
                      if (state is GetExpenseFailure) {
                        if (_hasShownSnackBar || _hasNavigated || !mounted) {
                          return;
                        }
                        setState(() {
                          _hasShownSnackBar = true;
                        });

                        ScaffoldMessenger.of(context).clearSnackBars();
                      }
                    },
                  ),
                  BlocListener<GetCustomersBloc, GetCustomersState>(
                    listener: (context, state) {
                      if (state is GetCustomersFailure) {
                        if (_hasShownSnackBar || _hasNavigated || !mounted) {
                          return;
                        }
                        setState(() {
                          _hasShownSnackBar = true;
                        });

                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.warning, color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Failed to fetch customers data',
                                    style: GoogleFonts.poppins(
                                      fontSize: baseFontSize * 0.9,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
                child: BlocBuilder<GetExpenseBloc, GetExpenseState>(
                  bloc: getIt<GetExpenseBloc>(),
                  builder: (context, expenseState) {
                    if (expenseState is GetExpenseLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return Form(
                      key: _formKey,
                      child: SafeArea(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // this text will be replaced by image
                              Center(
                                  child: Image.asset(
                                "assets/images/reimbursement.png",
                                height: 116,
                                width: 132,
                              )),
                              SizedBox(height: dynamicSpacing * 0.5),
                              Center(
                                child: Text(
                                  'Please fill in the details below to apply for reimbursement',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              SizedBox(height: dynamicSpacing),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Select Type',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      hintText: "Select type",
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color(0xFF006FFD),
                                            width: 1), // when selected
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Color(0XFF006FFD), width: 1),
                                      ),
                                    ),
                                    initialValue: _selectedExpenseType,
                                    items: [
                                      DropdownMenuItem(
                                        value: 'Client',
                                        child: Text(
                                          'Client',
                                          style: ReimbursementTextStyles
                                              .dropdownItem,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Company expenses',
                                        child: Text(
                                          'Company expenses',
                                          style: ReimbursementTextStyles
                                              .dropdownItem,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (expenseState is GetExpenseSuccess)
                                        ...expenseState.expenses.map((expense) {
                                          return DropdownMenuItem(
                                            value: expense['id'].toString(),
                                            child: Text(
                                              expense['label'] ?? 'Unknown',
                                              style: ReimbursementTextStyles
                                                  .dropdownItem,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedExpenseType = value;
                                        _selectedCustomer = null;
                                      });
                                    },
                                    validator: (value) =>
                                        value == null ? 'Required' : null,
                                    icon: const Icon(
                                      Icons.expand_more,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    menuMaxHeight:
                                        MediaQuery.of(context).size.height *
                                            0.3,
                                  ),
                                  const SizedBox(height: 10),
                                  if (_selectedExpenseType == 'Client') ...[
                                    SizedBox(height: dynamicSpacing),
                                    BlocBuilder<GetCustomersBloc,
                                        GetCustomersState>(
                                      bloc: getIt<GetCustomersBloc>(),
                                      builder: (context, state) {
                                        List<Map<String, dynamic>> customers =
                                            [];
                                        if (state is GetCustomersSuccess) {
                                          customers = state.customers;
                                        }

                                        return DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Color(0xFF006FFD),
                                                  width: 1), // when selected
                                            ),
                                            labelText: "Select customer",
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                  color: Color(0XFF006FFD),
                                                  width: 1),
                                            ),
                                          ),
                                          initialValue: _selectedCustomer,
                                          items: customers.map((customer) {
                                            return DropdownMenuItem(
                                              value: customer['id'].toString(),
                                              child: Text(
                                                customer['company_name'] ??
                                                    'Unknown',
                                                style: ReimbursementTextStyles
                                                    .dropdownItem,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedCustomer = value;
                                            });
                                          },
                                          validator: (value) =>
                                              value == null ? 'Required' : null,
                                          icon: const Icon(
                                            ReimbursementIcons.dropdown,
                                            color:
                                                ReimbursementColors.textColor,
                                          ),
                                          dropdownColor: ReimbursementColors
                                              .backgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          menuMaxHeight: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.3,
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Date',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: TextEditingController(
                                            text: _selectedDate != null
                                                ? DateFormat('yyyy-MM-dd')
                                                    .format(_selectedDate!)
                                                : '',
                                          ),
                                          decoration: InputDecoration(
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Color(0xFF006FFD),
                                                  width: 1),
                                            ),
                                            labelText: "Date",
                                            hintText: 'mm/dd/yyyy',
                                            suffixIcon: const Icon(
                                                Icons.calendar_today_outlined,
                                                color: Colors.blue),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          validator: (value) =>
                                              _selectedDate == null
                                                  ? 'Required'
                                                  : null,
                                          onTap: () async {
                                            FocusScope.of(context)
                                                .requestFocus(FocusNode());
                                            await _pickDate(context);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Amount',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _amountController,
                                          decoration: InputDecoration(
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Color(0xFF006FFD),
                                                  width: 1),
                                            ),
                                            hintText: 'Amount',
                                            labelText: "Amount",
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Required';
                                            }
                                            if (double.tryParse(value) ==
                                                null) {
                                              return 'Please enter a valid number';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              const Text(
                                'Description',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _descriptionController,
                                decoration: InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color(0xFF006FFD),
                                        width: 1), // when selected
                                  ),
                                  hintText: 'Enter description here',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                maxLines: 2,
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Document File',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),

                              selectedFile == null
                                  ? GestureDetector(
                                      onTap: () async {
                                        final result =
                                            await FilePicker.platform.pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: [
                                            'jpg',
                                            'jpeg',
                                            'png',
                                            'pdf',
                                            'doc',
                                            'docx'
                                          ],
                                        );

                                        if (result != null &&
                                            result.files.single.path != null) {
                                          setState(() {
                                            selectedFile =
                                                File(result.files.single.path!);
                                            selectedFileExtension =
                                                result.files.single.extension;
                                          });
                                        }
                                      },
                                      child: Container(
                                        height: 120,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons
                                                  .add_photo_alternate_outlined),
                                              const SizedBox(width: 8),
                                              const Text(
                                                  'Upload Bill(PDF, DOC, Image)',
                                                  style: TextStyle(
                                                      color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade400),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            selectedFileExtension
                                                        ?.toLowerCase() ==
                                                    'pdf'
                                                ? Icons.picture_as_pdf
                                                : selectedFileExtension
                                                                ?.toLowerCase() ==
                                                            'doc' ||
                                                        selectedFileExtension
                                                                ?.toLowerCase() ==
                                                            'docx'
                                                    ? Icons.description
                                                    : Icons.image,
                                            size: 40,
                                            color: Colors.blueAccent,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    selectedFile!.path
                                                        .split('/')
                                                        .last,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${(selectedFile!.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
                                                  style: const TextStyle(
                                                      color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.remove_red_eye_outlined,
                                                color: Colors.blueAccent),
                                            onPressed: () =>
                                                _showImageDialog(selectedFile!),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.redAccent),
                                            onPressed: () {
                                              setState(() {
                                                selectedFile = null;
                                                selectedFileExtension = null;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),

                              SizedBox(height: dynamicSpacing * 1.67),
                              BlocBuilder<ReimbursementBloc,
                                  ReimbursementState>(
                                bloc: getIt<ReimbursementBloc>(),
                                builder: (context, state) {
                                  return SizedBox(
                                    width: double.infinity,
                                    height: dynamicButtonHeight,
                                    child: state is ReimbursementLoading
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : ElevatedButton(
                                            onPressed: _submitForm,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.blueAccent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text(
                                              'Submit',
                                              style: ReimbursementTextStyles
                                                  .buttonText,
                                            ),
                                          ),
                                  );
                                },
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
          ),
        ),
      ),
    );
  }
}
