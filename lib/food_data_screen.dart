import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'food_api_services.dart';

class FoodDataScreen extends StatefulWidget {
  const FoodDataScreen({Key? key}) : super(key: key);

  @override
  _FoodDataScreenState createState() => _FoodDataScreenState();
}

class _FoodDataScreenState extends State<FoodDataScreen> {
  Map<String, List<Map<String, dynamic>>> _groupedFoodData = {
    'breakfast': [],
    'lunch': [],
    'dinner': [],
    'snack': [],
  };
  DateTime _selectedDate = DateTime.now();
  String? _expandedCategory;
  final FoodService _foodService = FoodService();
  Dio dio = Dio();

  @override
  void initState() {
    super.initState();
    _loadFoodData();
  }

  Future<void> _loadFoodData() async {
    final data = await _foodService.getFood();

    Map<String, List<Map<String, dynamic>>> grouped = {
      'breakfast': [],
      'lunch': [],
      'dinner': [],
      'snack': [],
    };

    for (var item in data) {
      DateTime itemDate = DateTime.parse(item['date_uploaded']);
      if (DateUtils.isSameDay(itemDate, _selectedDate)) {
        String type = (item['type'] ?? '').toLowerCase();
        type = type.trim();
        if (['breakfast', 'lunch', 'dinner'].contains(type)) {
          grouped[type]!.add(item);
        } else {
          grouped['snack']!.add(item);
        }
      }
    }

    setState(() {
      _groupedFoodData = grouped;
    });
  }

  Future<void> _uploadFoodData(
      Map<String, dynamic> foodData, BuildContext context) async {
    // Open the calendar widget to select the date and time
    DateTime? selectedDateTime = await _pickDateTime(context);

    // If a valid date-time is selected
    if (selectedDateTime != null) {
      // Update the food data with the selected date-time
      foodData['date_uploaded'] = selectedDateTime.toIso8601String();
      foodData['volume'].toString().toLowerCase() == 'null' ? foodData['volume'] = 1 : foodData['volume'] = foodData['volume'];

      // Repost the food data
      await _foodService.repostFood(foodData);

      // Reload food data 
      _loadFoodData();
    }
  }

// Method to open a date and time picker
  Future<DateTime?> _pickDateTime(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      // Show time picker after selecting date
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(pickedDate),
      );

      if (pickedTime != null) {
        // Combine the selected date and time into a DateTime object
        return DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }

