
import 'package:split_trip/data/database/database_helper.dart';
import 'package:split_trip/data/database/db_constants.dart';

class DatabaseExportService {
  DatabaseExportService._();

  /// Reads all database tables and constructs an export Map.
  static Future<Map<String, dynamic>> exportDatabase() async {
    final dbHelper = DatabaseHelper.instance;

    final profile = await dbHelper.getAll(table: DBConstants.profileTable);
    final categories = await dbHelper.getAll(table: DBConstants.categoriesTable);
    final groups = await dbHelper.getAll(table: DBConstants.groupsTable);
    final groupMembers = await dbHelper.getAll(table: DBConstants.groupMembersTable);
    final groupMessages = await dbHelper.getAll(table: DBConstants.groupMessagesTable);

    return {
      "version": 1,
      "db_version": DBConstants.databaseVersion,
      "profile": profile,
      "categories": categories,
      "groups": groups,
      "group_members": groupMembers,
      "group_messages": groupMessages,
    };
  }
}
