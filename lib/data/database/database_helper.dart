import 'package:sqflite/sqflite.dart';

import 'database_provider.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  /// INSERT
  Future<int> insert({
    required String table,
    required Map<String, dynamic> values,
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace,
  }) async {
    final db = await DatabaseProvider.database();

    return db.insert(
      table,
      values,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  /// INSERT MULTIPLE ROWS
  Future<void> insertBatch({
    required String table,
    required List<Map<String, dynamic>> values,
  }) async {
    final db = await DatabaseProvider.database();

    final batch = db.batch();

    for (final item in values) {
      batch.insert(
        table,
        item,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// GET ALL
  Future<List<Map<String, dynamic>>> getAll({
    required String table,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await DatabaseProvider.database();

    return db.query(
      table,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// GET BY ID
  Future<Map<String, dynamic>?> getById({
    required String table,
    required int id,
    String idColumn = 'id',
  }) async {
    final db = await DatabaseProvider.database();

    final result = await db.query(
      table,
      where: '$idColumn = ?',
      whereArgs: [id],
      limit: 1,
    );

    return result.isEmpty ? null : result.first;
  }

  /// GET WHERE
  Future<List<Map<String, dynamic>>> getWhere({
    required String table,
    String? where,
    List<Object?>? args,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await DatabaseProvider.database();

    return db.query(
      table,
      where: where,
      whereArgs: args,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// EXISTS
  Future<bool> exists({
    required String table,
    required String where,
    required List<Object?> args,
  }) async {
    final db = await DatabaseProvider.database();

    final result = await db.query(
      table,
      where: where,
      whereArgs: args,
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// UPDATE
  Future<int> update({
    required String table,
    required Map<String, dynamic> values,
    required String where,
    required List<Object?> args,
  }) async {
    final db = await DatabaseProvider.database();

    return db.update(
      table,
      values,
      where: where,
      whereArgs: args,
    );
  }

  /// DELETE
  Future<int> delete({
    required String table,
    required String where,
    required List<Object?> args,
  }) async {
    final db = await DatabaseProvider.database();

    return db.delete(
      table,
      where: where,
      whereArgs: args,
    );
  }

  /// DELETE ALL
  Future<int> clearTable(String table) async {
    final db = await DatabaseProvider.database();

    return db.delete(table);
  }

  /// COUNT
  Future<int> count({
    required String table,
    String? where,
    List<Object?>? args,
  }) async {
    final db = await DatabaseProvider.database();

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM $table
      ${where != null ? "WHERE $where" : ""}
      ''',
      args,
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// SEARCH
  Future<List<Map<String, dynamic>>> search({
    required String table,
    required String column,
    required String keyword,
    String? orderBy,
  }) async {
    final db = await DatabaseProvider.database();

    return db.query(
      table,
      where: '$column LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: orderBy,
    );
  }

  /// RAW QUERY
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? args,
  ]) async {
    final db = await DatabaseProvider.database();

    return db.rawQuery(sql, args);
  }

  /// RAW INSERT
  Future<int> rawInsert(
    String sql, [
    List<Object?>? args,
  ]) async {
    final db = await DatabaseProvider.database();

    return db.rawInsert(sql, args);
  }

  /// RAW UPDATE
  Future<int> rawUpdate(
    String sql, [
    List<Object?>? args,
  ]) async {
    final db = await DatabaseProvider.database();

    return db.rawUpdate(sql, args);
  }

  /// RAW DELETE
  Future<int> rawDelete(
    String sql, [
    List<Object?>? args,
  ]) async {
    final db = await DatabaseProvider.database();

    return db.rawDelete(sql, args);
  }

  /// TRANSACTION
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    final db = await DatabaseProvider.database();

    return db.transaction(action);
  }

  /// CLOSE DATABASE
  Future<void> close() async {
    final db = await DatabaseProvider.database();

    await db.close();

    DatabaseProvider.clear();
  }
}