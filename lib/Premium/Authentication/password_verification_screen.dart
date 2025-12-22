import 'package:ezhrm/Premium/Authentication/password_setup_screen.dart';
import 'package:flutter/material.dart';
import '../Dependency_Injection/dependency_injection.dart';
import 'User Information/user_details.dart';

class PasswordVerificationScreen extends StatefulWidget {
  final UserDetails userDetails;
  const PasswordVerificationScreen({required this.userDetails, super.key});

  @override
  _PasswordVerificationScreenState createState() =>
      _PasswordVerificationScreenState();
}

class _PasswordVerificationScreenState
    extends State<PasswordVerificationScreen> {
  final TextEditingController _passwordController = TextEditingController();

  void _verifyPassword() async {
    String? savedPassword = await widget.userDetails.getPassword();
    if (_passwordController.text == savedPassword) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProtectedScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect Password!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Enter Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyPassword,
              child: Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProtectedScreen extends StatelessWidget {
  const ProtectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Protected Screen')),
      body: Center(child: Text('Welcome to the protected screen!')),
    );
  }
}

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Required for async initialization
  setupDependencies(); // Initialize GetIt dependencies

  String? savedPassword = await getIt<UserDetails>().getPassword();

  runApp(MaterialApp(
    home: savedPassword == null
        ? PasswordSetupScreen(userDetails: getIt<UserDetails>())
        : PasswordVerificationScreen(userDetails: getIt<UserDetails>()),
  ));
}
