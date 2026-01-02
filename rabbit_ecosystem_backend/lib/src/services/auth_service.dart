import 'package:bcrypt/bcrypt.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../models/auth_models.dart';
import '../repositories/user_repository.dart';
import '../repositories/refresh_token_repository.dart';
import 'jwt_service.dart';

class AuthService {
  final UserRepository _userRepository;
  final RefreshTokenRepository _refreshTokenRepository;
  final JwtService _jwtService;
  final Uuid _uuid = const Uuid();

  AuthService({
    required UserRepository userRepository,
    required RefreshTokenRepository refreshTokenRepository,
    JwtService? jwtService,
  })  : _userRepository = userRepository,
        _refreshTokenRepository = refreshTokenRepository,
        _jwtService = jwtService ?? JwtService();

  /// Register a new user
  Future<Map<String, dynamic>?> register(User user, String password) async {
    try {
      // Validate input
      if (user.mobile.isEmpty) {
        return null;
      }

      if (password.length < 6) {
        return null;
      }

      // Check if user already exists
      final existingUser = await _userRepository.findByMobile(user.mobile);
      if (existingUser != null) {
        return null;
      }

      // Check email if provided
      if (user.email != null && user.email!.isNotEmpty) {
        final existingEmailUser = await _userRepository.findByEmail(user.email!);
        if (existingEmailUser != null) {
          return null;
        }
      }

      // Hash password
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      // Create user with UUID
      final userWithUuid = user.copyWith(
        uuid: _uuid.v4(),
        createdAt: DateTime.now(),
      );

      final createdUser = await _userRepository.create(userWithUuid, hashedPassword);

      // Generate tokens
      final tokenPair = _jwtService.generateTokenPair(createdUser);

      // Store refresh token
      await _refreshTokenRepository.create(
        createdUser.id,
        tokenPair.refreshToken,
        DateTime.now().add(const Duration(days: 30)),
      );

      return {
        'token': tokenPair.accessToken,
        'refreshToken': tokenPair.refreshToken,
        'user': createdUser,
      };
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  /// Login user with mobile and password
  Future<Map<String, dynamic>?> login(String mobile, String password) async {
    try {
      // Validate input
      if (mobile.isEmpty || password.isEmpty) {
        return null;
      }

      // Find user by mobile
      final user = await _userRepository.findByMobile(mobile);
      if (user == null) {
        return null;
      }

      // Check if user is active
      if (!user.isActive) {
        return null;
      }

      // Get password hash
      final passwordHash = await _userRepository.getPasswordHash(user.id);
      if (passwordHash == null) {
        return null;
      }

      // Verify password
      if (!BCrypt.checkpw(password, passwordHash)) {
        return null;
      }

      // Update last login
      await _userRepository.updateLastLogin(user.id);

      // Generate tokens
      final tokenPair = _jwtService.generateTokenPair(user);

      // Clean old refresh tokens for this user
      await _refreshTokenRepository.deleteExpiredTokens(user.id);

      // Store new refresh token
      await _refreshTokenRepository.create(
        user.id,
        tokenPair.refreshToken,
        DateTime.now().add(const Duration(days: 30)),
      );

      return {
        'token': tokenPair.accessToken,
        'refreshToken': tokenPair.refreshToken,
        'user': user,
      };
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  /// Refresh access token using refresh token
  Future<Map<String, dynamic>?> refreshToken(String refreshToken) async {
    try {
      // Validate refresh token format
      final payload = _jwtService.validateToken(refreshToken);
      if (payload == null || !payload.isRefreshToken) {
        return null;
      }

      // Check if refresh token exists in database
      final storedToken = await _refreshTokenRepository.findByToken(refreshToken);
      if (storedToken == null) {
        return null;
      }

      // Check if refresh token is expired
      if (storedToken.expiresAt.isBefore(DateTime.now())) {
        await _refreshTokenRepository.delete(storedToken.id);
        return null;
      }

      // Get user
      final user = await _userRepository.findById(payload.userId);
      if (user == null || !user.isActive) {
        return null;
      }

      // Generate new token pair
      final newTokenPair = _jwtService.generateTokenPair(user);

      // Delete old refresh token
      await _refreshTokenRepository.delete(storedToken.id);

      // Store new refresh token
      await _refreshTokenRepository.create(
        user.id,
        newTokenPair.refreshToken,
        DateTime.now().add(const Duration(days: 30)),
      );

      return {
        'token': newTokenPair.accessToken,
        'refreshToken': newTokenPair.refreshToken,
        'user': user,
      };
    } catch (e) {
      print('Token refresh error: $e');
      return null;
    }
  }

  /// Logout user by invalidating refresh token
  Future<bool> logout(String refreshToken) async {
    try {
      final payload = _jwtService.validateToken(refreshToken);
      if (payload == null) return false;

      await _refreshTokenRepository.deleteByUserIdAndToken(payload.userId, refreshToken);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate access token and return user info
  Future<User?> validateAccessToken(String accessToken) async {
    try {
      final payload = _jwtService.validateToken(accessToken);
      if (payload == null || !payload.isAccessToken) {
        return null;
      }

      // Get fresh user data from database
      final user = await _userRepository.findById(payload.userId);
      if (user == null || !user.isActive) {
        return null;
      }

      return user;
    } catch (e) {
      return null;
    }
  }

  /// Change user password
  Future<bool> changePassword(int userId, String currentPassword, String newPassword) async {
    try {
      if (newPassword.length < 6) {
        return false;
      }

      // Get current password hash
      final currentHash = await _userRepository.getPasswordHash(userId);
      if (currentHash == null) {
        return false;
      }

      // Verify current password
      if (!BCrypt.checkpw(currentPassword, currentHash)) {
        return false;
      }

      // Hash new password
      final newHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());

      // Update password
      await _userRepository.updatePassword(userId, newHash);

      // Invalidate all refresh tokens for this user (force re-login)
      await _refreshTokenRepository.deleteAllByUserId(userId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reset password (for admin use)
  Future<bool> resetPassword(int userId, String newPassword) async {
    try {
      if (newPassword.length < 6) {
        return false;
      }

      // Hash new password
      final newHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());

      // Update password
      await _userRepository.updatePassword(userId, newHash);

      // Invalidate all refresh tokens for this user
      await _refreshTokenRepository.deleteAllByUserId(userId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has permission
  Future<bool> hasPermission(int userId, String permission) async {
    try {
      final user = await _userRepository.findById(userId);
      if (user == null || !user.isActive) {
        return false;
      }

      return user.role.hasPermission(permission);
    } catch (e) {
      return false;
    }
  }

  /// Get user permissions
  Future<List<String>> getUserPermissions(int userId) async {
    try {
      final user = await _userRepository.findById(userId);
      if (user == null || !user.isActive) {
        return [];
      }

      return user.role.permissions;
    } catch (e) {
      return [];
    }
  }
}