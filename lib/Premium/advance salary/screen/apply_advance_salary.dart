import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../Authentication/User Information/user_details.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Authentication/bloc/auth_bloc.dart';
import '../../Authentication/screen/login_screen.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../Dependency_Injection/dependency_injection.dart';
import '../../SessionHandling/session_bloc.dart';
import '../../SideMenuBar/screen/sidebar.dart';
import '../bloc/advance_salary_bloc.dart';
import 'advance_salary_screen.dart';

class ApplyAdvanceSalary extends StatefulWidget {
  const ApplyAdvanceSalary({super.key});

  @override
  State<ApplyAdvanceSalary> createState() => _ApplyAdvanceSalaryState();
}

class _ApplyAdvanceSalaryState extends State<ApplyAdvanceSalary> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  int selectedMonth = DateTime.now().month;

  final List<String> months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];

  final _formKey = GlobalKey<FormState>();

  void _submitAdvanceRequest() {
    final String amountText = _amountController.text.trim();
    final String remarks = _remarksController.text.trim();

    if (!_formKey.currentState!.validate()) return;

    final double? amount = double.tryParse(amountText);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid number")),
      );
      return;
    }

    getIt<AdvanceSalaryBloc>().add(
      AdvanceSalary(
        advance_amount: amount,
        remarks: remarks,
        month: selectedMonth,
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      ],
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          centerTitle: true,
          title: const Text(
            "Apply Advance Salary",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
        body: BlocListener<AdvanceSalaryBloc, AdvanceSalaryState>(
          listener: (context, state) {
            if (state is AdvanceSalarySuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green),
              );
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        AdvanceSalaryScreen()), // route name from your routes table
                (Route<dynamic> route) => false, // removes all previous routes
              );
            } else if (state is AdvanceSalaryFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.errorMessage),
                    backgroundColor: Colors.red),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Image.asset('assets/images/applyloan.png', height: 180),
                  const SizedBox(height: 20),
                  const Text(
                    "Please fill in the details below to request advance salary",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  _buildLabel("Advance Amount"),
                  _buildTextField(
                    hint: "Enter amount in rupees",
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _buildLabel("Select Month"),
                  DropdownButtonFormField<int>(
                    initialValue: selectedMonth,
                    items: List.generate(12, (index) {
                      return DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text(months[index]),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedMonth = value;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: "Choose month",
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel("Remarks"),
                  _buildTextField(
                    hint: "Enter any remarks",
                    controller: _remarksController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitAdvanceRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Submit"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
