import 'package:flutter/material.dart';

import 'User Information/user_details.dart';

class PasswordSetupScreen extends StatefulWidget {
  final UserDetails userDetails;

  const PasswordSetupScreen({required this.userDetails, super.key});

  @override
  _PasswordSetupScreenState createState() => _PasswordSetupScreenState();
}

class _PasswordSetupScreenState extends State<PasswordSetupScreen> {
  final TextEditingController _passwordController = TextEditingController();

  void _savePassword() async {
    String password = _passwordController.text;
    if (password.isNotEmpty) {
      await widget.userDetails.savePassword(password);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Set Password')),
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
              onPressed: _savePassword,
              child: Text('Save Password'),
            ),
          ],
        ),
      ),
    );
  }
}
