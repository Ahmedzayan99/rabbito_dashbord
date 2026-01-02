/// Application configuration
class AppConfig {
  // API Configuration
  static const String baseUrl = 'http://localhost:8080'; // Change for production
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // App Information
  static const String appName = 'Rabbit Ecosystem Dashboard';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Admin dashboard for Rabbit Ecosystem';

  // Environment
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get isDevelopment => !isProduction;

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Duration
  static const Duration cacheShortDuration = Duration(minutes: 5);
  static const Duration cacheMediumDuration = Duration(hours: 1);
  static const Duration cacheLongDuration = Duration(days: 1);

  // Feature Flags
  static const bool enableRealTimeUpdates = true;
  static const bool enablePushNotifications = true;
  static const bool enableOfflineMode = false;

  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const String emailRegex = r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+';

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx'];

  // WebSocket
  static const String wsUrl = 'ws://localhost:8080/ws';
  static const Duration wsReconnectDelay = Duration(seconds: 5);
  static const int wsMaxRetries = 5;

  // Initialize configuration
  static Future<void> initialize() async {
    // Initialize any async configuration here
    // For example: load environment variables, initialize logging, etc.
  }

  // Get API URL
  static String getApiUrl(String endpoint) {
    return '$baseUrl/api/$apiVersion$endpoint';
  }

  // Get WebSocket URL
  static String getWebSocketUrl(String? namespace) {
    return namespace != null ? '$wsUrl/$namespace' : wsUrl;
  }

  // Get asset URL
  static String getAssetUrl(String path) {
    return '/assets/$path';
  }

  // Get CDN URL (if using CDN)
  static String getCdnUrl(String path) {
    return 'https://cdn.rabbit-ecosystem.com/$path';
  }

  // Environment-specific configuration
  static String get environmentName {
    if (isProduction) return 'production';
    return 'development';
  }

  // Debug configuration
  static bool get enableLogging => !isProduction;
  static bool get enableAnalytics => isProduction;
  static bool get enableCrashReporting => isProduction;

  // Security configuration
  static const bool enableHttpsOnly = true;
  static const bool enableCertificatePinning = false;
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);

  // UI Configuration
  static const double defaultBorderRadius = 8.0;
  static const double defaultElevation = 2.0;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  // Table configuration
  static const int rowsPerPage = 20;
  static const List<int> availableRowsPerPage = [10, 20, 50, 100];

  // Chart configuration
  static const int maxDataPoints = 1000;
  static const Duration chartAnimationDuration = Duration(milliseconds: 500);

  // Notification configuration
  static const Duration notificationDisplayDuration = Duration(seconds: 5);
  static const int maxNotificationsPerPage = 50;

  // Export configuration
  static const List<String> supportedExportFormats = ['csv', 'xlsx', 'pdf'];
  static const int maxExportRows = 10000;

  // Search configuration
  static const int minSearchLength = 2;
  static const Duration searchDebounceDuration = Duration(milliseconds: 300);
  static const int maxSearchResults = 100;

  // Retry configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Rate limiting
  static const int maxRequestsPerMinute = 60;
  static const Duration rateLimitWindow = Duration(minutes: 1);
}
