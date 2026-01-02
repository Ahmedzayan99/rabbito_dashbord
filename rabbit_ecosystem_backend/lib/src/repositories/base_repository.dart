import 'dart:async';
import 'package:postgres/postgres.dart';

/// Base repository class providing common database operations
abstract class BaseRepository<T> {
  final Connection connection;
  
  BaseRepository(this.connection);

  /// Get table name for this repository
  String get tableName;

  /// Convert database row to model
  T fromMap(Map<String, dynamic> map);

  /// Convert model to database map
  Map<String, dynamic> toMap(T model);

  /// Find record by ID
  Future<T?> findById(int id) async {
    final result = await connection.execute(
      'SELECT * FROM $tableName WHERE id = @id',
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;
    return fromMap(result.first.toColumnMap());
  }

  /// Find all records with optional limit and offset
  Future<List<T>> findAll({int? limit, int? offset}) async {
    String query = 'SELECT * FROM $tableName ORDER BY created_at DESC';
    
    if (limit != null) {
      query += ' LIMIT $limit';
    }
    
    if (offset != null) {
      query += ' OFFSET $offset';
    }

    final result = await connection.execute(query);
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Count total records
  Future<int> count() async {
    final result = await connection.execute('SELECT COUNT(*) as count FROM $tableName');
    return result.first.toColumnMap()['count'] as int;
  }

  /// Find records with WHERE condition
  Future<List<T>> findWhere(String condition, {Map<String, dynamic>? parameters}) async {
    final result = await connection.execute(
      'SELECT * FROM $tableName WHERE $condition ORDER BY created_at DESC',
      parameters: parameters,
    );
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Find single record with WHERE condition
  Future<T?> findOneWhere(String condition, {Map<String, dynamic>? parameters}) async {
    final result = await connection.execute(
      'SELECT * FROM $tableName WHERE $condition LIMIT 1',
      parameters: parameters,
    );

    if (result.isEmpty) return null;
    return fromMap(result.first.toColumnMap());
  }

  /// Create new record
  Future<T> create(Map<String, dynamic> data) async {
    final columns = data.keys.join(', ');
    final placeholders = data.keys.map((key) => '@$key').join(', ');

    final result = await connection.execute(
      'INSERT INTO $tableName ($columns) VALUES ($placeholders) RETURNING *',
      parameters: data,
    );

    return fromMap(result.first.toColumnMap());
  }

  /// Update record by ID
  Future<T?> update(int id, Map<String, dynamic> data) async {
    if (data.isEmpty) {
      return await findById(id);
    }

    final setClause = data.keys.map((key) => '$key = @$key').join(', ');
    final parameters = Map<String, dynamic>.from(data);
    parameters['id'] = id;
    parameters['updated_at'] = DateTime.now().toIso8601String();

    final result = await connection.execute(
      'UPDATE $tableName SET $setClause, updated_at = @updated_at WHERE id = @id RETURNING *',
      parameters: parameters,
    );

    if (result.isEmpty) return null;
    return fromMap(result.first.toColumnMap());
  }

  /// Delete record by ID
  Future<bool> delete(int id) async {
    final result = await connection.execute(
      'DELETE FROM $tableName WHERE id = @id',
      parameters: {'id': id},
    );

    return result.affectedRows > 0;
  }

  /// Soft delete record by ID (if table has is_active column)
  Future<T?> softDelete(int id) async {
    return await update(id, {'is_active': false});
  }

  /// Execute custom query
  Future<List<Map<String, dynamic>>> executeQuery(String query, {Map<String, dynamic>? parameters}) async {
    final result = await connection.execute(query, parameters: parameters);
    return result.map((row) => row.toColumnMap()).toList();
  }

  /// Execute custom query and return single result
  Future<Map<String, dynamic>?> executeQuerySingle(String query, {Map<String, dynamic>? parameters}) async {
    final result = await connection.execute(query, parameters: parameters);
    if (result.isEmpty) return null;
    return result.first.toColumnMap();
  }

  /// Begin transaction
  Future<void> beginTransaction() async {
    await connection.execute('BEGIN');
  }

  /// Commit transaction
  Future<void> commitTransaction() async {
    await connection.execute('COMMIT');
  }

  /// Rollback transaction
  Future<void> rollbackTransaction() async {
    await connection.execute('ROLLBACK');
  }

  /// Execute function within transaction
  Future<R> withTransaction<R>(Future<R> Function() operation) async {
    await beginTransaction();
    try {
      final result = await operation();
      await commitTransaction();
      return result;
    } catch (e) {
      await rollbackTransaction();
      rethrow;
    }
  }
}