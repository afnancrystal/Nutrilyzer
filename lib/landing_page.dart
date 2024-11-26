import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:food_analysis_app/food_api_services.dart';
import 'package:food_analysis_app/local_database_helper.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class DietTrackingPage extends StatefulWidget {
  @override
  State<DietTrackingPage> createState() => _DietTrackingPageState();
}

class _DietTrackingPageState extends State<DietTrackingPage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  String? _username;
  String? _email;
  bool _isLoading = true;

  // Nutrient values (default to 0)
  double _caloriesConsumed = 0;
  double _carbsConsumed = 0;
  double _proteinConsumed = 0;
  double _fatConsumed = 0;

  // Nutrient goals (default values can be set, allow user to change)
  double _caloriesGoal = 0;
  double _carbsGoal = 0;
  double _proteinGoal = 0;
  double _fatGoal = 0;

  // Store food items by type
  List<Map<String, dynamic>> _breakfastItems = [];
  List<Map<String, dynamic>> _lunchItems = [];
  List<Map<String, dynamic>> _dinnerItems = [];

  // Timer for daily reset
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadSavedGoals();
    _fetchTodaysFoodData();
    _setupMidnightReset();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  // Setup timer for midnight reset
  void _setupMidnightReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    _midnightTimer = Timer(timeUntilMidnight, () {
      _resetDailyValues();
      // Setup the next day's timer
      _setupMidnightReset();
    });
  }

  Future<void> _fetchUserData() async {
    try {
      String? token = await storage.read(key: 'jwtToken');
      String? username = await storage.read(key: 'username');
      String? email = await storage.read(key: 'email');
      if (token != null && username != null && email != null) {
        setState(() {
          _username = username;
          _email = email;
          _isLoading = false;
        });
      } else {
        Fluttertoast.showToast(
          msg: "Failed to fetch user data.",
          toastLength: Toast.LENGTH_LONG,
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e", toastLength: Toast.LENGTH_LONG);
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Reset all daily values at midnight
   void _resetDailyValues() {
    setState(() {
      _caloriesConsumed = 0;
      _carbsConsumed = 0;
      _proteinConsumed = 0;
      _fatConsumed = 0;
      _breakfastItems = [];
      _lunchItems = [];
      _dinnerItems = [];
    });
    _fetchTodaysFoodData();
  }

  // Load saved goals from storage
  Future<void> _loadSavedGoals() async {
    try {
      final calories = await storage.read(key: 'caloriesGoal');
      final carbs = await storage.read(key: 'carbsGoal');
      final protein = await storage.read(key: 'proteinGoal');
      final fat = await storage.read(key: 'fatGoal');

      setState(() {
        _caloriesGoal = double.tryParse(calories ?? '0') ?? 0;
        _carbsGoal = double.tryParse(carbs ?? '0') ?? 0;
        _proteinGoal = double.tryParse(protein ?? '0') ?? 0;
        _fatGoal = double.tryParse(fat ?? '0') ?? 0;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Error loading goals: $e");
    }
  }

  final FoodService _foodService = FoodService();
  // Fetch and process today's food data
  Future<void> _fetchTodaysFoodData() async {
    try {
   final foodItems = await await _foodService.getFood();
      final today = DateTime.now();
      
      // Filter for today's items only
      final todaysFoodItems = foodItems.where((item) {
        final itemDate = DateTime.parse(item['date_uploaded']);
        return itemDate.year == today.year && 
               itemDate.month == today.month && 
               itemDate.day == today.day;
      }).toList();

      // Reset daily consumed values at midnight
      double calories = 0;
      double carbs = 0;
      double protein = 0;
      double fat = 0;

      // Categorize items by meal type and calculate totals
      setState(() {
        _breakfastItems = todaysFoodItems.where((item) => item['type'].toLowerCase() == 'breakfast').toList();
        _lunchItems = todaysFoodItems.where((item) => item['type'].toLowerCase() == 'lunch').toList();
        _dinnerItems = todaysFoodItems.where((item) => item['type'].toLowerCase() == 'dinner').toList();

        // Calculate total nutrients consumed
        for (var item in todaysFoodItems) {
          calories += double.tryParse(item['calories'] ?? '0') ?? 0;
          carbs += double.tryParse(item['carbs'] ?? '0') ?? 0;
          protein += double.tryParse(item['protein'] ?? '0') ?? 0;
          fat += double.tryParse(item['fat'] ?? '0') ?? 0;
        }

        _caloriesConsumed = calories;
        _carbsConsumed = carbs;
        _proteinConsumed = protein;
        _fatConsumed = fat;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching food data: $e");
    }
  }

  // Modified _setNutrientGoal to save goals
  Future<void> _setNutrientGoal(String nutrient) async {
    TextEditingController controller = TextEditingController();
    double currentGoal = 0;

    switch (nutrient) {
      case 'Calories':
        currentGoal = _caloriesGoal;
        break;
      case 'Carbohydrates':
        currentGoal = _carbsGoal;
        break;
      case 'Protein':
        currentGoal = _proteinGoal;
        break;
      case 'Fat':
        currentGoal = _fatGoal;
        break;
    }

    controller.text = currentGoal.toString();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Set $nutrient Goal'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Enter goal for $nutrient'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Set Goal'),
              onPressed: () async {
                double newGoal = double.tryParse(controller.text) ?? currentGoal;
                // Save goal to storage
                String storageKey = '';
                setState(() {
                  switch (nutrient) {
                    case 'Calories':
                      _caloriesGoal = newGoal;
                      storageKey = 'caloriesGoal';
                      break;
                    case 'Carbohydrates':
                      _carbsGoal = newGoal;
                      storageKey = 'carbsGoal';
                      break;
                    case 'Protein':
                      _proteinGoal = newGoal;
                      storageKey = 'proteinGoal';
                      break;
                    case 'Fat':
                      _fatGoal = newGoal;
                      storageKey = 'fatGoal';
                      break;
                  }
                });
                await storage.write(key: storageKey, value: newGoal.toString());
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting and Streak (unchanged)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _username != null ? "Good Morning, $_username!" : '',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Great work this week! Peek @ your stats 👇",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Goals and Circular Progress Indicators 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCircularIndicator("Calories", _caloriesConsumed, _caloriesGoal, Colors.orange),
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _setNutrientGoal('Calories'),
                            ),
                            SizedBox(width: 6),
                            _buildCircularIndicator("Carbohydrates", _carbsConsumed, _carbsGoal, Colors.green),
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.green),
                              onPressed: () => _setNutrientGoal('Carbohydrates'),
                            ),
                            SizedBox(width: 10),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCircularIndicator("Protein", _proteinConsumed, _proteinGoal, Colors.blue),
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _setNutrientGoal('Protein'),
                            ),
                            SizedBox(width: 10),
                            _buildCircularIndicator("Fat", _fatConsumed, _fatGoal, Colors.red),
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.red),
                              onPressed: () => _setNutrientGoal('Fat'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Breakfast Section
             if( _breakfastItems.isNotEmpty)
                _buildMealSection("Breakfast", _breakfastItems),
              
              // Lunch Section
              if( _lunchItems.isNotEmpty)
                _buildMealSection("Lunch", _lunchItems),
              
              // Dinner Section
              if(_dinnerItems.isNotEmpty)
                _buildMealSection("Dinner", _dinnerItems),
            ],
          ),
        ),
      ),
    );
  }

