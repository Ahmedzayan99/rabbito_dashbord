import 'dart:async';
import '../repositories/user_repository.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import 'jwt_service.dart';

/// Service for user-related business logic
class UserService {
  final UserRepository _userRepository;
  final JwtService _jwtService;

  UserService(this._userRepository, this._jwtService);

  /// Register a new user
  Future<AuthResponse> registerUser({
    required String mobile,
    required String password,
    String? username,
    String? email,
    UserRole role = UserRole.customer,
  }) async {
    try {
      // Check if mobile already exists
      if (await _userRepository.mobileExists(mobile)) {
        return AuthResponse.error('Mobile number already registered');
      }

      // Check if email already exists (if provided)
      if (email != null && await _userRepository.emailExists(email)) {
        return AuthResponse.error('Email already registered');
      }

      // Validate mobile format
      if (!_isValidMobile(mobile)) {
        return AuthResponse.error('Invalid mobile number format');
      }

      // Validate email format (if provided)
      if (email != null && !_isValidEmail(email)) {
        return AuthResponse.error('Invalid email format');
      }

      // Validate password strength
      if (!_isValidPassword(password)) {
        return AuthResponse.error('Password must be at least 8 characters long');
      }

      // Create user
      final user = await _userRepository.createUser(
        mobile: mobile,
        password: password,
        username: username,
        email: email,
        role: role,
      );

      // Generate tokens
      final tokenPair = _jwtService.generateTokenPair(user);

      return AuthResponse.success(
        accessToken: tokenPair.accessToken,
        refreshToken: tokenPair.refreshToken,
        user: user,
        expiresAt: tokenPair.expiresAt,
        message: 'Registration successful',
      );
    } catch (e) {
      return AuthResponse.error('Registration failed: ${e.toString()}');
    }
  }

  /// Login user
  Future<AuthResponse> loginUser({
    required String identifier, // mobile or email
    required String password,
  }) async {
    try {
      // Find user by mobile or email
      final user = await _userRepository.findByMobileOrEmail(identifier);
      
      if (user == null) {
        return AuthResponse.error('User not found');
      }

      // Check if user is active
      if (!user.isActive) {
        return AuthResponse.error('Account is deactivated');
      }

      // Verify password
      final isValidPassword = await _userRepository.verifyPassword(user, password);
      if (!isValidPassword) {
        return AuthResponse.error('Invalid credentials');
      }

      // Update last login
      await _userRepository.updateLastLogin(user.id);

      // Generate tokens
      final tokenPair = _jwtService.generateTokenPair(user);

      return AuthResponse.success(
        accessToken: tokenPair.accessToken,
        refreshToken: tokenPair.refreshToken,
        user: user,
        expiresAt: tokenPair.expiresAt,
        message: 'Login successful',
      );
    } catch (e) {
      return AuthResponse.error('Login failed: ${e.toString()}');
    }
  }

  /// Refresh access token
  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      // Validate refresh token
      final payload = _jwtService.validateToken(refreshToken);
      
      if (payload == null || !payload.isRefreshToken) {
        return AuthResponse.error('Invalid refresh token');
      }

      // Get user
      final user = await _userRepository.findById(payload.userId);
      
      if (user == null || !user.isActive) {
        return AuthResponse.error('User not found or inactive');
      }

      // Generate new tokens
      final tokenPair = _jwtService.generateTokenPair(user);

