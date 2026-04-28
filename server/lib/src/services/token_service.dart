import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../config/app_env.dart';

class TokenService {
  String createToken({
    required int accountId,
    required String email,
    required String roleName,
  }) {
    final jwt = JWT({
      'accountId': accountId,
      'email': email,
      'role': roleName,
    }, issuer: 'infographic-app');

    return jwt.sign(
      SecretKey(AppEnv.jwtSecret),
      expiresIn: Duration(hours: AppEnv.jwtExpiresHours),
    );
  }

  Map<String, dynamic>? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(AppEnv.jwtSecret));

      final payload = jwt.payload;

      if (payload is Map<String, dynamic>) {
        return payload;
      }

      return Map<String, dynamic>.from(payload as Map);
    } catch (_) {
      return null;
    }
  }
}
