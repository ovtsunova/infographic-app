import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:client/src/features/admin/data/admin_models.dart';
import 'package:client/src/features/admin/data/admin_repository.dart';

part 'admin_event.dart';
part 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _repository;

  AdminBloc({
    required AdminRepository repository,
  })  : _repository = repository,
        super(const AdminState.initial()) {
    on<AdminStarted>(_onStarted);
    on<AdminRefreshRequested>(_onRefreshRequested);
    on<AdminSectionChanged>(_onSectionChanged);
    on<AdminUserSearchChanged>(_onUserSearchChanged);
    on<AdminUserRoleChanged>(_onUserRoleChanged);
    on<AdminUserBlockStatusChanged>(_onUserBlockStatusChanged);
  }

  Future<void> _onStarted(
    AdminStarted event,
    Emitter<AdminState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _onRefreshRequested(
    AdminRefreshRequested event,
    Emitter<AdminState> emit,
  ) async {
    await _loadData(emit);
  }

  void _onSectionChanged(
    AdminSectionChanged event,
    Emitter<AdminState> emit,
  ) {
    emit(
      state.copyWith(
        section: event.section,
        clearMessage: true,
      ),
    );
  }

  void _onUserSearchChanged(
    AdminUserSearchChanged event,
    Emitter<AdminState> emit,
  ) {
    emit(
      state.copyWith(
        searchQuery: event.query,
        clearMessage: true,
      ),
    );
  }

  Future<void> _onUserRoleChanged(
    AdminUserRoleChanged event,
    Emitter<AdminState> emit,
  ) async {
    final previousState = state;

    emit(
      state.copyWith(
        status: AdminStatus.submitting,
        clearMessage: true,
      ),
    );

    try {
      await _repository.changeUserRole(
        accountId: event.accountId,
        roleId: event.roleId,
      );

      await _loadData(
        emit,
        successMessage: 'Роль пользователя успешно изменена',
      );
    } catch (error) {
      emit(
        previousState.copyWith(
          status: AdminStatus.ready,
          message: error.toString(),
          messageIsError: true,
        ),
      );
    }
  }

  Future<void> _onUserBlockStatusChanged(
    AdminUserBlockStatusChanged event,
    Emitter<AdminState> emit,
  ) async {
    final previousState = state;

    emit(
      state.copyWith(
        status: AdminStatus.submitting,
        clearMessage: true,
      ),
    );

    try {
      await _repository.changeBlockStatus(
        accountId: event.accountId,
        isBlocked: event.isBlocked,
      );

      await _loadData(
        emit,
        successMessage: event.isBlocked
            ? 'Пользователь успешно заблокирован'
            : 'Пользователь успешно разблокирован',
      );
    } catch (error) {
      emit(
        previousState.copyWith(
          status: AdminStatus.ready,
          message: error.toString(),
          messageIsError: true,
        ),
      );
    }
  }

  Future<void> _loadData(
    Emitter<AdminState> emit, {
    String? successMessage,
  }) async {
    emit(
      state.copyWith(
        status: AdminStatus.loading,
        clearMessage: true,
      ),
    );

    try {
      final responses = await Future.wait<dynamic>([
        _repository.loadDashboard(),
        _repository.loadUsers(),
        _repository.loadRoles(),
        _repository.loadAuditLogs(limit: 100),
      ]);

      emit(
        state.copyWith(
          status: AdminStatus.ready,
          dashboard: responses[0] as AdminDashboardStats,
          users: responses[1] as List<AdminUser>,
          roles: responses[2] as List<AdminRole>,
          auditLogs: responses[3] as List<AdminAuditLog>,
          message: successMessage,
          messageIsError: false,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AdminStatus.failure,
          message: error.toString(),
          messageIsError: true,
        ),
      );
    }
  }
}