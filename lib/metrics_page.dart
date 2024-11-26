import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:food_analysis_app/food_api_services.dart';
import 'package:intl/intl.dart';

class MetricsPage extends StatefulWidget {
  const MetricsPage({Key? key}) : super(key: key);

  @override
  _MetricsPageState createState() => _MetricsPageState();
}

class _MetricsPageState extends State<MetricsPage> {
  List<Map<String, dynamic>> _foodData = [];
  final FoodService _foodService = FoodService();
  String _selectedType = 'All';
  List<String> _foodTypes = ['All'];

  @override
  void initState() {
    super.initState();
    _loadFoodData();
  }

  Future<void> _loadFoodData() async {
    try {
      final data = await _foodService.getFood();
      final types = ['All']..addAll(
          data.map((item) => item['type'].toString().trim()).toSet().toList()
      );
      
      setState(() {
        _foodData = data;
        _foodTypes = types;
      });
      print('Loaded food data: $_foodData'); // Debug print
    } catch (e) {
      print('Error loading food data: $e');
    }
  }

  double _parseValue(dynamic value) {
    if (value == null || value == 'N/A') return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing value: $value');
        return 0.0;
      }
    }
    return 0.0;
  }

  List<Map<String, dynamic>> _getProcessedData() {
    // Filter by type if needed
    final filteredData = _selectedType == 'All'
        ? _foodData
        : _foodData.where((item) => item['type'] == _selectedType).toList();

    // Group by date
    final Map<String, Map<String, dynamic>> dailyData = {};
    
    for (var item in filteredData) {
      final date = DateFormat('yyyy-MM-dd').format(
        DateTime.parse(item['date_uploaded'].toString())
      );
      
      if (!dailyData.containsKey(date)) {
        dailyData[date] = {
          'date': date,
          'calories': 0.0,
          'carbs': 0.0,
          'fat': 0.0,
          'protein': 0.0,
        };
      }

      // Safely parse and add values
      dailyData[date]!['calories'] += _parseValue(item['calories']);
      dailyData[date]!['carbs'] += _parseValue(item['carbs']);
      dailyData[date]!['fat'] += _parseValue(item['fat']);
      dailyData[date]!['protein'] += _parseValue(item['protein']);
    }

    return dailyData.values.toList()
      ..sort((a, b) => a['date'].compareTo(b['date']));
  }
  
double getNiceInterval(double range) {
  // Check if range is zero to prevent division by zero
  if (range == 0) {
    return 1.0;
  }

  double roughInterval = range / 4;
  double magnitude = pow(10, (log(roughInterval) / ln10).floor()).toDouble();
  double normalizedInterval = roughInterval / magnitude;
  
  double niceInterval;
  if (normalizedInterval < 1.5) {
    niceInterval = 1;
  } else if (normalizedInterval < 3) {
    niceInterval = 2;
  } else if (normalizedInterval < 7) {
    niceInterval = 5;
  } else {
    niceInterval = 10;
  }
  
  return niceInterval * magnitude;
}

Widget _buildLineChart(String nutrient, Color color) {
  try {
    final data = _getProcessedData();
    if (data.isEmpty) return const Center(child: Text('No data available'));

    // Debug print
    print('Processing data for $nutrient: $data');

    final spots = data.asMap().entries.map((entry) {
      final value = _parseValue(entry.value[nutrient.toLowerCase()]);
      return FlSpot(entry.key.toDouble(), value);
    }).toList();

    if (spots.isEmpty) {
      return const Center(child: Text('No data available for the selected nutrient'));
    }

    // Find max value for Y axis
    final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    
    // Check if maxY is finite, otherwise set a default value
    if (maxY.isInfinite || maxY.isNaN) {
      return const Center(child: Text('Invalid data encountered'));
    }

    // Add 10% padding and round up
    final range = maxY * 1.1;
    final interval = getNiceInterval(range);
    
    // Round up max Y to next interval
    final adjustedMaxY = (range / interval).ceil() * interval;

    return AspectRatio(
      aspectRatio: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: adjustedMaxY.toDouble(),
            clipData: FlClipData.all(),
            gridData: FlGridData(
              show: true,
              horizontalInterval: interval,
              checkToShowHorizontalLine: (value) {
                // Show lines at multiples of the interval
                return (value % interval).abs() < 0.001;
              },
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= data.length) return const Text('');
                    final date = data[value.toInt()]['date'].toString();
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        DateFormat('MM/dd').format(DateTime.parse(date)),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: interval,
                  getTitlesWidget: (value, meta) {
                    // Only show values at interval points
                    if ((value % interval).abs() >= 0.001) return const Text('');
                    return Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: color,
                barWidth: 3,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
    );
  } catch (e) {
    print('Error building chart: $e');
    return Center(child: Text('Error: $e'));
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nutrition Metrics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedType,
                    items: _foodTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedType = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _foodData.isEmpty
                  ? const Center(child: Text('Add some food to see metrics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal)))
                  //const Center(child: CircularProgressIndicator())
                  : DefaultTabController(
                      length: 4,
                      child: Column(
                        children: [
                          const TabBar(
                            tabs: [
                              Tab(text: 'Calories'),
                              Tab(text: 'Protein'),
                              Tab(text: 'Carbs'),
                              Tab(text: 'Fat'),
                            ],
                            labelColor: Colors.black,
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildLineChart('Calories', Colors.orange),
                                _buildLineChart('Protein', Colors.blue),
                                _buildLineChart('Carbs', Colors.green),
                                _buildLineChart('Fat', Colors.red),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}