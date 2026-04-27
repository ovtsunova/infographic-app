import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../handlers/admin_handler.dart';
import '../handlers/attendance_handler.dart';
import '../handlers/auth_handler.dart';
import '../handlers/disciplines_handler.dart';
import '../handlers/grades_handler.dart';
import '../handlers/groups_handler.dart';
import '../handlers/health_handler.dart';
import '../handlers/infographics_handler.dart';
import '../handlers/periods_handler.dart';
import '../handlers/profile_handler.dart';
import '../handlers/statistics_handler.dart';
import '../handlers/students_handler.dart';
import '../middleware/auth_middleware.dart';
import '../services/token_service.dart';
import '../utils/json_response.dart';

class AppRouter {
  Handler get handler {
    final router = Router();

    final tokenService = TokenService();

    final healthHandler = HealthHandler();
    final authHandler = AuthHandler(tokenService: tokenService);
    final profileHandler = ProfileHandler();

    final groupsHandler = GroupsHandler();
    final disciplinesHandler = DisciplinesHandler();
    final periodsHandler = PeriodsHandler();
    final studentsHandler = StudentsHandler();
    final gradesHandler = GradesHandler();
    final attendanceHandler = AttendanceHandler();
    final statisticsHandler = StatisticsHandler();
    final infographicsHandler = InfographicsHandler();
    final adminHandler = AdminHandler();

    final authMiddleware = AuthMiddleware(tokenService: tokenService);

    router.get('/api/health', healthHandler.health);
    router.get('/api/db/health', healthHandler.dbHealth);

    router.post('/api/auth/register', authHandler.register);
    router.post('/api/auth/login', authHandler.login);

    router.get(
      '/api/auth/me',
      _protect(profileHandler.getMe, authMiddleware.requireAuth()),
    );

    router.put(
      '/api/auth/profile',
      _protect(profileHandler.updateProfile, authMiddleware.requireAuth()),
    );

    router.put(
      '/api/auth/password',
      _protect(profileHandler.changePassword, authMiddleware.requireAuth()),
    );

    // ------------------------------
    // Учебные группы
    // ------------------------------

    router.get(
      '/api/groups',
      _protect(groupsHandler.getAll, authMiddleware.requireAuth()),
    );

    router.get('/api/groups/<id|[0-9]+>', (Request request, String id) {
      return _protect(
        (protectedRequest) => groupsHandler.getById(protectedRequest, id),
        authMiddleware.requireAuth(),
      )(request);
    });

    router.post(
      '/api/groups',
      _protect(groupsHandler.create, authMiddleware.requireAdmin()),
    );

    router.put('/api/groups/<id|[0-9]+>', (Request request, String id) {
      return _protect(
        (protectedRequest) => groupsHandler.update(protectedRequest, id),
        authMiddleware.requireAdmin(),
      )(request);
    });

    router.delete('/api/groups/<id|[0-9]+>', (Request request, String id) {
      return _protect(
        (protectedRequest) => groupsHandler.delete(protectedRequest, id),
        authMiddleware.requireAdmin(),
      )(request);
    });

    // ------------------------------
    // Дисциплины
    // ------------------------------

    router.get(
      '/api/disciplines',
      _protect(disciplinesHandler.getAll, authMiddleware.requireAuth()),
    );

    router.get('/api/disciplines/<id|[0-9]+>', (Request request, String id) {
      return _protect(
        (protectedRequest) => disciplinesHandler.getById(protectedRequest, id),
        authMiddleware.requireAuth(),
      )(request);
    });

    router.post(
      '/api/disciplines',
      _protect(disciplinesHandler.create, authMiddleware.requireAdmin()),
    );

    router.put('/api/disciplines/<id|[0-9]+>', (Request request, String id) {
      return _protect(
        (protectedRequest) => disciplinesHandler.update(protectedRequest, id),
        authMiddleware.requireAdmin(),
      )(request);
    });

    router.delete('/api/disciplines/<id|[0-9]+>', (Request request, String id) {
      return _protect(
        (protectedRequest) => disciplinesHandler.delete(protectedRequest, id),
        authMiddleware.requireAdmin(),
      )(request);
    });

    // ------------------------------
    // Учебные периоды
    // ------------------------------

    router.get(
      '/api/periods',
      _protect(periodsHandler.getAll, authMiddleware.requireAuth()),
    );

    router.get('/api/periods/<id|[0-9]+>', (Request request, String id) {
      return _protect(
        (protectedRequest) => periodsHandler.getById(protectedRequest, id),
        authMiddleware.requireAuth(),
      )(request);
    });

    router.post(
      '/api/periods',
      _protect(periodsHandler.create, authMiddleware.requireAdmin()),
    );

    router.put('/api/periods/<id|[0-9]+>', (Request request, String id) {
      return _protect(
        (protectedRequest) => periodsHandler.update(protectedRequest, id),
        authMiddleware.requireAdmin(),
      )(request);
    });

    router.delete('/api/periods/<id|[0-9]+>', (Request request, String id) {
      return _protect(
        (protectedRequest) => periodsHandler.delete(protectedRequest, id),
        authMiddleware.requireAdmin(),
      )(request);
    });

    // ------------------------------
    // Студенты
    // ------------------------------

    router.get(
      '/api/students',
      _protect(studentsHandler.getAll, authMiddleware.requireAuth()),
    );

    router.get('/api/students/<id|[0-9]+>', (Request request, String id) {
      return _protect(
        (protectedRequest) => studentsHandler.getById(protectedRequest, id),
        authMiddleware.requireAuth(),
      )(request);
    });

    router.post(
      '/api/students',
      _protect(studentsHandler.create, authMiddleware.requireAdmin()),
    );

    router.put('/api/students/<id|[0-9]+>', (Request request, String id) {
      return _protect(
        (protectedRequest) => studentsHandler.update(protectedRequest, id),
        authMiddleware.requireAdmin(),
      )(request);
    });

    router.delete('/api/students/<id|[0-9]+>', (Request request, String id) {
      return _protect(
        (protectedRequest) => studentsHandler.delete(protectedRequest, id),
        authMiddleware.requireAdmin(),
      )(request);
    });

    // ------------------------------
    // Оценки
    // ------------------------------

    router.get(
      '/api/grades',
      _protect(gradesHandler.getAll, authMiddleware.requireAuth()),
    );

    router.post(
      '/api/grades',
      _protect(gradesHandler.create, authMiddleware.requireAdmin()),
    );

    router.put('/api/grades/<id|[0-9]+>', (Request request, String id) {
      return _protect(
        (protectedRequest) => gradesHandler.update(protectedRequest, id),
        authMiddleware.requireAdmin(),
      )(request);
    });

    router.delete('/api/grades/<id|[0-9]+>', (Request request, String id) {
      return _protect(
        (protectedRequest) => gradesHandler.delete(protectedRequest, id),
        authMiddleware.requireAdmin(),
      )(request);
    });

    // ------------------------------
    // Посещаемость
    // ------------------------------

    router.get(
      '/api/attendance',
      _protect(attendanceHandler.getAll, authMiddleware.requireAuth()),
    );

    router.post(
      '/api/attendance',
      _protect(attendanceHandler.create, authMiddleware.requireAdmin()),
    );

    router.put('/api/attendance/<id|[0-9]+>', (Request request, String id) {
      return _protect(
        (protectedRequest) => attendanceHandler.update(protectedRequest, id),
        authMiddleware.requireAdmin(),
      )(request);
    });

    router.delete('/api/attendance/<id|[0-9]+>', (Request request, String id) {
      return _protect(
        (protectedRequest) => attendanceHandler.delete(protectedRequest, id),
        authMiddleware.requireAdmin(),
      )(request);
    });

    // ------------------------------
    // Статистика
    // ------------------------------

    router.get(
      '/api/statistics/groups',
      _protect(
        statisticsHandler.getGroupStatistics,
        authMiddleware.requireAuth(),
      ),
    );

    router.get(
      '/api/statistics/summary',
      _protect(
        statisticsHandler.getSummary,
        authMiddleware.requireAuth(),
      ),
    );

    router.get(
      '/api/statistics/grade-distribution',
      _protect(
        statisticsHandler.getGradeDistribution,
        authMiddleware.requireAuth(),
      ),
    );

    // ------------------------------
    // Инфографики
    // ------------------------------

    router.get(
      '/api/infographics/templates',
      _protect(
        infographicsHandler.getTemplates,
        authMiddleware.requireAuth(),
      ),
    );

    router.get(
      '/api/infographics/my',
      _protect(
        infographicsHandler.getMyInfographics,
        authMiddleware.requireAuth(),
      ),
    );

    router.get(
      '/api/infographics',
      _protect(
        infographicsHandler.getAll,
        authMiddleware.requireAdmin(),
      ),
    );

    router.post(
      '/api/infographics',
      _protect(
        infographicsHandler.save,
        authMiddleware.requireAuth(),
      ),
    );

    router.delete('/api/infographics/<id|[0-9]+>', (
      Request request,
      String id,
    ) {
      return _protect(
        (protectedRequest) => infographicsHandler.delete(protectedRequest, id),
        authMiddleware.requireAuth(),
      )(request);
    });

    // ------------------------------
    // Администратор
    // ------------------------------

    router.get(
      '/api/admin/dashboard',
      _protect(adminHandler.getDashboard, authMiddleware.requireAdmin()),
    );

    router.get(
      '/api/admin/users',
      _protect(adminHandler.getUsers, authMiddleware.requireAdmin()),
    );

    router.get('/api/admin/users/<id|[0-9]+>', (
      Request request,
      String id,
    ) {
      return _protect(
        (protectedRequest) => adminHandler.getUserById(protectedRequest, id),
        authMiddleware.requireAdmin(),
      )(request);
    });

    router.get(
      '/api/admin/roles',
      _protect(adminHandler.getRoles, authMiddleware.requireAdmin()),
    );

    router.put('/api/admin/users/<id|[0-9]+>/role', (
      Request request,
      String id,
    ) {
      return _protect(
        (protectedRequest) => adminHandler.changeUserRole(protectedRequest, id),
        authMiddleware.requireAdmin(),
      )(request);
    });

    router.put('/api/admin/users/<id|[0-9]+>/block', (
      Request request,
      String id,
    ) {
      return _protect(
        (protectedRequest) =>
            adminHandler.changeBlockStatus(protectedRequest, id),
        authMiddleware.requireAdmin(),
      )(request);
    });

    router.get(
      '/api/admin/audit-logs',
      _protect(adminHandler.getAuditLogs, authMiddleware.requireAdmin()),
    );

    router.get(
      '/api/admin/import-files',
      _protect(adminHandler.getImportFiles, authMiddleware.requireAdmin()),
    );

    router.get(
      '/api/admin/exported-files',
      _protect(adminHandler.getExportedFiles, authMiddleware.requireAdmin()),
    );

    router.all('/<ignored|.*>', (Request request) {
      return JsonResponse.notFound(
        'Маршрут не найден: ${request.requestedUri.path}',
      );
    });

    return router.call;
  }

  Handler _protect(
    FutureOr<Response> Function(Request request) handler,
    Middleware middleware,
  ) {
    return middleware(
      (Request request) async {
        return handler(request);
      },
    );
  }
}