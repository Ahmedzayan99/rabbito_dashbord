import 'package:postgres/postgres.dart';
import 'dart:io';

class DatabaseManager {
  static DatabaseManager? _instance;
  Connection? _connection;

  DatabaseManager._();

  static DatabaseManager get instance {
    _instance ??= DatabaseManager._();
    return _instance!;
  }

  /// Initialize database connection
  Future<void> initialize() async {
    if (_connection != null) return;

    final host = Platform.environment['DATABASE_HOST'] ?? 'localhost';
    final port = int.parse(Platform.environment['DATABASE_PORT'] ?? '5432');
    final database = Platform.environment['DATABASE_NAME'] ?? 'rabbit_ecosystem';
    final username = Platform.environment['DATABASE_USER'] ?? 'rabbit_user';
    final password = Platform.environment['DATABASE_PASSWORD'] ?? 'rabbit_password_2024';

    _connection = await Connection.open(
      Endpoint(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.disable,
        connectTimeout: const Duration(seconds: 30),
        queryTimeout: const Duration(seconds: 30),
      ),
    );

    print('Database connected successfully');
  }

  /// Get database connection
  Future<Connection> getConnection() async {
    if (_connection == null) {
      await initialize();
    }
    return _connection!;
  }

  /// Get database connection (sync version)
  Connection get connection {
    if (_connection == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _connection!;
  }

  /// Close database connection
  Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
      print('Database connection closed');
    }
  }

  /// Test database connection
  Future<bool> testConnection() async {
    try {
      if (_connection == null) {
        await initialize();
      }

      final result = await _connection!.execute('SELECT 1 as test');
      return result.isNotEmpty && result.first[0] == 1;
    } catch (e) {
      print('Database connection test failed: $e');
      return false;
    }
  }

  /// Run database migrations
  Future<void> runMigrations() async {
    try {
      await initialize();

      // Check if migrations table exists
      final migrationTableExists = await _checkTableExists('migrations');
      
      if (!migrationTableExists) {
        await _createMigrationsTable();
      }

      // Run pending migrations
      await _runPendingMigrations();

      print('Database migrations completed successfully');
    } catch (e) {
      print('Migration failed: $e');
      rethrow;
    }
  }

  /// Check if a table exists
  Future<bool> _checkTableExists(String tableName) async {
    final result = await _connection!.execute(
      '''
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = \$1
      )
      ''',
      parameters: [tableName],
    );

    return result.first[0] as bool;
  }

  /// Create migrations tracking table
  Future<void> _createMigrationsTable() async {
    await _connection!.execute(
      '''
      CREATE TABLE migrations (
        id SERIAL PRIMARY KEY,
        filename VARCHAR(255) NOT NULL UNIQUE,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
      ''',
    );
  }

  /// Run pending migrations
  Future<void> _runPendingMigrations() async {
    final migrationFiles = [
      '001_create_tables.sql',
    ];

    for (final filename in migrationFiles) {
      final isExecuted = await _isMigrationExecuted(filename);
      
      if (!isExecuted) {
        await _executeMigrationFile(filename);
        await _markMigrationAsExecuted(filename);
        print('Executed migration: $filename');
      }
    }
  }

  /// Check if migration has been executed
  Future<bool> _isMigrationExecuted(String filename) async {
    final result = await _connection!.execute(
      'SELECT COUNT(*) FROM migrations WHERE filename = \$1',
      parameters: [filename],
    );

    return (result.first[0] as int) > 0;
  }

  /// Execute migration file
  Future<void> _executeMigrationFile(String filename) async {
    final migrationPath = 'database/migrations/$filename';
    final file = File(migrationPath);
    
    if (!file.existsSync()) {
      throw Exception('Migration file not found: $migrationPath');
    }

    final sql = await file.readAsString();
    
    // Split SQL by semicolons and execute each statement
    final statements = sql.split(';').where((s) => s.trim().isNotEmpty);
    
    for (final statement in statements) {
      if (statement.trim().isNotEmpty) {
        await _connection!.execute(statement.trim());
      }
    }
  }

  /// Mark migration as executed
  Future<void> _markMigrationAsExecuted(String filename) async {
    await _connection!.execute(
      'INSERT INTO migrations (filename) VALUES (\$1)',
      parameters: [filename],
    );
  }

  /// Seed initial data
  Future<void> seedData() async {
    try {
      await initialize();

      // Check if data already exists
      final userCount = await _connection!.execute('SELECT COUNT(*) FROM users');
      if ((userCount.first[0] as int) > 0) {
        print('Database already contains data, skipping seed');
        return;
      }

      // Run seed files
      final seedFiles = [
        '001_initial_data.sql',
      ];

      for (final filename in seedFiles) {
        await _executeSeedFile(filename);
        print('Executed seed: $filename');
      }

      print('Database seeding completed successfully');
    } catch (e) {
      print('Seeding failed: $e');
      rethrow;
    }
  }

  /// Execute seed file
  Future<void> _executeSeedFile(String filename) async {
    final seedPath = 'database/seeds/$filename';
    final file = File(seedPath);
    
    if (!file.existsSync()) {
      throw Exception('Seed file not found: $seedPath');
    }

    final sql = await file.readAsString();
    
    // Split SQL by semicolons and execute each statement
    final statements = sql.split(';').where((s) => s.trim().isNotEmpty);
    
    for (final statement in statements) {
      if (statement.trim().isNotEmpty) {
        try {
          await _connection!.execute(statement.trim());
        } catch (e) {
          // Continue with other statements if one fails (for INSERT IGNORE-like behavior)
          print('Warning: Seed statement failed (might be expected): $e');
        }
      }
    }
  }

  /// Reset database (for development/testing only)
  Future<void> resetDatabase() async {
    try {
      await initialize();

      // Drop all tables
      await _connection!.execute('DROP SCHEMA public CASCADE');
      await _connection!.execute('CREATE SCHEMA public');
      await _connection!.execute('GRANT ALL ON SCHEMA public TO public');

      print('Database reset completed');

      // Re-run migrations and seeds
      await runMigrations();
      await seedData();
    } catch (e) {
      print('Database reset failed: $e');
      rethrow;
    }
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getStatistics() async {
    await initialize();

    final result = await _connection!.execute(
      '''
      SELECT 
        schemaname,
        tablename,
        n_tup_ins as inserts,
        n_tup_upd as updates,
        n_tup_del as deletes,
        n_live_tup as live_tuples,
        n_dead_tup as dead_tuples
      FROM pg_stat_user_tables
      ORDER BY tablename
      ''',
    );

    final tables = <Map<String, dynamic>>[];
    for (final row in result) {
      tables.add({
        'schema': row[0],
        'table': row[1],
        'inserts': row[2],
        'updates': row[3],
        'deletes': row[4],
        'live_tuples': row[5],
        'dead_tuples': row[6],
      });
    }

    return {
      'tables': tables,
      'total_tables': tables.length,
    };
  }

  /// Execute raw SQL query
  Future<Result> executeQuery(String sql, {List<dynamic>? parameters}) async {
    await initialize();
    return _connection!.execute(sql, parameters: parameters);
  }

  /// Begin transaction
  Future<void> beginTransaction() async {
    await initialize();
    await _connection!.execute('BEGIN');
  }

  /// Commit transaction
  Future<void> commitTransaction() async {
    await _connection!.execute('COMMIT');
  }

  /// Rollback transaction
  Future<void> rollbackTransaction() async {
    await _connection!.execute('ROLLBACK');
  }

  /// Execute within transaction
  Future<T> executeInTransaction<T>(Future<T> Function() operation) async {
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