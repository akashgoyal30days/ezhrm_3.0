import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../Dependency_Injection/dependency_injection.dart';
import '../../success_dialog.dart';
import '../bloc/auth_bloc.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is UpdatePasswordSuccess) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => SuccessDialog(
              title: "Password Reset Email Sent",
              message: "Please check your email to reset your password.",
              buttonText: "Proceed",
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to login
              },
            ),
          );
        } else if (state is UpdatePasswordFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent, // Make AppBar transparent
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                Navigator.pop(context); // Navigate back to previous screen
              },
            ),
          ),
          // This allows the body to be drawn behind the AppBar for a seamless look
          extendBodyBehindAppBar: true,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            // You already correctly applied the gradient here
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.bottomEnd,
                end: AlignmentDirectional.topStart,
                colors: [Color(0xFF3A96E9), Color(0xFF154C7E)],
                stops: [0.3675, 0.9589],
                transform: GradientRotation(290.26 * (3.1416 / 180)),
              ),
            ),
            child: SafeArea(
              child: state is AuthLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        SizedBox(height: screenHeight * 0.04),
                        // Center Logo
                        Image.asset(
                          'assets/images/ezhrm_logo.png',
                          width: screenWidth * 0.28,
                          height: screenHeight * 0.12,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        // White Modal Container
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(28),
                                topRight: Radius.circular(28),
                              ),
                            ),
                            child: SingleChildScrollView(
                              // Added for keyboard overflow safety
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Center(
                                    child: Text(
                                      'Reset your password',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Center(
                                    child: Text(
                                      'All fields are mandatory',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: 'Poppins',
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  // Email Field
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: TextField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: const InputDecoration(
                                          hintText: 'Email ID',
                                          suffixIcon:
                                              Icon(Icons.email_outlined),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 18),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Proceed Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 63,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final email =
                                            _emailController.text.trim();

                                        if (email.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    "All fields are required")),
                                          );
                                          return;
                                        }

                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => SuccessDialog(
                                            title: "Password Reset Email sent successfully",
                                            message:
                                                "Please check your email to reset your password.",
                                            buttonText: "Proceed",
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); // Close dialog
                                              Navigator.of(context)
                                                  .pop(); // Go back to login
                                            },
                                          ),
                                        );
                                        getIt<AuthBloc>()
                                            .add(UpdatePassword(email: email));
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: EdgeInsets.zero,
                                        backgroundColor: Colors.transparent,
                                        elevation: 0,
                                      ),
                                      child: Ink(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF268AE4),
                                              Color(0xFF095DA9)
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(12)),
                                        ),
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: const Text(
                                            'Proceed',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
    );
  }
}
