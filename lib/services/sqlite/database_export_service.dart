
import 'package:split_trip/data/database/database_helper.dart';
import 'package:split_trip/data/database/db_constants.dart';

class DatabaseExportService {
  DatabaseExportService._();

  /// Reads all database tables and constructs an export Map.
  static Future<Map<String, dynamic>> exportDatabase() async {
    final dbHelper = DatabaseHelper.instance;

    final profile = await dbHelper.getAll(table: DBConstants.profileTable);
    final categories = await dbHelper.getAll(table: DBConstants.categoriesTable);

    return {
      "version": 1,
      "db_version": DBConstants.databaseVersion,
      "profile": profile,
      "categories": categories,
    };
  }
}
