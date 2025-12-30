import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app_selector_screen.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../Dependency_Injection/dependency_injection.dart';
import '../User Information/user_details.dart';
import '../User Information/user_session.dart';
import '../bloc/auth_bloc.dart';
import '../model/user_model.dart';
import 'forgot_password_screen.dart';
import 'loading_screen.dart';

class LoginScreen extends StatefulWidget {
  final UserSession userSession;
  final UserDetails userDetails;
  final ApiUrlConfig apiUrlConfig;

  const LoginScreen({
    super.key,
    required this.userSession,
    required this.userDetails,
    required this.apiUrlConfig,
  });

  @override
  State<LoginScreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FlutterSecureStorage storage = FlutterSecureStorage();
  AppUser? _appUser; // Store AppUser in state
  bool _obscureText = true;
  bool _isCheckingSession = true;

  final FirebaseAuth _auth = FirebaseAuth.instance; // 🔥 Added
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // 🔥 Added
    scopes: ['email', 'profile'],
  );

  @override
  void initState() {
    _checkSessionAndNavigate();
    super.initState();
  }

  Future<bool> _checkSessionAndNavigate() async {
    try {
      print('LoginScreen: Checking session validity');
      final token = await widget.userSession.token;
      final id = await widget.userSession.uid;
      if (token == null || token.isEmpty || id == null) {
        print('LoginScreen: No valid token or user ID found');
        setState(() => _isCheckingSession = false);
        return false;
      }
      print('LoginScreen: Valid session found, id: $id, token: $token');

      // Navigate to LoadingScreen instead of fetching data here
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoadingScreen(
              userSession: widget.userSession,
              userDetails: widget.userDetails,
              apiUrlConfig: widget.apiUrlConfig,
              userId: id,
            ),
          ),
        );
      }
      return true;
    } catch (e) {
      print('LoginScreen: Error while checking session validity: $e');
      setState(() => _isCheckingSession = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session validation failed')),
      );
      return false;
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      debugPrint('in the google sign in function');
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print(
            "LoginScreen: User already signed in as ${currentUser.email}, signing out...");
        await _auth.signOut();
        await _googleSignIn.signOut();
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("LoginScreen: Google Sign-In aborted by user");
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;

      // 🔥 Debug logs
      print("LoginScreen: Google ID: ${googleUser.id}");
      print("LoginScreen: Google username: ${googleUser.email}");
      print("LoginScreen: Google name: ${googleUser.displayName}");
      print("LoginScreen: ID Token: ${googleAuth.idToken}");
      print("LoginScreen: Firebase User: ${user?.email}, UID: ${user?.uid}");

      final headers = {
        'Content-Type': 'application/json',
      };
      final fcmToken = await widget.userDetails.getFcmToken();
      final deviceId = await widget.userDetails.getDeviceId();

      final body = jsonEncode({
        'name': googleUser.displayName,
        // 'name': 'vishal dhiman',
        'email': googleUser.email, //real value
        // 'email': 'vishaldhiman1118@gmail.com',// for testing only
        'provider': 'google',
        'deviceId': deviceId,
        'fcm_token': fcmToken
      });

      // Replace this with your actual API endpoint
      final url = Uri.parse(widget.apiUrlConfig.googleSignIn);

      final response = await http.post(url, headers: headers, body: body);

      final responseBody = jsonDecode(response.body);
      print('response body is $responseBody');
      print('response body is $responseBody');

      if (response.statusCode == 200) {
        final cid = responseBody['user']['company_id'];
        print('user data is $responseBody and cid is $cid');
        final user =
            AppUser.fromGoogleResponse(responseBody as Map<String, dynamic>);
        await widget.userSession.setUserCredentials(
          userId: user.id,
          userToken: user.token,
          sessionValidity: true,
        );
        await widget.userSession.setCId(CId: cid.toString());
        print('c id after successfully google sign in is $cid}');
        print('user id after successfully google sign in is ${user.id}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Google Sign-In Successful"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoadingScreen(
                userSession: widget.userSession,
                userDetails: widget.userDetails,
                apiUrlConfig: widget.apiUrlConfig,
                userId: user.id,
              ),
            ),
          );
        }

        final body = jsonEncode({
          'username': 'admin',
          'password': 'testpass123',
          'companyCode': 'N$cid',
        });

        print('cid:$cid');

        // Replace this with your actual API endpoint
        final url = Uri.parse(widget.apiUrlConfig.imageLogin);

        final imageLoginResponse =
            await http.post(url, headers: headers, body: body);

        if (imageLoginResponse.statusCode == 200) {
          final responseBody = jsonDecode(imageLoginResponse.body);
          String apiKey = responseBody['api_key'];
          await widget.userSession.setApiKey(apiKey: apiKey);
          print(
              'LoginScreen: Api key stored in local data ${await widget.userSession.apiKey}');
        } else {
          print('Login failed: ${response.statusCode} ${response.body}');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Your email is not registered. Please contact the administrator")),
        );
        print('Login failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print("LoginScreen: Google Sign-In error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In failed")),
      );
    }
  }

  Future<String> ensureDeviceId() async {
    try {
      final existingDeviceId = await widget.userDetails.getDeviceId();
      if (existingDeviceId != null && existingDeviceId.isNotEmpty) {
        print('LoginScreen: Using existing device ID: $existingDeviceId');
        return existingDeviceId;
      }

      final deviceInfoPlugin = DeviceInfoPlugin();
      String? newDeviceId;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        newDeviceId = androidInfo.id; // This is ANDROID_ID
        print('LoginScreen: Device id is $newDeviceId');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        newDeviceId = iosInfo.identifierForVendor;
        print('LoginScreen: Device id is $newDeviceId');
      }

      if (newDeviceId == null || newDeviceId.isEmpty) {
        throw Exception("Could not retrieve a valid device ID");
      }

      print('LoginScreen: Retrieved device ID: $newDeviceId');
      await widget.userDetails.setDeviceId(newDeviceId);
      return newDeviceId;
    } catch (e) {
      print('LoginScreen: Error in ensuring device ID: $e');
      return "unknown_device_id"; // or handle as needed
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaler = MediaQuery.of(context).textScaleFactor.clamp(1.0, 1.3);
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) async {
            print('LoginScreen: AuthBloc state changed: $state');
            if (state is AuthLoaded) {
              print('LoginScreen: AuthLoaded with user: ${state.user.name}');

              // ✅ Show success snackbar
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Login successful! Welcome ${state.user.name}'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }

              final headers = {
                'Content-Type': 'application/json',
              };

              final cId = await widget.userSession.cId;

              final body = jsonEncode({
                'username': 'admin',
                'password': 'testpass123',
                'companyCode': 'N$cId',
              });

              print('cid:$cId');

              // Replace this with your actual API endpoint
              final url = Uri.parse(widget.apiUrlConfig.imageLogin);

              final response =
                  await http.post(url, headers: headers, body: body);

              if (response.statusCode == 200) {
                final responseBody = jsonDecode(response.body);
                String apiKey = responseBody['api_key'];
                await widget.userSession.setApiKey(apiKey: apiKey);
                print(
                    'LoginScreen: Api key stored in local data ${await widget.userSession.apiKey}');
              } else {
                print('Login failed: ${response.statusCode} ${response.body}');
              }

              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoadingScreen(
                      userSession: widget.userSession,
                      userDetails: widget.userDetails,
                      apiUrlConfig: widget.apiUrlConfig,
                      userId: state.user.id,
                    ),
                  ),
                );
              }
            }

            // Navigate to HomeScreen
            // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
            else if (state is AuthFailure) {
              print('LoginScreen: AuthFailure: ${state.message}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // --- STRUCTURAL CHANGE: Using Scaffold with a white background ---
          return Scaffold(
            backgroundColor: Colors.white, // Set the main background to white
            body: Stack(
              children: [
                // --- LAYER 1: The blue gradient background on top ---
                Container(
                  // This container is just the blue area at the top.
                  height: screenHeight * 0.35, // Covers top 35% of the screen
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.bottomEnd,
                      end: AlignmentDirectional.topStart,
                      colors: [Color(0xFF3A96E9), Color(0xFF154C7E)],
                      stops: [0.3675, 0.9589],
                      transform: GradientRotation(290.26 * (3.1416 / 180)),
                    ),
                  ),
                ),

                // --- LAYER 2: The scrollable content (logo and form) ---
                SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // --- Spacing to position the logo within the blue area ---
                        SizedBox(height: screenHeight * 0.08),

                        // --- The Logo ---
                        Image.asset(
                          'assets/images/ezhrm_logo.png',
                          width: screenWidth * 0.25, // Responsive logo size
                          height: screenWidth * 0.25,
                        ),

                        SizedBox(height: screenHeight * 0.05),

                        // --- The White Form Card ---
                        Container(
                          width: double.infinity,
                          // The height is now flexible, based on its content
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.06, vertical: 30),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          // The content of your form is exactly the same as before
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Welcome Back",
                                style: TextStyle(
                                    fontSize: 28 * textScaler,
                                    fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Enter your details below to continue",
                                style: TextStyle(
                                    fontSize: 15 * textScaler,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black54),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: screenHeight * 0.035),

                              // Email field
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(fontSize: 16 * textScaler),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Email ID',
                                    suffixIcon: Icon(Icons.email_outlined),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Password field
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextField(
                                  controller: passwordController,
                                  obscureText: _obscureText,
                                  style: TextStyle(fontSize: 16 * textScaler),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Password',
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureText
                                          ? Icons.visibility_off
                                          : Icons.visibility),
                                      onPressed: () {
                                        setState(() {
                                          _obscureText = !_obscureText;
                                        });
                                      },
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Login button
                              SizedBox(
                                height: 58 * textScaler,
                                child: ElevatedButton(
                                  onPressed: state is AuthLoading
                                      ? null
                                      : () async {
                                          final email =
                                              emailController.text.trim();
                                          final password =
                                              passwordController.text.trim();
                                          if (email.isEmpty ||
                                              password.isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      "Please enter both email and password")),
                                            );
                                            return;
                                          }

                                          final bool? userConsented = await showDialog<bool>(
                                            context: context,
                                            barrierDismissible: false, // User must tap a button
                                            builder: (BuildContext context) {
                                              return const DataUsageDialog();
                                            },
                                          );

                                          // If user did NOT tap "Continue" (i.e., tapped Cancel or dismissed), abort login
                                          if (userConsented != true) {
                                            return; // Do nothing, stay on login screen
                                          }

                                          final deviceId =
                                              await ensureDeviceId();
                                          getIt<AuthBloc>().add(LoginSubmitted(
                                              email, password, deviceId));
                                        },
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    disabledBackgroundColor:
                                        Colors.grey.withOpacity(0.5),
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF268AE4),
                                          Color(0xFF095DA9)
                                        ],
                                        stops: [0.009, 0.8906],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: state is AuthLoading
                                          ? const CircularProgressIndicator(
                                              color: Colors.white)
                                          : Text(
                                              "Login",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16 * textScaler,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                    ),
                                  ),
                                ),
                              ),

                              // Forgot Password, etc.
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Forgot Password',
                                  style: TextStyle(
                                    fontSize: 14 * textScaler,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Text("Or sign in with",
                                        style: TextStyle(
                                            fontSize: 14 * textScaler)),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              SizedBox(
                                height: 58 * textScaler,
                                child: OutlinedButton.icon(
                                  onPressed: _signInWithGoogle,
                                  icon: Image.asset('assets/images/google.png',
                                      width: 20 * textScaler),
                                  label: Text(
                                    'Sign in with Google',
                                    style: TextStyle(
                                        fontSize: 16 * textScaler,
                                        color: Colors.black),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.grey),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.015),
                              TextButton(
                                onPressed: () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  debugPrint(
                                      'Standard EZHRM app: moving back to version selector screen');
                                  prefs.remove('app_version');
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            AppSelectorScreen()), // route name from your routes table
                                    (Route<dynamic> route) =>
                                        false, // removes all previous routes
                                  );
                                },
                                child: Text(
                                  'Change Version',
                                  style: TextStyle(
                                    fontSize: 14 * textScaler,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

class CustomInputCard extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String imageAssetPath;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const CustomInputCard({
    super.key,
    required this.label,
    required this.controller,
    required this.imageAssetPath,
    required this.keyboardType,
    this.validator,
  });

  @override
  _CustomInputCardState createState() => _CustomInputCardState();
}

class _CustomInputCardState extends State<CustomInputCard> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(
            0,
            _isFocused ? -20 : 0,
            0,
          ),
          child: Row(
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: _isFocused ? 12 : 16,
                  fontFamily: 'Poppins',
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Image.asset(
                widget.imageAssetPath,
                width: 24,
                height: 24,
                color: Colors.grey,
              ),
            ],
          ),
        ),
        TextFormField(
          focusNode: _focusNode,
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.label == 'Password',
          validator: widget.validator,
          decoration: InputDecoration(
            hintText: widget.label,
            hintStyle: const TextStyle(
              fontSize: 16,
              fontFamily: 'Poppins',
              color: Colors.grey,
            ),
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class DataUsageDialog extends StatelessWidget {
  const DataUsageDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 15),
      title: const Text(
        "Attention",
        style: TextStyle(
            color: Color(0xff072a99),
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            fontSize: 20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
              textAlign: TextAlign.start,
              text: const TextSpan(
                  style: TextStyle(fontSize: 18, color: Colors.black, fontFamily: 'Poppins'),
                  children: [
                    TextSpan(text: "EZHRM collects ", style: TextStyle(fontFamily: 'Poppins',)),
                    TextSpan(
                        text: "location data ",
                        style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins',)),
                    TextSpan(
                        text: "to enable attendance marking and customer visit tracking even when the ",
                        style: TextStyle(fontWeight: FontWeight.normal, fontFamily: 'Poppins',)),
                    TextSpan(text: "app is closed or not in use. ", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: "This data is also collected when the app is running in the ",
                        style: TextStyle(fontWeight: FontWeight.normal, fontFamily: 'Poppins',)),
                    TextSpan(text: "background ", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: "to ensure accurate visit logs during your working hours. ",
                        style: TextStyle(fontWeight: FontWeight.normal, fontFamily: 'Poppins',)),
                    TextSpan(
                        text: "This tracking is based on your employer's configuration. You can stop tracking by logging out or revoking permissions.",
                        style: TextStyle(fontWeight: FontWeight.normal, fontFamily: 'Poppins',)),
                  ])),
        ],
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          style:
          ButtonStyle(foregroundColor: WidgetStateProperty.all(Colors.red)),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          style: ButtonStyle(
              foregroundColor:
              WidgetStateProperty.all(const Color(0xff072a99))),
          child: const Text("Continue"),
        ),
      ],
    );
  }
}
