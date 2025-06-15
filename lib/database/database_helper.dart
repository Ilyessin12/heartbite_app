import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'schema_statements.dart'; // Import the schema statements

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper(){
    return _instance;
  }
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async{
    if(_database != null){
      return _database!;
    }
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async{
    String path = join(await getDatabasesPath(), 'heartbite_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async{
    await db.execute(SchemaStatements.pragmaForeignKeysOn);
  }

  Future<void> _onCreate(Database db, int version) async{
    // Enable foreign key support first if not done in onConfigure for older sqflite versions
    // await db.execute(SchemaStatements.pragmaForeignKeysOn); // Already in onConfigure

    for(final statement in SchemaStatements.allSchemaStatements){
      await db.execute(statement);
    }
  }

  //=============================CRUD METHODS======================================

  //+++++++++++++++++++EXAMPLES FOR USER TABLE+++++++++++++++++++++
  // Example: Insert a user
  Future<int> insertUser(Map<String, dynamic> row) async{
    Database db = await database;
    return await db.insert('users', row);
  }

  // Example: Query all users
  Future<List<Map<String, dynamic>>> queryAllUsers() async{
    Database db = await database;
    return await db.query('users');
  }

  // More CRUD methods can be added here for other tables
  

  Future<void> close() async{
    Database db = await database;
    db.close();
    _database = null; // Reset the database instance so it can be re-initialized if needed
  }

  // Method to delete the database (for testing or reset purposes)
  Future<void> deleteDatabaseFile() async{
    String path = join(await getDatabasesPath(), 'heartbite_app.db');
    await deleteDatabase(path);
    _database = null; // Ensure the database is re-initialized next time
    print("Database deleted.");
  }
}