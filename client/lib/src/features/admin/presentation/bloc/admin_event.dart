part of 'admin_bloc.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class AdminStarted extends AdminEvent {
  const AdminStarted();
}

class AdminRefreshRequested extends AdminEvent {
  const AdminRefreshRequested();
}

class AdminSectionChanged extends AdminEvent {
  final AdminSection section;

  const AdminSectionChanged({
    required this.section,
  });

  @override
  List<Object?> get props => [section];
}

class AdminUserSearchChanged extends AdminEvent {
  final String query;

  const AdminUserSearchChanged({
    required this.query,
  });

  @override
  List<Object?> get props => [query];
}

class AdminUserRoleChanged extends AdminEvent {
  final int accountId;
  final int roleId;

  const AdminUserRoleChanged({
    required this.accountId,
    required this.roleId,
  });

  @override
  List<Object?> get props => [
        accountId,
        roleId,
      ];
}

class AdminUserBlockStatusChanged extends AdminEvent {
  final int accountId;
  final bool isBlocked;

  const AdminUserBlockStatusChanged({
    required this.accountId,
    required this.isBlocked,
  });

  @override
  List<Object?> get props => [
        accountId,
        isBlocked,
      ];
}