int portion = 1;
  Widget _buildMealSection(String title, List<Map<String, dynamic>> items) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Text(
          title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      ...items.map((item) {
        // Parse volume, divide by 100 if necessary, and default to 1 if parsing fails
        double volume = double.tryParse(item['volume'].toString()) ?? 1;
        volume = volume / 100; // Divide volume by 100
        volume <=100 ? portion = 1 : portion = volume.round();
        return _buildFoodLogItem(
          item['name'],
          portion,
          "${item['carbs']}g", // Assuming carbs is a String
          item['calories'], // Assuming calories is a number
        );
      }).toList(),
    ],
  );
}


  Widget _buildCircularIndicator(String label, double current, double goal, Color color) {
    // If goal is 0, display "Set a Goal" instead of progress
    String centerText = goal == 0 ? "Set a Goal" : "${current.toStringAsFixed(0)}/$goal";
    double percentage = goal == 0 ? 0 : current / goal;

    return Column(
      children: [
        CircularPercentIndicator(
          radius: 50,
          lineWidth: 10,
          percent: percentage.clamp(0.0, 1.0),
          center: Text(
            centerText,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          progressColor: color,
          backgroundColor: Colors.grey[200]!,
          circularStrokeCap: CircularStrokeCap.round,
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildFoodLogItem(String title, int servings, String carbs, String calories, {bool isKetoFriendly = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isKetoFriendly ? Colors.green : Colors.grey,
            child: Icon(isKetoFriendly ? Icons.check : Icons.close, color: Colors.white),
          ),
          title: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Text("$servings Portion(s) - $carbs Carbs"),
          trailing: Text(
            "$calories Cal",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}