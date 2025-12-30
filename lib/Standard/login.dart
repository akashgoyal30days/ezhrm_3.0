// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:ezhrm/Standard/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/style.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../app_selector_screen.dart';
import '../standard_app_entry.dart';
import 'home_bottom_navigation_bar.dart';
import 'constants.dart';
import 'custom_text_field.dart';
import 'api.dart';
import 'services/shared_preferences_singleton.dart';

String? liveattendancetoken;

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  final currDt = DateTime.now();
  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final emailController = TextEditingController(),
      passwordController = TextEditingController(),
      emailnewController = TextEditingController(),
      phoneController = TextEditingController();
  bool agreedToDataUsage = false;
  String? _platformVersion = '',
      btnstate,
      message = '',
      messagenew = '',
      messagenotp = '',
      mytoken = "",
      location;
  bool visible = false,
      visiblem = false,
      visibleotp = false,
      hideIcon = false,
      _initialized = false,
      todash = true;
  GoogleSignInAccount? _currentUser;

  @override
  void initState() {
    super.initState();
    dontshowbackgroundlocationdailog();
    initPlatformState();
  }

  dontshowbackgroundlocationdailog() async {
    await SharedPreferencesInstance.setString(
        "ShowBackgroundLocationDailog", "false");
  }

  Future<void> _handleSignIn() async {
    if (!agreedToDataUsage) {
      final continueLogin = await showDialog<bool>(
            context: context,
            builder: (_) => const DataUsageDialog(),
          ) ??
          false;
      if (!continueLogin) return;
    }
    agreedToDataUsage = true;

    try {
      // Initialize (must provide Web Client ID)
      final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email'],
          serverClientId:
              "784136586253-gquflk6tl3ac5rd7bflpv4dr0sccm1mn.apps.googleusercontent.com");

      await googleSignIn.signOut(); // Clears previous state

      // Authenticate
      final account = await googleSignIn.signIn();

      if (account == null) {
        debugPrint("User canceled Google Sign-In");
        return;
      }

      setState(() {
        _currentUser = account;
      });

      final email = account.email;
      debugPrint("Google email: $email");

      await _googleLogin(); // pass email to API
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') {
        log("User canceled Google Sign-In");
        return;
      }

      debugPrint("Google Sign-In failed: ${e.message}");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Sign-In failed.")),
        );
      }
    } catch (e) {
      log("Unexpected Google Sign-In error: $e");
    }
  }

  String? imeiNumber;
  Future<void> initPlatformState() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _platformVersion = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _platformVersion = iosInfo.identifierForVendor ?? '';
      }

      SharedPreferencesInstance.setString('deviceid', _platformVersion);
      log("Unique ID: $_platformVersion");
    } catch (e) {
      _platformVersion = '';
      log("Device ID error: $e");
    }
  }

  // Future<void> _register() async {
  //   if (_initialized) return;
  //   _firebaseMessaging.requestPermission();
  //   try {
  //     mytoken = await _firebaseMessaging.getToken();
  //   } catch (e) {}
  //   await SharedPreferencesInstance.instance!.setString('fbasetoken', mytoken!);
  //   _initialized = true;
  // }

  String? otp;
  Future _sendOtp() async {
    var uri = "$customurl/controller/process/forget_password.php";
    final response = await http.post(Uri.parse(uri), body: {
      'id': data['data']['id'],
      'otp': otp,
      'type': 's2',
      'db': data['data']['db'],
    }, headers: <String, String>{
      'Accept': 'application/json',
    });
    datan = json.decode(response.body);
    setState(() {
      userDatan = datan["data"];
      if (datan['status'] == true) {
        Navigator.pop(context);
        Fluttertoast.showToast(
            msg: "Your New Password Is Generated Successfully",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 20,
            backgroundColor: Colors.white,
            textColor: Colors.black,
            fontSize: 16.0);
        Navigator.pop(context);
      } else if (datan['status'] == false) {
        Navigator.pop(context);
        setState(() {
          btnstate = 'close';
        });
        Fluttertoast.showToast(
            msg: datan['error'],
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 20000,
            backgroundColor: Colors.white,
            textColor: Colors.black,
            fontSize: 16.0);
      }
    });
  }

  apple_login(String appleloginEmail) async {
    log(appleloginEmail.toString());
    setState(() {
      message = 'please wait....';
      visible = true;
    });

    var uri = "$customurl/controller/process/app/user_glogin.php";
    final response = await http.post(Uri.parse(uri), body: {
      'type': 'glogin',
      'email': appleloginEmail.toString() ?? "",
      'device_id': _platformVersion ?? "",
      'device_id2': _platformVersion ?? "",
      'version': version ?? "",
      'firebase': mytoken ?? "",
      'platform': 'android',
    }, headers: <String, String>{
      'Accept': 'application/json',
    });
    var mydata = json.decode(response.body);

    if (!mydata.containsKey('status')) {
      setState(() {
        visible = false;
      });
      return;
    }
    setState(() {
      message = mydata['msg'];
      visible = false;
    });
    if (mydata['status'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          data['msg'],
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.red,
      ));
      return;
    }
    await SharedPreferencesInstance.loginDataInitialise(mydata);

    final prefs = await SharedPreferences.getInstance();
    final cid = prefs.getString('comp_id');

    final headers = {
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'username': userName,
      'password': imagePassword,
      'companyCode': 'O$cid',
    });

    final url = Uri.parse(imageLogin);

    final imageLoginResponse =
    await http.post(url, headers: headers, body: body);

    if (imageLoginResponse.statusCode == 200) {
      final responseBody = jsonDecode(imageLoginResponse.body);
      String apiKey = responseBody['api_key'];
      await prefs.setString('api_key', apiKey);
      print(
          'LoginScreen: Api key stored in local data ${prefs.getString('api_key')}');
    } else {
      print('Login failed: ${imageLoginResponse.statusCode} ${imageLoginResponse.body}');
    }
    restartApp();
  }

  _googleLogin() async {
    log(_currentUser!.email.toString());
    if (_currentUser == null) return;
    setState(() {
      message = 'please wait....';
      visible = true;
    });

    var uri = "$customurl/controller/process/app/user_glogin.php";
    final response = await http.post(Uri.parse(uri), body: {
      'type': 'glogin',
      'email': _currentUser!.email ?? "",
      'device_id': _platformVersion ?? "",
      'device_id2': _platformVersion ?? "",
      'version': version ?? "",
      'firebase': mytoken ?? "",
      'platform': 'android',
    }, headers: <String, String>{
      'Accept': 'application/json',
    });
    var mydata = json.decode(response.body);
    debugPrint('Google sign in response ${mydata.toString()}');

    if (!mydata.containsKey('status')) {
      setState(() {
        visible = false;
      });
      return;
    }
    setState(() {
      message = mydata['msg'];
      visible = false;
    });
    if (mydata['status'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          data['msg'],
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.red,
      ));
      return;
    }
    await SharedPreferencesInstance.loginDataInitialise(mydata);

    final prefs = await SharedPreferences.getInstance();
    final cid = prefs.getString('comp_id');

    final headers = {
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'username': userName,
      'password': imagePassword,
      'companyCode': 'O$cid',
    });

    final url = Uri.parse(imageLogin);

    final imageLoginResponse =
    await http.post(url, headers: headers, body: body);

    if (imageLoginResponse.statusCode == 200) {
      final responseBody = jsonDecode(imageLoginResponse.body);
      String apiKey = responseBody['api_key'];
      await prefs.setString('api_key', apiKey);
      print(
          'LoginScreen: Api key stored in local data ${prefs.getString('api_key')}');
    } else {
      print('Login failed: ${imageLoginResponse.statusCode} ${imageLoginResponse.body}');
    }
    restartApp();
  }

  var userData, userDatan, db, data, datan;
  String? dbn;
  Future _frgtpasswrd() async {
    var uri = "$customurl/controller/process/forget_password.php";
    final response = await http.post(Uri.parse(uri), body: {
      'email': emailnewController.text,
      'phone': phoneController.text,
      'type': 's1'
    }, headers: <String, String>{
      'Accept': 'application/json',
    });
    data = json.decode(response.body);
    setState(() async {
      userData = data["status"];
      if (userData == true) {
        Navigator.pop(context);
        Navigator.pop(context);
        emailnewController.clear();
        phoneController.clear();
        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
              backgroundColor: Colors.white,
              elevation: 80,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0))),
              title: Center(
                  child: Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    color: Colors.red,
                    iconSize: 30,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const Text('Enter OTP',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              )),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Center(
                      child: OTPTextField(
                        length: 6,
                        width: MediaQuery.of(context).size.width,
                        textFieldAlignment: MainAxisAlignment.spaceAround,
                        fieldWidth: 40,
                        fieldStyle: FieldStyle.box,
                        style: const TextStyle(fontSize: 17),
                        onCompleted: (pin) => setState(
                          () {
                            otp = pin;
                          },
                        ),
                      ),
                    ),
                    Card(
                      color: Colors.transparent,
                      elevation: 80,
                      child: ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.all<Color>(Colors.grey)),
                        child: const Text(
                          'SUBMIT',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          if (otp == null) return;
                          _sendOtp();
                          setState(() {
                            btnstate = 'hide';
                            _load();
                          });
                        },
                        // color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else if (userData == false) {
        Navigator.pop(context);
        Fluttertoast.showToast(
            msg: "Credentials don't match for the user",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 20,
            backgroundColor: Colors.white,
            textColor: Colors.black,
            fontSize: 16.0);
        setState(() {
          btnstate = 'show';
        });
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailnewController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  String? btnval;

  _load() {
    if (btnstate == 'hide') {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
            backgroundColor: Colors.transparent,
            elevation: 80,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0))),
            title: Center(
                child: Column(
              children: [
                Center(
                  child: LoadingAnimationWidget.flickr(
                    leftDotColor: Colors.indigo,
                    rightDotColor: Colors.blue,
                    size: 60,
                  ),
                )
              ],
            )),
          );
        },
      );
    }
    if (btnstate == 'close') {
      Navigator.pop(context);
    }
  }

  forgotPassword() => showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: EdgeInsets.zero,
            child: ForgotPasswordDialogBox(
              emailnewController,
              phoneController,
              () {
                _frgtpasswrd();
                setState(() {
                  btnstate = 'hide';
                  _load();
                  messagenew = 'please wait....';
                  visiblem = true;
                });
              },
            ),
          );
        },
      );

  login() async {
    log(showupdatedailog.toString());
    String email = emailController.text ?? "",
        password = passwordController.text ?? "";
    if (email.isEmpty || password.isEmpty) return;
    // Warning Dialog
    if (!agreedToDataUsage) {
      bool continueLogin = await showDialog(
              context: context, builder: (_) => DataUsageDialog()) ??
          false;
      if (!continueLogin) return;
    }
    agreedToDataUsage = true;
    // Warning Dialog
    var did = _platformVersion;
    setState(() {
      message = 'please wait....';
      visible = true;
      btnval = 'show';
    });
    var rsp = await loginUser(email, password, _platformVersion!, version!, mytoken!);

    debugPrint('Login response from username and password${rsp.toString()}');
    if (rsp.containsKey('status')) {
      setState(() {
        btnval = 'hide';
        message = rsp['msg'];
        visible = false;
      });
      if (rsp['status'].toString() == "true") {
        await SharedPreferencesInstance.loginDataInitialise(rsp);

        final prefs = await SharedPreferences.getInstance();
        final cid = prefs.getString('comp_id');
        final uid = prefs.getString('uid');

        var uri = "$customurl/controller/process/app/attendance_mark.php";

        Map companyBody = {
          'type': 'get_company_id',
          'uid': uid,
          'cid': cid,
        };
        final response = await http.post(
          Uri.parse(uri),
          body: companyBody,
          headers: <String, String>{
            'Accept': 'application/json',
          },
        );

        debugPrint('Status code: ${response.statusCode}');
        debugPrint('Raw response company id body: "${response.body}"');

        if (response.body.isEmpty) {
          debugPrint('❌ Empty response from server');
          return;
        }

        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);

          prefs.setString('company_id', decoded['cid']);
        } catch (e) {
          debugPrint('❌ JSON decode failed: $e');
          return;
        }

        debugPrint('Company id response: $decoded');

        final newCompanyId = prefs.getString('company_id');
        final headers = {
          'Content-Type': 'application/json',
        };
        final body = jsonEncode({
          'username': userName,
          'password': imagePassword,
          'companyCode': 'O$newCompanyId',
        });

        final url = Uri.parse(imageLogin);

        final imageLoginResponse =
        await http.post(url, headers: headers, body: body);

        if (imageLoginResponse.statusCode == 200) {
          final responseBody = jsonDecode(imageLoginResponse.body);
          String apiKey = responseBody['api_key'];
          await prefs.setString('api_key', apiKey);
          print(
              'LoginScreen: Api key stored in local data ${prefs.getString('api_key')}');
        } else {
          print('Login failed: ${imageLoginResponse.statusCode} ${imageLoginResponse.body}');
        }

        if (rsp['data']['role'].toString().trim() == 'Attendance Manager') {
          setState(() {});
          SharedPreferencesInstance.setString('att_manager', '1');
        } else {
          setState(() {});

          SharedPreferencesInstance.setString('att_manager', '0');
        }
        restartApp();

        if (datak != null) {
          datak['code'] = 1002;
        }
        if (mounted) {
          setState(() {
            btnval = 'hide';
          });
        }
      }
    } else {
      setState(() {
        btnval = 'hide';
        visible = false;
        message = "nothing";
      });
      Navigator.pop(context);
    }
  }

  restartApp() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationAlways,
      Permission.camera,
      Permission.photos,
    ].request();

    await SharedPreferencesInstance.instance!
        .setString("showupdatedailog", "true");

    await SharedPreferencesInstance.setString(
        "ShowBackgroundLocationDailog", "true");
    await initializeApp();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeBottomNavigationBar()),
      (_) => false,
    );
    try {
      var uri = "$customurl/controller/process/app/profile.php";
      final response = await http.post(Uri.parse(uri), body: {
        'type': 'fetch_profile',
        'cid': SharedPreferencesInstance.getString('comp_id') ?? "",
        'uid': SharedPreferencesInstance.getString('uid') ?? ""
      }, headers: <String, String>{
        'Accept': 'application/json',
      });
      var data = json.decode(response.body);

      List userData = data["data"];
      log("Profile Data$userData");
      await SharedPreferencesInstance.saveUserProfileData(userData[0]);
    } catch (e) {
//
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: SizedBox(
                          height: 80,
                          child: Image.asset(
                            'assets/ezlogo.png',
                            colorBlendMode: BlendMode.colorBurn,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 4),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.5,
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Login",
                                    style: TextStyle(
                                      color: Color(0xff072a99),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 26,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                                padding: EdgeInsets.only(left: 8.0, bottom: 8),
                                child: Text("Enter your credentials below",
                                    style: TextStyle(
                                      color: Color(0xff072a99),
                                    ))),
                            CustomTextField(
                              enabled: message != "please wait...." ||
                                  message != 'Login Successfully',
                              controller: emailController,
                              hint: "Email ID",
                              textInputType: TextInputType.emailAddress,
                            ),
                            CustomTextField(
                              enabled: message != "please wait...." ||
                                  message != 'Login Successfully',
                              controller: passwordController,
                              callBack: login,
                              isPassword: true,
                              hint: "Password",
                              textInputType: TextInputType.visiblePassword,
                            ),
                            if (message != null &&
                                message != 'Login Successfully' &&
                                message != "please wait...." &&
                                message!.isNotEmpty)
                              Center(
                                  child: Text(
                                message!,
                                style: const TextStyle(
                                  color: Colors.red,
                                ),
                              )),
                            if (message != "please wait...." ||
                                message != 'Login Successfully')
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                        onPressed: forgotPassword,
                                        style: ButtonStyle(
                                            padding: WidgetStateProperty.all(
                                                EdgeInsets.zero),
                                            foregroundColor:
                                                WidgetStateProperty.all(
                                              const Color(0xff072a99),
                                            )),
                                        child: const Text("Forgot Password?")),
                                  ],
                                ),
                              ),
                            message == "please wait...." ||
                                    message == 'Login Successfully'
                                ? Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Center(
                                      child: LoadingAnimationWidget
                                          .threeRotatingDots(
                                              color: const Color(0x88072a99),
                                              size: 50),
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          ElevatedButton(
                                            onPressed: login,
                                            style: ButtonStyle(
                                              padding: WidgetStateProperty.all(
                                                  const EdgeInsets.all(15)),
                                              shape: WidgetStateProperty.all(
                                                RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    10,
                                                  ),
                                                ),
                                              ),
                                              backgroundColor:
                                                  WidgetStateProperty.all(
                                                const Color(0xff072a99),
                                              ),
                                              elevation:
                                                  WidgetStateProperty.all(8),
                                            ),
                                            child: const Text(" Login "),
                                          ),
                                          const SizedBox(height: 6),
                                          SignInButton(
                                            Buttons.Google,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            elevation: 8,
                                            onPressed: _handleSignIn,
                                          ),
                                          const SizedBox(height: 10),
                                          Platform.isIOS
                                              ? SignInWithAppleButton(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  height: 35,
                                                  style:
                                                      SignInWithAppleButtonStyle
                                                          .black,
                                                  onPressed: () async {
                                                    final credential =
                                                        await SignInWithApple
                                                            .getAppleIDCredential(
                                                      scopes: [
                                                        AppleIDAuthorizationScopes
                                                            .email,
                                                        AppleIDAuthorizationScopes
                                                            .fullName,
                                                      ],
                                                    );

                                                    log(credential.email
                                                        .toString());
                                                    apple_login(credential.email
                                                        .toString());
                                                  },
                                                )
                                              : const SizedBox(),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: TextButton(
                                                onPressed: () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (_) =>
                                                            const RegisterNewCompany())),
                                                style: ButtonStyle(
                                                    padding:
                                                        WidgetStateProperty.all(
                                                            EdgeInsets.zero),
                                                    foregroundColor:
                                                        WidgetStateProperty.all(
                                                      const Color(0xff072a99),
                                                    )),
                                                child: const Text(
                                                    "Register a New Company")),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: TextButton(
                                                onPressed: () async {
                                                  final prefs =
                                                      await SharedPreferences
                                                          .getInstance();
                                                  prefs.remove('app_version');
                                                  debugPrint(
                                                      'Standard EZHRM app: moving back to version selector screen');
                                                  Navigator.pushAndRemoveUntil(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            AppSelectorScreen()), // route name from your routes table
                                                    (Route<dynamic> route) =>
                                                        false, // removes all previous routes
                                                  );
                                                },
                                                style: ButtonStyle(
                                                    padding:
                                                        WidgetStateProperty.all(
                                                            EdgeInsets.zero),
                                                    foregroundColor:
                                                        WidgetStateProperty.all(
                                                      const Color(0xff072a99),
                                                    )),
                                                child: const Text(
                                                    "Change Version")),
                                          ),
                                        ])),
                          ]),
                    ),
                  ]),
            ),
          ),
          if (message == 'Login Successfully')
            SizedBox.expand(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xdd072a99),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LoadingAnimationWidget.fourRotatingDots(
                        size: 40,
                        color: Colors.white,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text("Successfully Logged In",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ]),
              ),
            )
        ],
      ),
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

