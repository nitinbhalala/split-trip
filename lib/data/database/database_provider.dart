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
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ${DBConstants.groupsTable} (
              ${DBConstants.id} INTEGER PRIMARY KEY AUTOINCREMENT,
              ${DBConstants.groupName} TEXT NOT NULL,
              ${DBConstants.groupDescription} TEXT,
              ${DBConstants.createdAt} TEXT,
              ${DBConstants.updatedAt} TEXT
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ${DBConstants.groupMembersTable} (
              ${DBConstants.id} INTEGER PRIMARY KEY AUTOINCREMENT,
              ${DBConstants.memberGroupId} INTEGER NOT NULL,
              ${DBConstants.memberName} TEXT NOT NULL,
              ${DBConstants.memberPhone} TEXT,
              ${DBConstants.createdAt} TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ${DBConstants.groupMessagesTable} (
              ${DBConstants.id} INTEGER PRIMARY KEY AUTOINCREMENT,
              ${DBConstants.msgGroupId} INTEGER NOT NULL,
              ${DBConstants.msgSenderName} TEXT NOT NULL,
              ${DBConstants.msgText} TEXT NOT NULL,
              ${DBConstants.msgAmount} REAL DEFAULT 0.0,
              ${DBConstants.msgIsExpense} INTEGER DEFAULT 0,
              ${DBConstants.createdAt} TEXT
            )
          ''');
          if (oldVersion < 4) {
            try {
              await db.execute(
                'ALTER TABLE ${DBConstants.groupsTable} ADD COLUMN ${DBConstants.groupIconName} TEXT DEFAULT "group_work";',
              );
              await db.execute(
                'ALTER TABLE ${DBConstants.groupsTable} ADD COLUMN ${DBConstants.groupColorValue} INTEGER DEFAULT 4282081782;',
              );
            } catch (_) {}
          }
        }
        if (oldVersion < 5) {
          try {
            await db.execute(
              'ALTER TABLE ${DBConstants.groupsTable} ADD COLUMN ${DBConstants.groupImagePath} TEXT DEFAULT "";',
            );
          } catch (_) {}
        }
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