      return AuthResponse.success(
        accessToken: tokenPair.accessToken,
        refreshToken: tokenPair.refreshToken,
        user: user,
        expiresAt: tokenPair.expiresAt,
        message: 'Token refreshed successfully',
      );
    } catch (e) {
      return AuthResponse.error('Token refresh failed: ${e.toString()}');
    }
  }

  /// Get user profile
  Future<User?> getUserProfile(int userId) async {
    return await _userRepository.findById(userId);
  }

  /// Update user profile
  Future<User?> updateUserProfile(int userId, {
    String? username,
    String? email,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (username != null) {
        updateData['username'] = username;
      }
      
      if (email != null) {
        if (!_isValidEmail(email)) {
          throw Exception('Invalid email format');
        }
        
        // Check if email already exists for another user
        final existingUser = await _userRepository.findByEmail(email);
        if (existingUser != null && existingUser.id != userId) {
          throw Exception('Email already registered');
        }
        
        updateData['email'] = email;
        updateData['email_verified'] = false; // Reset verification status
      }

      if (updateData.isEmpty) {
        return await _userRepository.findById(userId);
      }

      return await _userRepository.update(userId, updateData);
    } catch (e) {
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }

  /// Change user password
  Future<bool> changePassword(int userId, String currentPassword, String newPassword) async {
    try {
      // Get user
      final user = await _userRepository.findById(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      // Verify current password
      final isValidPassword = await _userRepository.verifyPassword(user, currentPassword);
      if (!isValidPassword) {
        throw Exception('Current password is incorrect');
      }

      // Validate new password
      if (!_isValidPassword(newPassword)) {
        throw Exception('New password must be at least 8 characters long');
      }

      // Update password
      return await _userRepository.updatePassword(userId, newPassword);
    } catch (e) {
      throw Exception('Password change failed: ${e.toString()}');
    }
  }

  /// Verify email
  Future<User?> verifyEmail(int userId) async {
    return await _userRepository.verifyEmail(userId);
  }

  /// Verify mobile
  Future<User?> verifyMobile(int userId) async {
    return await _userRepository.verifyMobile(userId);
  }

  /// Update user balance
  Future<User?> updateBalance(int userId, double amount) async {
    if (amount < 0) {
      throw Exception('Amount cannot be negative');
    }
    return await _userRepository.updateBalance(userId, amount);
  }

  /// Add to user balance
  Future<User?> addToBalance(int userId, double amount) async {
    if (amount <= 0) {
      throw Exception('Amount must be positive');
    }
    return await _userRepository.addToBalance(userId, amount);
  }

  /// Subtract from user balance
  Future<User?> subtractFromBalance(int userId, double amount) async {
    if (amount <= 0) {
      throw Exception('Amount must be positive');
    }
    
    // Check if user has sufficient balance
    final user = await _userRepository.findById(userId);
    if (user == null) {
      throw Exception('User not found');
    }
    
    if (user.balance < amount) {
      throw Exception('Insufficient balance');
    }
    
    return await _userRepository.subtractFromBalance(userId, amount);
  }

  /// Get users with pagination
  Future<List<User>> getUsers({int? limit, int? offset, bool activeOnly = true}) async {
    if (activeOnly) {
      return await _userRepository.findActiveUsers(limit: limit, offset: offset);
    }
    return await _userRepository.findAll(limit: limit, offset: offset);
  }

  /// Search users
  Future<List<User>> searchUsers(String query, {int? limit, int? offset}) async {
    if (query.trim().isEmpty) {
      return await getUsers(limit: limit, offset: offset);
    }
    return await _userRepository.searchUsers(query, limit: limit, offset: offset);
  }

  /// Get users by role
  Future<List<User>> getUsersByRole(UserRole role) async {
    return await _userRepository.findByRole(role);
  }

  /// Deactivate user
  Future<User?> deactivateUser(int userId) async {
    return await _userRepository.update(userId, {'is_active': false});
  }

  /// Activate user
  Future<User?> activateUser(int userId) async {
    return await _userRepository.update(userId, {'is_active': true});
  }

  /// Update user role (admin only)
  Future<User?> updateUserRole(int userId, UserRole newRole) async {
    return await _userRepository.update(userId, {'role': newRole.value});
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    return await _userRepository.getUserStats();
  }

  /// Update user rating
  Future<User?> updateUserRating(int userId, double rating, int totalRatings) async {
    if (rating < 0 || rating > 5) {
      throw Exception('Rating must be between 0 and 5');
    }
    if (totalRatings < 0) {
      throw Exception('Total ratings cannot be negative');
    }
    return await _userRepository.updateRating(userId, rating, totalRatings);
  }

  /// Delete user (soft delete)
  Future<bool> deleteUser(int userId) async {
    final user = await _userRepository.softDelete(userId);
    return user != null;
  }

  /// Update user with UpdateUserRequest
  Future<User?> updateUser(int userId, UpdateUserRequest request) async {
    final updateData = <String, dynamic>{};

    if (request.username != null) updateData['username'] = request.username;
    if (request.email != null) updateData['email'] = request.email;
    if (request.role != null) updateData['role'] = request.role!.value;
    if (request.isActive != null) updateData['is_active'] = request.isActive;

    if (updateData.isEmpty) {
      return await _userRepository.findById(userId);
    }

    return await _userRepository.update(userId, updateData);
  }

  /// Get total user count
  Future<int> getTotalUserCount() async {
    return await _userRepository.getTotalCount();
  }

  /// Validate mobile number format
  bool _isValidMobile(String mobile) {
    // Saudi mobile number format: +966xxxxxxxxx or 05xxxxxxxx
    final saudiMobileRegex = RegExp(r'^(\+966|0)?5[0-9]{8}$');
    return saudiMobileRegex.hasMatch(mobile);
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Validate password strength
  bool _isValidPassword(String password) {
    return password.length >= 8;
  }

  /// Check if user exists
  Future<bool> userExists(int userId) async {
    final user = await _userRepository.findById(userId);
    return user != null && user.isActive;
  }

  /// Get user by UUID
  Future<User?> getUserByUuid(String uuid) async {
    return await _userRepository.findByUuid(uuid);
  }

  /// Create a new user (admin function)
  Future<User?> createUser(User user, String password) async {
    try {
      // Hash the password
      final hashedPassword = _jwtService.hashPassword(password);

      // Create user in database
      final createdUser = await _userRepository.createUser(
        mobile: user.mobile,
        password: hashedPassword,
        username: user.username,
        email: user.email,
        role: user.role,
      );

      return createdUser;
    } catch (e) {
      return null;
    }
  }

  /// Validate user permissions for action
  bool canUserPerformAction(User user, String action) {
    return user.role.hasPermission(action);
  }

  /// Check if user can access resource
  bool canUserAccessResource(User user, int resourceOwnerId, String requiredPermission) {
    // User can access their own resource
    if (user.id == resourceOwnerId) {
      return true;
    }
    
    // User can access if they have the required permission
    return user.role.hasPermission(requiredPermission);
  }
}