    // If no valid date and time are selected, return null
    return null;
  }

  Widget _buildFoodCard(Map<String, dynamic> item) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name: ${item['name']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  item['volume'].toString().toLowerCase() == 'null' ? Text('Volume: 1') : Text('Volume: ${item['volume']}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Nutritional Information:',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Calories: ${item['calories']}',
                      style: const TextStyle(fontSize: 16)),
                  Text('Carbohydrates: ${item['carbs']}',
                      style: const TextStyle(fontSize: 16)),
                  Text('Fat: ${item['fat']}',
                      style: const TextStyle(fontSize: 16)),
                  Text('Protein: ${item['protein']}',
                      style: const TextStyle(fontSize: 16)),
                  Text(
                    'Uploaded on: ${DateFormat.yMd().add_jm().format(
                          DateTime.parse(item['date_uploaded']),
                        )}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
              onPressed: () => _uploadFoodData(item, context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
      String category, List<Map<String, dynamic>> items) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: _expandedCategory == category,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedCategory = expanded ? category : null;
          });
        },
        title: Text(
          category.capitalize(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: items.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No items yet'),
                )
              ]
            : items.map((item) => _buildFoodCard(item)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  centerTitle: true,
                  title: const Text('Food Data'),
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset('assets/icons/app_icon2.png'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: TableCalendar(
                    firstDay:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _selectedDate,
                    selectedDayPredicate: (day) =>
                        isSameDay(_selectedDate, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDate = selectedDay;
                        _loadFoodData();
                      });
                    },
                    calendarFormat: CalendarFormat.week,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    _groupedFoodData.entries
                        .map((entry) =>
                            _buildCategorySection(entry.key, entry.value))
                        .toList(),
                  ),
                ),
                // Add extra space at the bottom for the floating action button
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ImagePickerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Log Food',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({Key? key}) : super(key: key);

  @override
  _ImagePickerScreenState createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Initialize as mutable lists
  List<Map<String, dynamic>> _resultData = [];
  List<DateTime> _uploadDates = [];
  String _errorMessage = '';

  // Temporary variables to store nutritional data
  double? volumePerCount;
  double? caloriesPerCount;
  double? carbsPerCount;
  double? proteinPerCount;
  double? fatPerCount;
  final FlutterSecureStorage storage = FlutterSecureStorage();

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      // Clear mutable lists
      _resultData.clear();
      _uploadDates.clear();
      _errorMessage = '';
      _imageFile = null; // Clear the existing image
    });

    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Function to extract the numeric part of a string
  double extractNumericValue(String value) {
    // Match the first sequence of digits (including decimal point if present)
    final match = RegExp(r'(\d*\.?\d+)').firstMatch(value);
    return match != null ? double.tryParse(match.group(1) ?? '0') ?? 0.0 : 0.0;
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = ''; // Clear the previous error message

      _resultData.clear();
      _uploadDates.clear();
    });

    String fileName = _imageFile!.path.split('/').last;
    FormData formData = FormData.fromMap({
      "image":
          await MultipartFile.fromFile(_imageFile!.path, filename: fileName),
    });
    String? token = await storage.read(key: 'jwtToken');
    Dio dio = Dio();
         dio.options.headers['Authorization'] = 'Bearer $token';

    try { 

      final response = await dio.post(
    'https://nutrilyzer.online/image-information/analyze',
        data: formData,
      );

      final jsonResponse = json.decode(response.data);

      if (jsonResponse['foods'] != null && jsonResponse['foods'] is List) {
        setState(() {
          _resultData = List<Map<String, dynamic>>.from(jsonResponse['foods']);
          _uploadDates = List<DateTime>.generate(
              _resultData.length, (index) => DateTime.now());

          // Loop through each food item and print the calculated values
          for (var item in _resultData) {
            int count = int.tryParse(item['count'].toString()) ?? 1;

            item['per_unit'] = {
              'volume': extractNumericValue(item['volume']) / count,
              'calories':
                  extractNumericValue(item['nutritional_info']['calories']) /
                      count,
              'carbs': extractNumericValue(item['nutritional_info']['carbs']) /
                  count,
              'protein':
                  extractNumericValue(item['nutritional_info']['protein']) /
                      count,
              'fat':
                  extractNumericValue(item['nutritional_info']['fat']) / count,
            };

            // Print calculated values for each food item
            print('Food Item: ${item['name']}');
            print('Volume per count: ${item['per_unit']['volume']}');
            print('Calories per count: ${item['per_unit']['calories']}');
            print('Carbs per count: ${item['per_unit']['carbs']}');
            print('Protein per count: ${item['per_unit']['protein']}');
            print('Fat per count: ${item['per_unit']['fat']}');
          }
        });
      } else {
        setState(() {
          _errorMessage =
              'No food items found in the response. Please try again.';
        });
      }
    } on DioException catch (dioError) {
      if (dioError.response != null) {
        // Check if the server responded with an error message
        print(dioError.response!.data);

        String errorMsg = dioError.response!.data['message'] ??
            dioError.response!.data['error'] ??
            'An unknown error occurred.';
        setState(() {
          _errorMessage = 'Server error: $errorMsg';
        });
      } else {
        // If no response is received (e.g. due to network error)
        setState(() {
          _errorMessage =
              'Could not reach the server. Please check your connection and try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'There was a problem with the response. Please try again, perhaps with a more relevant image.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  final FoodService _foodService = FoodService();
  Future<void> _saveDataToDatabase() async {
    if (_resultData.isEmpty) return;

    // Save each item to the database
    for (var item in _resultData) {
      Map<String, dynamic> row = {
        'name': item['name'],
        'type': item['type'],
        'volume': item['volume'],
        'count': item['count'],
        'nutritional_info': json.encode(item['nutritional_info']),
        'upload_date': _uploadDates[_resultData.indexOf(item)]
            .toIso8601String() 
      };
      // Save to database
      await _foodService.postFood(row);
    }

    // Show a snackbar to notify the user that the data was saved successfully
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data saved to database!')),
    );

    // Navigate to the HomePage after saving the data
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => const FoodDataScreen()), // Redirect to HomePage
    );
  }

  Future<void> _deleteItem(int index) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      setState(() {
        _resultData.removeAt(index); // Remove the item from the list
        _uploadDates.removeAt(index); // Remove the corresponding upload date
      });
    }
  }

  Future<void> _editItem(int index) async {
    final item =
        Map<String, dynamic>.from(_resultData[index]); // Create a copy
    final perUnitValues = item['per_unit'] ??
        {
          'volume': extractNumericValue(item['volume']) /
              (double.tryParse(item['count'].toString()) ?? 1.0),
          'calories':
              extractNumericValue(item['nutritional_info']['calories']) /
                  (double.tryParse(item['count'].toString()) ?? 1.0),
          'carbs': extractNumericValue(item['nutritional_info']['carbs']) /
              (double.tryParse(item['count'].toString()) ?? 1.0),
          'protein': extractNumericValue(item['nutritional_info']['protein']) /
              (double.tryParse(item['count'].toString()) ?? 1.0),
          'fat': extractNumericValue(item['nutritional_info']['fat']) /
              (double.tryParse(item['count'].toString()) ?? 1.0),
        };

    Map<String, dynamic> editedItem = Map<String, dynamic>.from(item);
    editedItem['nutritional_info'] =
        Map<String, dynamic>.from(item['nutritional_info']);

    // Extract units from original values
    final volumeMatch = RegExp(r'(\d*\.?\d+)(\s*([a-zA-Z]+))?')
        .firstMatch(item['volume'].toString());
    final proteinMatch = RegExp(r'(\d*\.?\d+)(\s*([a-zA-Z]+))?')
        .firstMatch(item['nutritional_info']['protein'].toString());
    final fatMatch = RegExp(r'(\d*\.?\d+)(\s*([a-zA-Z]+))?')
        .firstMatch(item['nutritional_info']['fat'].toString());
    final carbsMatch = RegExp(r'(\d*\.?\d+)(\s*([a-zA-Z]+))?')
        .firstMatch(item['nutritional_info']['carbs'].toString());
    final caloriesMatch = RegExp(r'(\d*\.?\d+)(\s*([a-zA-Z]+))?')
        .firstMatch(item['nutritional_info']['calories'].toString());

    String volumeUnit = volumeMatch?.group(3) ?? '';
    String proteinUnit = proteinMatch?.group(3) ?? '';
    String fatUnit = fatMatch?.group(3) ?? '';
    String carbsUnit = carbsMatch?.group(3) ?? '';
    String caloriesUnit = caloriesMatch?.group(3) ?? '';

    // Create controllers with current values
    final nameController = TextEditingController(text: item['name']);
    final typeController = TextEditingController(text: item['type']);
    final countController =
        TextEditingController(text: item['count'].toString());

    // Initialize controllers with current values (not per-unit values)
    final volumeController = TextEditingController(
        text: extractNumericValue(item['volume']).toString());
    final caloriesController = TextEditingController(
        text: extractNumericValue(item['nutritional_info']['calories'])
            .toString());
    final carbsController = TextEditingController(
        text:
            extractNumericValue(item['nutritional_info']['carbs']).toString());
    final fatController = TextEditingController(
        text: extractNumericValue(item['nutritional_info']['fat']).toString());
    final proteinController = TextEditingController(
        text: extractNumericValue(item['nutritional_info']['protein'])
            .toString());

    TextEditingController dateController = TextEditingController(
      text: DateFormat.yMd().add_jm().format(_uploadDates[index]),
    );

    // Function to update all nutritional values based on count
    void updateNutritionalValues(String newCount) {
      double count = double.tryParse(newCount) ?? 1.0;
      volumeController.text =
          (perUnitValues['volume'] * count).toStringAsFixed(1);
      caloriesController.text =
          (perUnitValues['calories'] * count).toStringAsFixed(1);
      carbsController.text =
          (perUnitValues['carbs'] * count).toStringAsFixed(1);
      fatController.text = (perUnitValues['fat'] * count).toStringAsFixed(1);
      proteinController.text =
          (perUnitValues['protein'] * count).toStringAsFixed(1);
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  onChanged: (value) => editedItem['name'] = value,
                ),
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(labelText: 'Meal Type'),
                  onChanged: (value) => editedItem['type'] = value,
                ),
                TextField(
                  controller: countController,
                  decoration: const InputDecoration(labelText: 'Count'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    editedItem['count'] = value;
                    updateNutritionalValues(value);
                  },
                ),
                Stack(
                  children: [
                    TextField(
                      controller: volumeController,
                      decoration: const InputDecoration(labelText: 'Volume'),
                      enabled: false, // Make read-only
                    ),
                    Positioned(
                      right: 10,
                      top: 16,
                      child: Text(
                        volumeUnit,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Nutritional Information:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Stack(
                  children: [
                    TextField(
                      controller: caloriesController,
                      decoration: const InputDecoration(labelText: 'Calories'),
                      enabled: false,
                    ),
                    Positioned(
                      right: 10,
                      top: 16,
                      child: Text(
                        caloriesUnit,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                Stack(
                  children: [
                    TextField(
                      controller: carbsController,
                      decoration: const InputDecoration(labelText: 'Carbs'),
                      enabled: false,
                    ),
                    Positioned(
                      right: 10,
                      top: 16,
                      child: Text(
                        carbsUnit,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                Stack(
                  children: [
                    TextField(
                      controller: fatController,
                      decoration: const InputDecoration(labelText: 'Fat'),
                      enabled: false,
                    ),
                    Positioned(
                      right: 10,
                      top: 16,
                      child: Text(
                        fatUnit,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                Stack(
                  children: [
                    TextField(
                      controller: proteinController,
                      decoration: const InputDecoration(labelText: 'Protein'),
                      enabled: false,
                    ),
                    Positioned(
                      right: 10,
                      top: 16,
                      child: Text(
                        proteinUnit,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Upload Date:', style: TextStyle(fontSize: 10)),
                    Expanded(
                      child: TextField(
                        controller: dateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              DateTime? newDate = await showDatePicker(
                                context: context,
                                initialDate: _uploadDates[index],
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (newDate != null) {
                                TimeOfDay? newTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(
                                      _uploadDates[index]),
                                );
                                if (newTime != null) {
                                  setState(() {
                                    _uploadDates[index] = DateTime(
                                      newDate.year,
                                      newDate.month,
                                      newDate.day,
                                      newTime.hour,
                                      newTime.minute,
                                    );
                                    dateController.text = DateFormat.yMd()
                                        .add_jm()
                                        .format(_uploadDates[index]);
                                  });
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Update the editedItem with all the current values
                editedItem['name'] = nameController.text;
                editedItem['type'] = typeController.text.trim();
                editedItem['count'] = countController.text;
                editedItem['volume'] = '${volumeController.text} $volumeUnit';
                editedItem['nutritional_info']['calories'] =
                    '${caloriesController.text} $caloriesUnit';
                editedItem['nutritional_info']['carbs'] =
                    '${carbsController.text} $carbsUnit';
                editedItem['nutritional_info']['fat'] =
                    '${fatController.text} $fatUnit';
                editedItem['nutritional_info']['protein'] =
                    '${proteinController.text} $proteinUnit';

                // Preserve the per_unit values
                editedItem['per_unit'] = perUnitValues;

                setState(() {
                  _resultData[index] = editedItem;
                });

                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Food Analysis'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/icons/app_icon.png'),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _imageFile == null
                    ? const Text('No image selected.',
                        style: TextStyle(fontSize: 18))
                    : Image.file(
                        _imageFile!,
                        width: 255,
                        height: 255.8,
                        fit: BoxFit.contain,
                      ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _uploadImage,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Analyze Image'),
                          ),
                        ],
                      ),
                const SizedBox(height: 20),
                if (_resultData.isNotEmpty) ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _resultData.length,
                    itemBuilder: (context, index) {
                      final item = _resultData[index];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Name: ${item['name']}',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 5),
                                    Text('Meal Type: ${item['type']}',
                                        style: const TextStyle(fontSize: 16)),
                                    Text('Volume: ${item['volume']}',
                                        style: const TextStyle(fontSize: 16)),
                                    Text('Count: ${item['count']}',
                                        style: const TextStyle(fontSize: 16)),
                                    const SizedBox(height: 10),
                                    Text('Nutritional Information:',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        'Calories: ${item['nutritional_info']['calories']}',
                                        style: const TextStyle(fontSize: 16)),
                                    Text(
                                        'Carbs: ${item['nutritional_info']['carbs']}',
                                        style: const TextStyle(fontSize: 16)),
                                    Text(
                                        'Fat: ${item['nutritional_info']['fat']}',
                                        style: const TextStyle(fontSize: 16)),
                                    Text(
                                        'Protein: ${item['nutritional_info']['protein']}',
                                        style: const TextStyle(fontSize: 16)),
                                    Text(
                                      'Uploaded on: ${DateFormat.yMd().add_jm().format(_uploadDates[index])}',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editItem(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteItem(index),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ] else if (_resultData.isEmpty) ...[
                  Text(
                    'No food items.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 20),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                // Add Save button here
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: ElevatedButton.icon(
                    onPressed: _saveDataToDatabase,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
