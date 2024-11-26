import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:food_analysis_app/home_page.dart';
import 'package:food_analysis_app/metrics_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'food_api_services.dart'; 
import 'profile_screen.dart'; //  ProfilePage

// a screen for users who aren't logged in to switch between Login and Registration
class HomeScreenNotLoggedIn extends StatefulWidget {
  const HomeScreenNotLoggedIn({super.key});

  @override
  _HomeScreenNotLoggedInState createState() => _HomeScreenNotLoggedInState();
}

class _HomeScreenNotLoggedInState extends State<HomeScreenNotLoggedIn> {
  int _currentIndex = 0;
  final List<Widget> _children = [
    const RegistrationScreen(),
    const LoginScreen(),
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome!'),
      ),
      body: _children[
          _currentIndex], // Show Registration or Login based on tab index
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Register',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.login),
            label: 'Login',
          ),
        ],
      ),
    );
  }
}

// Registration Screen (Same as your existing one)
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final Dio dio = Dio();
  var storage = const FlutterSecureStorage();

  bool isValidLength = false;
  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasDigit = false;
  bool hasSpecialCharacter = false;
  final FocusNode _passwordFocusNode =
      FocusNode(); // Focus node for password field
  bool _isPasswordFieldTapped = false; // Tracks if password field is tapped
  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      setState(() {
        // Shows requirements only if the password field is focused
        _isPasswordFieldTapped = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose(); // Disposes the FocusNode when done
    super.dispose();
  }

  Future<void> registerToLoginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    dio.options.headers['Content-Type'] = 'application/json';
    dio.options.headers['Accept'] = 'application-json';
    var url =
        'https://nutrilyzer.online/auth-user/login';
    var data = {
      'email': usernameController.text.trim(),
      'password': passwordController.text,
    };
    try {
      var response = await dio.post(url, data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseData = response.data;
        if (responseData != null &&
            responseData['access_token'] != null &&
            responseData['refresh_token'] != null &&
            responseData['user']['first_name'] != null &&
            responseData['user']['email'] != null) {
          String token = responseData['access_token'];
          String refreshToken = responseData['refresh_token'];
          String first_name = responseData['user']['first_name'];
          String email = responseData['user']['email'];
          await storage.write(key: 'jwtToken', value: token);
          await storage.write(key: 'refreshToken', value: refreshToken);
          await storage.write(key: 'username', value: first_name);
          await storage.write(key: 'email', value: email);
          Fluttertoast.showToast(
              msg: "Login Successful", toastLength: Toast.LENGTH_SHORT);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          Fluttertoast.showToast(
              msg: "Failed to retrieve token.", toastLength: Toast.LENGTH_LONG);
        }
      } else {
        Fluttertoast.showToast(
            msg: "Login Failed: Status Code ${response.statusCode}",
            toastLength: Toast.LENGTH_LONG);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e", toastLength: Toast.LENGTH_LONG);
    }
  }

  Future<void> registerUser() async {
    if (_formKey.currentState!.validate()) {
      var url =
          'https://nutrilyzer.online/auth-user/register';
      var data = {
        'email': usernameController.text.trim(),
        'first_name': firstnameController.text,
        'last_name': lastnameController.text,
        'password': passwordController.text,
      };
      try {
        var response = await dio.post(url, data: data);

        if (response.statusCode == 200 || response.statusCode == 201) {
          Fluttertoast.showToast(
            msg: "Registration Successful",
            toastLength: Toast.LENGTH_SHORT,
          );
          registerToLoginUser();
        } else {
          // Handle server error responses with detailed message from response
          String errorMessage = response.data['error'] ?? 'Unknown error';
          Fluttertoast.showToast(
            msg: "Registration Failed: $errorMessage",
            toastLength: Toast.LENGTH_LONG,
          );
        }
      } catch (e) {
        print("$e");
        // Checks for DioError type and display a more detailed message
        if (e is DioError) {
          if (e.response != null) {
            // Shows detailed error returned by the server 
            String errorDetail = e.response?.data['error'] ?? 'Unknown error';
            Fluttertoast.showToast(
              msg: "Error: $errorDetail",
              toastLength: Toast.LENGTH_LONG,
            );
          } else {
            // Handles cases where the error is not related to the server response (e.g., network issues)
            Fluttertoast.showToast(
              msg: "Error: ${e.message}",
              toastLength: Toast.LENGTH_LONG,
            );
          }
        } else {
          // Handles any other error
          Fluttertoast.showToast(
            msg: "Error: $e",
            toastLength: Toast.LENGTH_LONG,
          );
        }
      }
    }
  }

  // Function to check password requirements
  void validatePassword(String password) {
    setState(() {
      isValidLength = password.length >= 8;
      hasUppercase = password.contains(RegExp(r'[A-Z]'));
      hasLowercase = password.contains(RegExp(r'[a-z]'));
      hasDigit = password.contains(RegExp(r'[0-9]'));
      hasSpecialCharacter =
          password.contains(RegExp(r'[@$!%*?&#]'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: <Widget>[
            TextFormField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            TextFormField(
              controller: firstnameController,
              decoration: const InputDecoration(labelText: 'First Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your first name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: lastnameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your last name';
                }
                return null;
              },
            ),
            Column(
              children: [
                TextFormField(
                  controller: passwordController,
                  focusNode: _passwordFocusNode,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  onChanged: validatePassword, // Call validate on change
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                if (_isPasswordFieldTapped)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPasswordRequirement(
                          'Minimum 8 characters', isValidLength),
                      _buildPasswordRequirement(
                          'At least one uppercase letter', hasUppercase),
                      _buildPasswordRequirement(
                          'At least one lowercase letter', hasLowercase),
                      _buildPasswordRequirement('At least one digit', hasDigit),
                      _buildPasswordRequirement(
                          'At least one special character: @\$!%*?&#',
                          hasSpecialCharacter),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: registerUser,
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildPasswordRequirement(String requirement, bool isValid) {
  return Row(
    children: [
      Icon(
        isValid ? Icons.check_circle : Icons.cancel,
        color: isValid ? Colors.green : Colors.red,
      ),
      const SizedBox(width: 8),
      Text(requirement, style: TextStyle(fontSize: 14)),
    ],
  );
}

// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final Dio dio = Dio();
  final _formKey = GlobalKey<FormState>();
  var storage = const FlutterSecureStorage();

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // dio.options.followRedirects =true;
    dio.options.headers['Content-Type'] = 'application/json';
    dio.options.headers['Accept'] = 'application-json';
    var url =
        'https://nutrilyzer.online/auth-user/login';
    var data = {
      'email': usernameController.text.trim(),
      'password': passwordController.text,
    };

    try {
      var response = await dio.post(url, data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseData = response.data;
        if (responseData != null &&
            responseData['access_token'] != null &&
            responseData['refresh_token'] != null &&
            responseData['user']['first_name'] != null &&
            responseData['user']['email'] != null) {
          String token = responseData['access_token'];
          String refreshToken = responseData['refresh_token'];
          String first_name = responseData['user']['first_name'];
          String email = responseData['user']['email'];
          await storage.write(key: 'jwtToken', value: token);
          await storage.write(key: 'refreshToken', value: refreshToken);
          await storage.write(key: 'username', value: first_name);
          await storage.write(key: 'email', value: email);
          Fluttertoast.showToast(
              msg: "Login Successful", toastLength: Toast.LENGTH_SHORT);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          Fluttertoast.showToast(
              msg: "Failed to retrieve token.", toastLength: Toast.LENGTH_LONG);
        }
      } else {
        Fluttertoast.showToast(
            msg: "Login Failed: Status Code ${response.statusCode}",
            toastLength: Toast.LENGTH_LONG);
      }
    } catch (e) {
      print(e);
      Fluttertoast.showToast(msg: "Error: $e", toastLength: Toast.LENGTH_LONG);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: <Widget>[
            Card(
              child: TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
              ),
            ),
            Card(
              child: TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loginUser,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
