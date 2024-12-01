import 'package:flutter/material.dart';
import 'mongodb.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final MongoDatabase _dbHelper = MongoDatabase();

  void _signup() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    bool isTaken = await _dbHelper.isUsernameTaken(username);

    if (isTaken) {
      _showMessage('Username already taken');
    } else {
      await _dbHelper.registerUser(username, password);
      _showMessage('Signup successful! Please login.');
      Navigator.pop(context); // Navigate back to login screen
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Signup'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: _signup,
              child: Text('Signup'),
            ),
          ],
        ),
      ),
    );
  }
}
