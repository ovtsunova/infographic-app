import 'dart:convert';

import 'package:server/src/utils/json_response.dart';
import 'package:test/test.dart';

void main() {
  group('JsonResponse', () {
    test('ok returns success response with json body', () async {
      final response = JsonResponse.ok({'success': true, 'message': 'ok'});

      expect(response.statusCode, 200);
      expect(
        response.headers['Content-Type'],
        'application/json; charset=utf-8',
      );

      final body = jsonDecode(await response.readAsString());

      expect(body['success'], true);
      expect(body['message'], 'ok');
    });

    test('badRequest returns 400 response', () async {
      final response = JsonResponse.badRequest('Ошибка валидации');

      expect(response.statusCode, 400);

      final body = jsonDecode(await response.readAsString());

      expect(body['success'], false);
      expect(body['message'], 'Ошибка валидации');
    });

    test('unauthorized returns 401 response', () async {
      final response = JsonResponse.unauthorized('Нет доступа');

      expect(response.statusCode, 401);

      final body = jsonDecode(await response.readAsString());

      expect(body['success'], false);
      expect(body['message'], 'Нет доступа');
    });
  });
}
