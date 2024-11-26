import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FoodService {
  Dio dio = Dio();

  final FlutterSecureStorage storage = FlutterSecureStorage();

  FoodService() {
    dio.options.baseUrl =
    'https://nutrilyzer.online';
   
    dio.options.headers['Content-Type'] = 'application/json';
    // interceptor for debugging
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  Future<bool> postFood(Map<String, dynamic> foodData) async {
    dio.options.connectTimeout = Duration(milliseconds: 10000);
    dio.options.receiveTimeout = Duration(milliseconds: 10000);
    String? token = await storage.read(key: 'jwtToken');
    dio.options.headers['Authorization'] = 'Bearer $token';
    Map<String, dynamic> nutritionalInfo =
        json.decode(foodData['nutritional_info']);

    foodData = {
      'name': foodData['name'],
      'type': foodData['type'],
      'volume': double.tryParse(foodData['volume'].split(' ')[0]),
      'calories': double.tryParse(nutritionalInfo['calories'].split(' ')[0]),
      'carbs': double.tryParse(nutritionalInfo['carbs'].split(' ')[0]),
      'fat': double.tryParse(nutritionalInfo['fat'].split(' ')[0]),
      'protein': double.tryParse(nutritionalInfo['protein'].split(' ')[0]),
      "date_uploaded": foodData['upload_date']
    };
    try {
      var payload = {
        'foods': [foodData]
      };

      final response = await dio.post(
        '/food/food-items',
        data: payload,
      );

      return response.statusCode == 201;
    } on DioError catch (e) {
      throw Exception(
          'Failed to save food items: ${e.response?.data ?? e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> getFood() async {
    String? token = await storage.read(key: 'jwtToken');
    dio.options.headers['Authorization'] = 'Bearer $token';
    dio.options.headers['Content-Type'] = 'application/json';
    dio.options.headers['Accept'] = 'application-json';
    try {
      // Send a GET request to retrieve food data
      final response = await dio.get('/food/food-items');
      print(response);

      // Check if the response status code is 200 (OK)
      if (response.statusCode == 200) {
        List<dynamic> foodList = response.data;

        // Create a list to store the final food data with nutritional info
        List<Map<String, dynamic>> foodDataList = [];

        // Iterate over each food item
        for (var food in foodList) {
          // Prepare the basic food info, directly mapping data from the response
          Map<String, dynamic> foodData = {
            'name': food['name'], // 'name' is a string
            'type': food['food_type'], // 'food_type' is a string
            'volume': food['volume']
                .toString(), // 'volume' is a number, so convert it to string
            'date_uploaded': food[
                'date_uploaded'], // 'date_uploaded' should be a string (ISO format)
          };

          // Map nutritional data directly from the response
          var nutritionalInfo = food['nutrition'];

          // Add nutritional info to the food data, using fallback if any field is missing
          foodData.addAll({
            'calories': nutritionalInfo['calories']?.toString() ??
                'N/A', // Ensure 'calories' exists, else 'N/A'
            'carbs': nutritionalInfo['carbs']?.toString() ??
                'N/A', // Ensure 'carbs' exists, else 'N/A'
            'fat': nutritionalInfo['fat']?.toString() ??
                'N/A', // Ensure 'fat' exists, else 'N/A'
            'protein': nutritionalInfo['protein']?.toString() ??
                'N/A', // Ensure 'protein' exists, else 'N/A'
          });

          // Add the processed food data to the list
          foodDataList.add(foodData);
        }

        // print('Fetched food data with nutritional info: $foodDataList');
        return foodDataList;
      } else {
        throw Exception('Failed to load food items');
      }
    } on DioError catch (e) {
      throw Exception(
          'Failed to fetch food items: ${e.response?.data ?? e.message}');
    }
  }

  Future<bool> repostFood(Map<String, dynamic> foodData) async {
    String? token = await storage.read(key: 'jwtToken');
    dio.options.headers['Authorization'] = 'Bearer $token';

    try {
      var payload = {
        'foods': [foodData]
      };
    

      final response = await dio.post(
        '/food/food-items',
        data: payload,
      );
      return response.statusCode == 201;
    } on DioError catch (e) {
      throw Exception(
          'Failed to save food items: ${e.response?.data ?? e.message}');
    }
  }

  Future<bool> testConnection() async {
    try {
      final response = await dio.get('/test');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
