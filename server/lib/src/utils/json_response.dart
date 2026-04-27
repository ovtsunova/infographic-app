import 'dart:convert';

import 'package:shelf/shelf.dart';

class JsonResponse {
  JsonResponse._();

  static final Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json; charset=utf-8',
  };

  static Response ok(Object data) {
    return Response.ok(jsonEncode(data), headers: defaultHeaders);
  }

  static Response created(Object data) {
    return Response(201, body: jsonEncode(data), headers: defaultHeaders);
  }

  static Response badRequest(String message) {
    return Response(
      400,
      body: jsonEncode({'success': false, 'message': message}),
      headers: defaultHeaders,
    );
  }

  static Response unauthorized(String message) {
    return Response(
      401,
      body: jsonEncode({'success': false, 'message': message}),
      headers: defaultHeaders,
    );
  }

  static Response forbidden(String message) {
    return Response(
      403,
      body: jsonEncode({'success': false, 'message': message}),
      headers: defaultHeaders,
    );
  }

  static Response notFound(String message) {
    return Response(
      404,
      body: jsonEncode({'success': false, 'message': message}),
      headers: defaultHeaders,
    );
  }

  static Response serverError(Object error) {
    return Response.internalServerError(
      body: jsonEncode({
        'success': false,
        'message': 'Ошибка сервера',
        'error': error.toString(),
      }),
      headers: defaultHeaders,
    );
  }
}