class ForgotPasswordDialogBox extends StatelessWidget {
  const ForgotPasswordDialogBox(this.email, this.phone, this.submit,
      {super.key});
  final TextEditingController? email, phone;
  final VoidCallback? submit;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Card(
          margin: const EdgeInsets.all(12.0),
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Reset Password",
                      style: TextStyle(
                        color: Color(0xff072a99),
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                    ),
                  ),
                ),
                const Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 8),
                    child: Text("Enter your Email & Phone Number",
                        style: TextStyle(
                          color: Color(0xff072a99),
                        ))),
                CustomTextField(
                  hint: "Email",
                  controller: email,
                  textInputType: TextInputType.emailAddress,
                ),
                CustomTextField(
                  hint: "Phone Number",
                  controller: phone,
                  callBack: submit,
                  textInputType: TextInputType.phone,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (email!.text.isEmpty || phone!.text.isEmpty) {
                            return;
                          }
                          submit!();
                        },
                        style: ButtonStyle(
                          padding:
                              WidgetStateProperty.all(const EdgeInsets.all(15)),
                          shape: WidgetStateProperty.all(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                          backgroundColor: WidgetStateProperty.all(
                            const Color(0xff072a99),
                          ),
                          elevation: WidgetStateProperty.all(8),
                        ),
                        child: const Text("Get OTP"),
                      ),
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: ButtonStyle(
                              padding: WidgetStateProperty.all(EdgeInsets.zero),
                              foregroundColor: WidgetStateProperty.all(
                                const Color(0xff072a99),
                              )),
                          child: const Text("Close")),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
