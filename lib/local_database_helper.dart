// import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = 'food_analysis.db';
  static const _databaseVersion = 1;

  static const table = 'user_table'; // A new table for user info
  static const columnId = 'id';
  static const columnUsername = 'username';
  static const columnEmail = 'email';
  static const columnPhoneNumber = 'phone_number';
  static const columnAge = 'age';

  static Database? _database;
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute(''' 
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnUsername TEXT,
            $columnEmail TEXT,
            $columnPhoneNumber TEXT,
            $columnAge INTEGER
          )
        ''');
      },
    );
  }

  Future<int> insert(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(table, row);
  }

  Future<int> update(Map<String, dynamic> row) async {
    final db = await database;
    int id = row[columnId];
    return await db.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> queryUserInfo() async {
    final db = await database;
    final result = await db.query(
      table,
      limit: 1, // assuming there's only one record for the user
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null; // No user data found
  }
}
