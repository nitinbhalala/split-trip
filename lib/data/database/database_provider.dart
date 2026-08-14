import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'db_constants.dart';

class DatabaseProvider {
  DatabaseProvider._();

  static Database? _database;
  static String? _activeUserEmail;
  static String? _activeDbName;

  /// Switches the active database to the specified user email.
  static Future<void> switchUserDatabase(String? userEmail) async {
    final targetDbName = DBConstants.getDatabaseNameForUser(userEmail);
    if (_database != null &&
        _database!.isOpen &&
        _activeDbName == targetDbName) {
      return;
    }
    await close();
    _activeUserEmail = userEmail;
    _activeDbName = targetDbName;
  }

  static Future<Database> database() async {
    final activeEmail =
        _activeUserEmail ?? FirebaseAuth.instance.currentUser?.email;
    final targetDbName = DBConstants.getDatabaseNameForUser(activeEmail);

    if (_database != null && _database!.isOpen) {
      if (_activeDbName == targetDbName) {
        return _database!;
      }
      await close();
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, targetDbName);
    _activeDbName = targetDbName;
    _activeUserEmail = activeEmail;

    _database = await openDatabase(
      path,
      version: DBConstants.databaseVersion,
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

        // 2. Profile Table
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

        // 3. Groups Table
        await db.execute('''
          CREATE TABLE ${DBConstants.groupsTable} (
            ${DBConstants.id} INTEGER PRIMARY KEY AUTOINCREMENT,
            ${DBConstants.groupName} TEXT NOT NULL,
            ${DBConstants.groupDescription} TEXT,
            ${DBConstants.groupIconName} TEXT DEFAULT 'group_work',
            ${DBConstants.groupColorValue} INTEGER DEFAULT 4282081782,
            ${DBConstants.groupImagePath} TEXT DEFAULT '',
            ${DBConstants.createdAt} TEXT,
            ${DBConstants.updatedAt} TEXT
          )
        ''');

        // 4. Group Members Table
        await db.execute('''
          CREATE TABLE ${DBConstants.groupMembersTable} (
            ${DBConstants.id} INTEGER PRIMARY KEY AUTOINCREMENT,
            ${DBConstants.memberGroupId} INTEGER NOT NULL,
            ${DBConstants.memberName} TEXT NOT NULL,
            ${DBConstants.memberPhone} TEXT,
            ${DBConstants.createdAt} TEXT
          )
        ''');

        // 5. Group Messages Table
        await db.execute('''
          CREATE TABLE ${DBConstants.groupMessagesTable} (
            ${DBConstants.id} INTEGER PRIMARY KEY AUTOINCREMENT,
            ${DBConstants.msgGroupId} INTEGER NOT NULL,
            ${DBConstants.msgSenderName} TEXT NOT NULL,
            ${DBConstants.msgText} TEXT NOT NULL,
            ${DBConstants.msgAmount} REAL DEFAULT 0.0,
            ${DBConstants.msgIsExpense} INTEGER DEFAULT 0,
            ${DBConstants.createdAt} TEXT
          )
        ''');
      },
    );

    return _database!;
  }

  static Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    _database = null;
    _activeDbName = null;
  }

  static void clear() {
    _database = null;
    _activeDbName = null;
    _activeUserEmail = null;
  }
}
