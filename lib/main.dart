import 'package:flutter/material.dart';
import 'package:food_analysis_app/home_page.dart';

const Color appGreen = Color(0xFF4CAF50);
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Glucocheck',
      //default purple, but changes to green with this code
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: appGreen,
        ),
      ),
      home: HomeScreen(),
    );
  }
}
