import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:food_analysis_app/local_database_helper.dart';
import 'package:food_analysis_app/login_registration_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Dio dio = Dio();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  String? _username;
  String? _email;
  String? _phoneNumber;
  int? _age;
  bool _isLoading = true;
  bool isLoggedIn = false;
  bool _isEditing = false; // Flag to switch between viewing and editing modes

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      // Retrieve the stored JWT token, username, and email
      String? token = await storage.read(key: 'jwtToken');
      String? username = await storage.read(key: 'username');
      String? email = await storage.read(key: 'email');

      // Check if token, username, and email are not null
      if (token != null && username != null && email != null) {
        setState(() {
          _username = username;
          _email = email;
          _isLoading = false; // Set loading to false when data is fetched successfully
        });
      } else {
        Fluttertoast.showToast(
          msg: "Failed to fetch user data.",
          toastLength: Toast.LENGTH_LONG,
        );
        setState(() {
          _isLoading = false; // Ensure loading is set to false in case of failure
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e", toastLength: Toast.LENGTH_LONG);
      setState(() {
        _isLoading = false; // Ensure loading is set to false in case of error
      });
    }
  }


  Future<void> _saveUserInfo() async {
    if (_phoneController.text.isNotEmpty && _ageController.text.isNotEmpty) {
      final updatedUser = {
        DatabaseHelper.columnUsername: _username,
        DatabaseHelper.columnEmail: _email,
        DatabaseHelper.columnPhoneNumber: _phoneController.text,
        DatabaseHelper.columnAge: int.tryParse(_ageController.text) ?? 0,
      };

      await dbHelper.update(updatedUser);
      Fluttertoast.showToast(msg: "User information updated.");
      setState(() {
        _isEditing = false;
      });
    } else {
      Fluttertoast.showToast(msg: "Please fill all fields.");
    }
  }

  void _logout() async {
    await storage.delete(key: 'jwtToken');
    await storage.delete(key: 'refreshToken');
    await storage.delete(key: 'username');
    await storage.delete(key: 'email');
    setState(() {
      isLoggedIn = false;
    });
    Fluttertoast.showToast(msg: "Successfully logged out");
    _goToLoginPage();
  }

  void _goToLoginPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreenNotLoggedIn()),
    );
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(_username != null ? "Hi, $_username" : ''),
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0, // Removes shadow 
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView( // Makes the content scrollable
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Picture Section
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(
                          "https://cdn-icons-png.flaticon.com/512/5951/5951752.png",
                        ),
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: () {
                              // TODO: Implement image picker
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // User Info Cards
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.person,
                            'Name',
                            _username ?? '',
                            context,
                          ),
                          _buildInfoRow(
                            Icons.email,
                            'Email',
                            _email ?? '',
                            context,
                          ),
                          _buildInfoRow(
                            Icons.phone,
                            'Phone',
                            '+1 234 567 8900', // Replace with actual phone
                            context,
                          ),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Age',
                            '28 years', // Replace with actual age
                            context,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Diet Information Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Diet Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.height,
                            'Height',
                            '175 cm', // Replace with actual height
                            context,
                          ),
                          _buildInfoRow(
                            Icons.monitor_weight,
                            'Current Weight',
                            '70 kg', // Replace with actual weight
                            context,
                          ),
                          _buildInfoRow(
                            Icons.track_changes,
                            'Target Weight',
                            '65 kg', // Replace with actual target
                            context,
                          ),
                          _buildInfoRow(
                            Icons.restaurant_menu,
                            'Diet Preferences',
                            'Vegetarian, Low Carb', // Replace with actual preferences
                            context,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
  );
}

// Helper method to build consistent info rows
Widget _buildInfoRow(IconData icon, String label, String value, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () {
            // TODO: Implement edit functionality
          },
        ),
      ],
    ),
  );
}
}

