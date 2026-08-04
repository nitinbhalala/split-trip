
import 'package:split_trip/data/database/database_provider.dart';
import 'package:split_trip/data/database/db_constants.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseImportService {
  DatabaseImportService._();

  /// Clears current database tables and restores backup data inside a single transaction.
  /// If any operation fails, the transaction is automatically rolled back.
  static Future<void> importDatabase(Map<String, dynamic> data) async {
    final db = await DatabaseProvider.database();

    await db.transaction((txn) async {
      // 1. Clear existing tables
      await txn.delete(DBConstants.profileTable);
      await txn.delete(DBConstants.categoriesTable);
      await txn.delete(DBConstants.groupsTable);
      await txn.delete(DBConstants.groupMembersTable);
      await txn.delete(DBConstants.groupMessagesTable);

      // 2. Restore Profile Table
      final List<dynamic> profileList = data['profile'] ?? [];
      for (final profileData in profileList) {
        await txn.insert(
          DBConstants.profileTable,
          Map<String, dynamic>.from(profileData as Map),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 3. Restore Categories Table
      final List<dynamic> categoriesList = data['categories'] ?? [];
      for (final categoryData in categoriesList) {
        await txn.insert(
          DBConstants.categoriesTable,
          Map<String, dynamic>.from(categoryData as Map),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 4. Restore Groups Table
      final List<dynamic> groupsList = data['groups'] ?? [];
      for (final groupData in groupsList) {
        await txn.insert(
          DBConstants.groupsTable,
          Map<String, dynamic>.from(groupData as Map),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 5. Restore Group Members Table
      final List<dynamic> membersList = data['group_members'] ?? [];
      for (final memberData in membersList) {
        await txn.insert(
          DBConstants.groupMembersTable,
          Map<String, dynamic>.from(memberData as Map),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 6. Restore Group Messages Table
      final List<dynamic> messagesList = data['group_messages'] ?? [];
      for (final messageData in messagesList) {
        await txn.insert(
          DBConstants.groupMessagesTable,
          Map<String, dynamic>.from(messageData as Map),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
