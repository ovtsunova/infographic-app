import 'package:dotenv/dotenv.dart';

class AppEnv {
  AppEnv._();

  static final DotEnv _env = DotEnv(includePlatformEnvironment: true);

  static void load() {
    _env.load(['.env']);
  }

  static String get serverHost => _getString('SERVER_HOST', 'localhost');

  static int get serverPort => _getInt('SERVER_PORT', 8080);

  static String get dbHost => _getString('DB_HOST', 'localhost');

  static int get dbPort => _getInt('DB_PORT', 5433);

  static String get dbName => _getRequired('DB_NAME');

  static String get dbUser => _getRequired('DB_USER');

  static String get dbPassword => _getRequired('DB_PASSWORD');

  static String get jwtSecret => _getRequired('JWT_SECRET');

  static int get jwtExpiresHours => _getInt('JWT_EXPIRES_HOURS', 24);

  static String get backupDirectory {
    return _getString('BACKUP_DIRECTORY', 'backups');
  }

  static String get pgDumpPath {
    return _getString('PG_DUMP_PATH', 'pg_dump');
  }

  static String get psqlPath {
    return _getString('PSQL_PATH', 'psql');
  }

  static String _getRequired(String key) {
    final value = _env[key];

    if (value == null || value.trim().isEmpty) {
      throw StateError('Не задана переменная окружения: $key');
    }

    return value.trim();
  }

  static String _getString(String key, String defaultValue) {
    final value = _env[key];

    if (value == null || value.trim().isEmpty) {
      return defaultValue;
    }

    return value.trim();
  }

  static int _getInt(String key, int defaultValue) {
    final value = _env[key];

    if (value == null || value.trim().isEmpty) {
      return defaultValue;
    }

    return int.tryParse(value.trim()) ?? defaultValue;
  }
}
