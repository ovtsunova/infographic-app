import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:server/src/config/app_env.dart';
import 'package:server/src/router/app_router.dart';

void main() async {
  AppEnv.load();

  final router = AppRouter();

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addHandler(router.handler);

  final server = await shelf_io.serve(
    handler,
    AppEnv.serverHost,
    AppEnv.serverPort,
  );

  print(
    'Сервер запущен: http://${server.address.host}:${server.port}',
  );
}

Middleware _corsMiddleware() {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers':
        'Origin, Content-Type, Accept, Authorization',
  };

  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok(
          '',
          headers: headers,
        );
      }

      final response = await innerHandler(request);

      return response.change(
        headers: {
          ...response.headers,
          ...headers,
        },
      );
    };
  };
}