import 'package:serverpod/serverpod.dart';

// This is the starting point of your Serverpod server.
void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(
    args,
    Protocol(),
    Endpoints(),
  );

  // Configure database connection
  await pod.start();
}

class DatabaseConfig {
  static Future<DatabasePoolManager> createDatabasePool() async {
    return DatabasePoolManager(
      PostgreSQLDatabase(
        host: 'localhost',
        port: 5432,
        name: 'rabbit_ecosystem',
        username: 'rabbit_user',
        password: 'rabbit_password_2024',
        requireSsl: false,
        isUnixSocket: false,
      ),
    );
  }
}