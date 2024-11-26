import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:food_analysis_app/food_data_screen.dart';
import 'package:food_analysis_app/login_registration_page.dart';
import 'package:food_analysis_app/metrics_page.dart';
import 'package:food_analysis_app/landing_page.dart'; // Import DietTrackingPage
import 'profile_screen.dart'; // ProfilePage

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Default index is 0 (Food Data Page)

  // Updated the list of pages to ensure it contains the right number of pages
  final List<Widget> _children = [
     DietTrackingPage(), // Diet Tracking Page
    const FoodDataScreen(), // Page for Food Data
    const MetricsPage(), // Page for Metrics

    const ProfileScreen(), // Page for Profile
  ];

  bool isLoggedIn = false; // To track if the user is logged in

  var storage = const FlutterSecureStorage();

  // Check if user is logged in on startup
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    String? token = await storage.read(key: 'jwtToken');
    setState(() {
      isLoggedIn = token != null && token.isNotEmpty;
    });
  }

  // Handle bottom navigation bar item taps
  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glucocheck'),
      ),
      body: isLoggedIn
          ? _children[_currentIndex] // Show main content after login
          : const HomeScreenNotLoggedIn(), // Show login screen if not logged in
      bottomNavigationBar: isLoggedIn
          ? BottomNavigationBar(
              onTap: onTabTapped,
              currentIndex: _currentIndex,
              backgroundColor: Theme.of(context)
                  .primaryColor, // Set the background color explicitly
              selectedItemColor:
                  Theme.of(context).primaryColor, // Set color for selected icon
              unselectedItemColor: Theme.of(context)
                  .primaryColor, // Set color for unselected icons
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.fastfood), // Icon for Diet Tracking
                  label: 'Diet Tracking', // Label for Diet Tracking
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.food_bank),
                  label: 'Food Data',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.show_chart),
                  label: 'Metrics',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle),
                  label: 'Profile',
                ),
              ],
            )
          : null, // Hide the bottom nav bar if not logged in
    );
  }
}
