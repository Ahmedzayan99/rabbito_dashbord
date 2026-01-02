import '../database/database_manager.dart';
import 'package:postgres/postgres.dart';

class RefreshToken {
  final int id;
  final int userId;
  final String token;
  final DateTime expiresAt;
  final DateTime createdAt;

  RefreshToken({
    required this.id,
    required this.userId,
    required this.token,
    required this.expiresAt,
    required this.createdAt,
  });

  factory RefreshToken.fromMap(Map<String, dynamic> map) {
    return RefreshToken(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      token: map['token'] as String,
      expiresAt: DateTime.parse(map['expires_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class RefreshTokenRepository {
  final DatabaseManager _db = DatabaseManager.instance;

  /// Create a new refresh token
  Future<RefreshToken> create(int userId, String token, DateTime expiresAt) async {
    try {
      final connection = await _db.getConnection();
      final result = await connection.execute(
        Sql.named('''
          INSERT INTO refresh_tokens (user_id, token, expires_at, created_at)
          VALUES (@userId, @token, @expiresAt, @createdAt)
          RETURNING *
        '''),
        parameters: {
          'userId': userId,
          'token': token,
          'expiresAt': expiresAt.toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      if (result.isEmpty) {
        throw Exception('Failed to create refresh token');
      }

      return RefreshToken.fromMap(result.first.toColumnMap());
    } catch (e) {
      print('Error creating refresh token: $e');
      rethrow;
    }
  }

  /// Find refresh token by token string
  Future<RefreshToken?> findByToken(String token) async {
    try {
      final connection = await _db.getConnection();
      final result = await connection.execute(
        Sql.named('SELECT * FROM refresh_tokens WHERE token = @token'),
        parameters: {'token': token},
      );

      if (result.isEmpty) return null;
      return RefreshToken.fromMap(result.first.toColumnMap());
    } catch (e) {
      print('Error finding refresh token: $e');
      return null;
    }
  }

  /// Find all refresh tokens for a user
  Future<List<RefreshToken>> findByUserId(int userId) async {
    try {
      final connection = await _db.getConnection();
      final result = await connection.execute(
        Sql.named('''
          SELECT * FROM refresh_tokens 
          WHERE user_id = @userId 
          ORDER BY created_at DESC
        '''),
        parameters: {'userId': userId},
      );

      return result.map((row) => RefreshToken.fromMap(row.toColumnMap())).toList();
    } catch (e) {
      print('Error finding refresh tokens by user id: $e');
      return [];
    }
  }

  /// Delete a refresh token by ID
  Future<bool> delete(int id) async {
    try {
      final connection = await _db.getConnection();
      final result = await connection.execute(
        Sql.named('DELETE FROM refresh_tokens WHERE id = @id'),
        parameters: {'id': id},
      );

      return result.affectedRows > 0;
    } catch (e) {
      print('Error deleting refresh token: $e');
      return false;
    }
  }

  /// Delete refresh token by user ID and token
  Future<bool> deleteByUserIdAndToken(int userId, String token) async {
    try {
      final connection = await _db.getConnection();
      final result = await connection.execute(
        Sql.named('DELETE FROM refresh_tokens WHERE user_id = @userId AND token = @token'),
        parameters: {'userId': userId, 'token': token},
      );

      return result.affectedRows > 0;
    } catch (e) {
      print('Error deleting refresh token by user and token: $e');
      return false;
    }
  }

  /// Delete all refresh tokens for a user
  Future<int> deleteAllByUserId(int userId) async {
    try {
      final connection = await _db.getConnection();
      final result = await connection.execute(
        Sql.named('DELETE FROM refresh_tokens WHERE user_id = @userId'),
        parameters: {'userId': userId},
      );

      return result.affectedRows;
    } catch (e) {
      print('Error deleting all refresh tokens for user: $e');
      return 0;
    }
  }

  /// Delete expired refresh tokens for a user
  Future<int> deleteExpiredTokens(int userId) async {
    try {
      final connection = await _db.getConnection();
      final result = await connection.execute(
        Sql.named('''
          DELETE FROM refresh_tokens 
          WHERE user_id = @userId AND expires_at < @now
        '''),
        parameters: {
          'userId': userId,
          'now': DateTime.now().toIso8601String(),
        },
      );

      return result.affectedRows;
    } catch (e) {
      print('Error deleting expired refresh tokens: $e');
      return 0;
    }
  }

  /// Delete all expired refresh tokens (cleanup job)
  Future<int> deleteAllExpiredTokens() async {
    try {
      final connection = await _db.getConnection();
      final result = await connection.execute(
        Sql.named('''
          DELETE FROM refresh_tokens 
          WHERE expires_at < @now
        '''),
        parameters: {'now': DateTime.now().toIso8601String()},
      );

      return result.affectedRows;
    } catch (e) {
      print('Error deleting all expired refresh tokens: $e');
      return 0;
    }
  }

  /// Count active refresh tokens for a user
  Future<int> countActiveTokens(int userId) async {
    try {
      final connection = await _db.getConnection();
      final result = await connection.execute(
        Sql.named('''
          SELECT COUNT(*) as count
          FROM refresh_tokens
          WHERE user_id = @userId AND expires_at > @now
        '''),
        parameters: {
          'userId': userId,
          'now': DateTime.now().toIso8601String(),
        },
      );

      return result.first.toColumnMap()['count'] as int;
    } catch (e) {
      print('Error counting active tokens: $e');
      return 0;
    }
  }

  /// Check if refresh token exists and is valid
  Future<bool> isValidToken(String token) async {
    try {
      final connection = await _db.getConnection();
      final result = await connection.execute(
        Sql.named('''
          SELECT COUNT(*) as count
          FROM refresh_tokens
          WHERE token = @token AND expires_at > @now
        '''),
        parameters: {
          'token': token,
          'now': DateTime.now().toIso8601String(),
        },
      );

      return (result.first.toColumnMap()['count'] as int) > 0;
    } catch (e) {
      print('Error checking token validity: $e');
      return false;
    }
  }
}