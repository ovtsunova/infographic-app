import 'package:postgres/postgres.dart';

import '../config/app_env.dart';

class Database {
  Database._();

  static Connection? _connection;

  static Future<Connection> get connection async {
    final currentConnection = _connection;

    if (currentConnection != null && currentConnection.isOpen) {
      return currentConnection;
    }

    _connection = await Connection.open(
      Endpoint(
        host: AppEnv.dbHost,
        port: AppEnv.dbPort,
        database: AppEnv.dbName,
        username: AppEnv.dbUser,
        password: AppEnv.dbPassword,
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.disable,
      ),
    );

    return _connection!;
  }

  static Future<bool> checkConnection() async {
    try {
      final conn = await connection;

      final result = await conn.execute(
        'SELECT 1 AS result',
      );

      return result.isNotEmpty && result.first[0] == 1;
    } catch (_) {
      return false;
    }
  }

  static Future<void> close() async {
    final currentConnection = _connection;

    if (currentConnection != null && currentConnection.isOpen) {
      await currentConnection.close();
    }

    _connection = null;
  }
}