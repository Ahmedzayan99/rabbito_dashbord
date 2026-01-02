/// Firebase configuration for Cloud Messaging and other services
class FirebaseConfig {
  // Firebase project configuration
  static const String projectId = 'rabbit-ecosystem'; // Replace with actual project ID
  static const String apiKey = 'your-api-key'; // Replace with actual API key
  static const String messagingSenderId = 'your-sender-id'; // Replace with actual sender ID
  static const String appId = 'your-app-id'; // Replace with actual app ID

  // FCM Server Key (keep this secret in production)
  static const String serverKey = 'your-server-key'; // Replace with actual server key

  // VAPID keys for web push notifications (if using web)
  static const String vapidKey = 'your-vapid-key'; // Replace with actual VAPID key

  // Notification settings
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Topic names for different notification types
  static const String orderUpdatesTopic = 'order_updates';
  static const String promotionsTopic = 'promotions';
  static const String systemAlertsTopic = 'system_alerts';

  // Notification channels (for Android)
  static const String orderChannel = 'orders';
  static const String promotionChannel = 'promotions';
  static const String chatChannel = 'chat';

  // TTL for notifications
  static const Duration defaultTTL = Duration(days: 7);

  // Batch size for sending notifications
  static const int batchSize = 500;

  // Firebase Admin SDK configuration
  static const Map<String, dynamic> adminConfig = {
    'type': 'service_account',
    'project_id': projectId,
    'private_key_id': 'your-private-key-id',
    'private_key': '-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY\n-----END PRIVATE KEY-----\n',
    'client_email': 'firebase-adminsdk@rabbit-ecosystem.iam.gserviceaccount.com',
    'client_id': 'your-client-id',
    'auth_uri': 'https://accounts.google.com/o/oauth2/auth',
    'token_uri': 'https://oauth2.googleapis.com/token',
    'auth_provider_x509_cert_url': 'https://www.googleapis.com/oauth2/v1/certs',
    'client_x509_cert_url': 'https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk%40rabbit-ecosystem.iam.gserviceaccount.com',
  };

  // Environment-based configuration
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get isDevelopment => !isProduction;

  // FCM endpoint URLs
  static const String fcmSendUrl = 'https://fcm.googleapis.com/fcm/send';
  static const String fcmBatchUrl = 'https://fcm.googleapis.com/batch';

  // Validation
  static bool get isConfigured =>
      serverKey.isNotEmpty &&
      serverKey != 'your-server-key' &&
      projectId.isNotEmpty &&
      projectId != 'rabbit-ecosystem';

  static void validateConfiguration() {
    if (!isConfigured) {
      throw Exception(
        'Firebase configuration is incomplete. Please update FirebaseConfig with actual values.',
      );
    }
  }
}

