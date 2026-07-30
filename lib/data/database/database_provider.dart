
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'db_constants.dart';

class DatabaseProvider {
  DatabaseProvider._();

  static Database? _database;

  static Future<Database> database() async {
    if (_database != null && _database!.isOpen) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DBConstants.databaseName);

    _database = await openDatabase(
      path,
      version: DBConstants
          .databaseVersion, // Version 1 for Play Store Initial Release
      onCreate: (db, version) async {
        // 1. Categories Table
        await db.execute('''
          CREATE TABLE ${DBConstants.categoriesTable} (
            ${DBConstants.id} INTEGER PRIMARY KEY AUTOINCREMENT,
            ${DBConstants.categoryName} TEXT NOT NULL,
            ${DBConstants.categoryIconName} TEXT NOT NULL,
            ${DBConstants.categoryColorValue} INTEGER NOT NULL,
            ${DBConstants.createdAt} TEXT,
            ${DBConstants.updatedAt} TEXT
          )
        ''');



        // 1. Profile Table
        await db.execute('''
          CREATE TABLE ${DBConstants.profileTable} (
         ${DBConstants.profileId} INTEGER PRIMARY KEY,
        ${DBConstants.profileFirstName} TEXT,
        ${DBConstants.profileLastName} TEXT,
        ${DBConstants.profileEmail} TEXT,
        ${DBConstants.profilePicture} TEXT,
        ${DBConstants.profileSelectedCurrency} TEXT
          )
        ''');


      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Version 1 launch: Future database migrations logic will be added here
      },
    );

    return _database!;
  }

  static Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    _database = null;
  }

  static void clear() {
    _database = null;
  }
}
