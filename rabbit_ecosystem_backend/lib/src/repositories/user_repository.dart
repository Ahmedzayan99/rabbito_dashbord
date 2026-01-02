import 'dart:async';
import 'package:postgres/postgres.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'base_repository.dart';
import '../models/user.dart';
import '../models/user_role.dart';

/// Repository for user-related database operations
class UserRepository extends BaseRepository<User> {
  UserRepository(super.connection);

  @override
  String get tableName => 'users';

  @override
  User fromMap(Map<String, dynamic> map) {
    return User.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(User user) {
    return {
      'uuid': user.uuid,
      'username': user.username,
      'email': user.email,
      'mobile': user.mobile,
      'role': user.role.value,
      'balance': user.balance,
      'rating': user.rating,
      'no_of_ratings': user.numberOfRatings,
      'is_active': user.isActive,
      'email_verified': user.emailVerified,
      'mobile_verified': user.mobileVerified,
      'last_login': user.lastLogin?.toIso8601String(),
      'created_at': user.createdAt.toIso8601String(),
      'updated_at': user.updatedAt?.toIso8601String(),
    };
  }

  /// Find user by mobile number
  Future<User?> findByMobile(String mobile) async {
    return await findOneWhere('mobile = @mobile', parameters: {'mobile': mobile});
  }

  /// Find user by email
  Future<User?> findByEmail(String email) async {
    return await findOneWhere('email = @email', parameters: {'email': email});
  }

  /// Find user by UUID
  Future<User?> findByUuid(String uuid) async {
    return await findOneWhere('uuid = @uuid', parameters: {'uuid': uuid});
  }

  /// Find user by mobile or email
  Future<User?> findByMobileOrEmail(String identifier) async {
    return await findOneWhere(
      'mobile = @identifier OR email = @identifier',
      parameters: {'identifier': identifier},
    );
  }

  /// Create new user with hashed password
  Future<User> createUser({
    required String mobile,
    required String password,
    String? username,
    String? email,
    UserRole role = UserRole.customer,
  }) async {
    final uuid = _generateUuid();
    final hashedPassword = _hashPassword(password);

    final userData = {
      'uuid': uuid,
      'username': username,
      'email': email,
      'mobile': mobile,
      'password_hash': hashedPassword,
      'role': role.value,
      'balance': 0.0,
      'rating': 0.0,
      'no_of_ratings': 0,
      'is_active': true,
      'email_verified': false,
      'mobile_verified': false,
      'created_at': DateTime.now().toIso8601String(),
    };

    return await create(userData);
  }

  /// Verify user password
  Future<bool> verifyPassword(User user, String password) async {
    final result = await executeQuerySingle(
      'SELECT password_hash FROM users WHERE id = @id',
      parameters: {'id': user.id},
    );

    if (result == null) return false;

    final storedHash = result['password_hash'] as String;
    final inputHash = _hashPassword(password);
    
    return storedHash == inputHash;
  }

  /// Update user password
  Future<bool> updatePassword(int userId, String newPassword) async {
    final hashedPassword = _hashPassword(newPassword);
    
    final result = await connection.execute(
      'UPDATE users SET password_hash = @password_hash, updated_at = @updated_at WHERE id = @id',
      parameters: {
        'id': userId,
        'password_hash': hashedPassword,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );

    return result.affectedRows > 0;
  }

  /// Update user last login
  Future<void> updateLastLogin(int userId) async {
    await connection.execute(
      'UPDATE users SET last_login = @last_login WHERE id = @id',
      parameters: {
        'id': userId,
        'last_login': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Update user balance
  Future<User?> updateBalance(int userId, double newBalance) async {
    return await update(userId, {'balance': newBalance});
  }

  /// Add to user balance
  Future<User?> addToBalance(int userId, double amount) async {
    final result = await connection.execute(
      'UPDATE users SET balance = balance + @amount, updated_at = @updated_at WHERE id = @id RETURNING *',
      parameters: {
        'id': userId,
        'amount': amount,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );

    if (result.isEmpty) return null;
    return fromMap(result.first.toColumnMap());
  }

  /// Subtract from user balance
  Future<User?> subtractFromBalance(int userId, double amount) async {
    final result = await connection.execute(
      'UPDATE users SET balance = balance - @amount, updated_at = @updated_at WHERE id = @id AND balance >= @amount RETURNING *',
      parameters: {
        'id': userId,
        'amount': amount,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );

    if (result.isEmpty) return null;
    return fromMap(result.first.toColumnMap());
  }

  /// Update user rating
  Future<User?> updateRating(int userId, double newRating, int totalRatings) async {
    return await update(userId, {
      'rating': newRating,
      'no_of_ratings': totalRatings,
    });
  }

  /// Verify email
  Future<User?> verifyEmail(int userId) async {
    return await update(userId, {'email_verified': true});
  }

  /// Verify mobile
  Future<User?> verifyMobile(int userId) async {
    return await update(userId, {'mobile_verified': true});
  }

  /// Find users by role
  Future<List<User>> findByRole(UserRole role) async {
    return await findWhere('role = @role', parameters: {'role': role.value});
  }

  /// Find active users
  Future<List<User>> findActiveUsers({int? limit, int? offset}) async {
    String query = 'SELECT * FROM users WHERE is_active = true ORDER BY created_at DESC';
    
    if (limit != null) {
      query += ' LIMIT $limit';
    }
    
    if (offset != null) {
      query += ' OFFSET $offset';
    }

    final result = await connection.execute(query);
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Search users by name, email, or mobile
  Future<List<User>> searchUsers(String query, {int? limit, int? offset}) async {
    final searchQuery = '''
      SELECT * FROM users 
      WHERE (username ILIKE @query OR email ILIKE @query OR mobile ILIKE @query)
      AND is_active = true
      ORDER BY created_at DESC
    ''';

    String finalQuery = searchQuery;
    if (limit != null) {
      finalQuery += ' LIMIT $limit';
    }
    if (offset != null) {
      finalQuery += ' OFFSET $offset';
    }

    final result = await connection.execute(
      finalQuery,
      parameters: {'query': '%$query%'},
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    final result = await executeQuerySingle('''
      SELECT 
        COUNT(*) as total_users,
        COUNT(CASE WHEN is_active = true THEN 1 END) as active_users,
        COUNT(CASE WHEN role = 'customer' THEN 1 END) as customers,
        COUNT(CASE WHEN role = 'partner' THEN 1 END) as partners,
        COUNT(CASE WHEN role = 'rider' THEN 1 END) as riders,
        COUNT(CASE WHEN email_verified = true THEN 1 END) as verified_emails,
        COUNT(CASE WHEN mobile_verified = true THEN 1 END) as verified_mobiles
      FROM users
    ''');

    return result ?? {};
  }

  /// Check if mobile exists
  Future<bool> mobileExists(String mobile) async {
    final result = await executeQuerySingle(
      'SELECT COUNT(*) as count FROM users WHERE mobile = @mobile',
      parameters: {'mobile': mobile},
    );
    
    return (result?['count'] as int? ?? 0) > 0;
  }

  /// Check if email exists
  Future<bool> emailExists(String email) async {
    final result = await executeQuerySingle(
      'SELECT COUNT(*) as count FROM users WHERE email = @email',
      parameters: {'email': email},
    );
    
    return (result?['count'] as int? ?? 0) > 0;
  }

  /// Get total count of users
  Future<int> getTotalCount() async {
    final result = await connection.execute('SELECT COUNT(*) as count FROM users');
    return result.first[0] as int;
  }

  /// Soft delete user (deactivate instead of delete)
  Future<User?> softDelete(int userId) async {
    return await update(userId, {'is_active': false});
  }

  /// Generate UUID for new user
  String _generateUuid() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + (timestamp % 1000)).toString();
    return 'user_${timestamp}_$random';
  }

  /// Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'rabbit_ecosystem_salt_2024');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}