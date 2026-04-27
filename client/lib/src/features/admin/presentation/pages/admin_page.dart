import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:client/src/features/admin/data/admin_models.dart';
import 'package:client/src/features/admin/data/admin_repository.dart';
import 'package:client/src/features/admin/presentation/bloc/admin_bloc.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminBloc(
        repository: context.read<AdminRepository>(),
      )..add(const AdminStarted()),
      child: const _AdminView(),
    );
  }
}

class _AdminView extends StatelessWidget {
  const _AdminView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        final message = state.message;

        if (message == null || message.trim().isEmpty) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: state.messageIsError ? Colors.red : null,
          ),
        );
      },
      builder: (context, state) {
        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Административная панель',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: state.isBusy
                          ? null
                          : () {
                              context.read<AdminBloc>().add(
                                    const AdminRefreshRequested(),
                                  );
                            },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Обновить'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Управление пользователями, ролями, блокировками и просмотр журнала действий системы.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                if (state.isInitialLoading)
                  const _LoadingCard()
                else if (state.status == AdminStatus.failure &&
                    !state.hasAnyData)
                  _ErrorCard(
                    message: state.message ?? 'Не удалось загрузить данные',
                  )
                else ...[
                  _SectionSelector(section: state.section),
                  const SizedBox(height: 24),
                  if (state.section == AdminSection.overview)
                    _OverviewSection(dashboard: state.dashboard)
                  else if (state.section == AdminSection.users)
                    _UsersSection(state: state)
                  else
                    _AuditSection(logs: state.auditLogs),
                ],
              ],
            ),
            if (state.status == AdminStatus.submitting)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.white.withOpacity(0.45),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SectionSelector extends StatelessWidget {
  final AdminSection section;

  const _SectionSelector({
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_SectionItem>[
      const _SectionItem(
        section: AdminSection.overview,
        title: 'Сводка',
        icon: Icons.dashboard_rounded,
      ),
      const _SectionItem(
        section: AdminSection.users,
        title: 'Пользователи',
        icon: Icons.people_alt_rounded,
      ),
      const _SectionItem(
        section: AdminSection.audit,
        title: 'Журнал действий',
        icon: Icons.history_rounded,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) {
        final selected = item.section == section;

        return ChoiceChip(
          selected: selected,
          avatar: Icon(
            item.icon,
            size: 18,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : const Color(0xFF6B7280),
          ),
          label: Text(item.title),
          onSelected: (_) {
            context.read<AdminBloc>().add(
                  AdminSectionChanged(section: item.section),
                );
          },
        );
      }).toList(),
    );
  }
}

class _SectionItem {
  final AdminSection section;
  final String title;
  final IconData icon;

  const _SectionItem({
    required this.section,
    required this.title,
    required this.icon,
  });
}

class _OverviewSection extends StatelessWidget {
  final AdminDashboardStats? dashboard;

  const _OverviewSection({
    required this.dashboard,
  });

  @override
  Widget build(BuildContext context) {
    final stats = dashboard;

    if (stats == null) {
      return const _MessageCard(
        icon: Icons.info_outline_rounded,
        title: 'Нет данных',
        message: 'Сводная статистика пока недоступна.',
      );
    }

    return _AdaptiveGrid(
      minItemWidth: 260,
      spacing: 16,
      children: [
        _AdminStatCard(
          icon: Icons.people_alt_rounded,
          title: 'Пользователи',
          value: stats.usersCount.toString(),
          description: 'Всего учетных записей',
        ),
        _AdminStatCard(
          icon: Icons.block_rounded,
          title: 'Заблокированы',
          value: stats.blockedUsersCount.toString(),
          description: 'Пользователи без доступа',
        ),
        _AdminStatCard(
          icon: Icons.groups_rounded,
          title: 'Учебные группы',
          value: stats.groupsCount.toString(),
          description: 'Созданные группы',
        ),
        _AdminStatCard(
          icon: Icons.school_rounded,
          title: 'Студенты',
          value: stats.studentsCount.toString(),
          description: 'Записи студентов',
        ),
        _AdminStatCard(
          icon: Icons.menu_book_rounded,
          title: 'Дисциплины',
          value: stats.disciplinesCount.toString(),
          description: 'Учебные дисциплины',
        ),
        _AdminStatCard(
          icon: Icons.insert_chart_rounded,
          title: 'Инфографики',
          value: stats.infographicsCount.toString(),
          description: 'Сохранённые результаты',
        ),
      ],
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String description;

  const _AdminStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 34,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersSection extends StatelessWidget {
  final AdminState state;

  const _UsersSection({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final users = state.filteredUsers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _UserSearchField(initialValue: state.searchQuery),
        const SizedBox(height: 16),
        if (users.isEmpty)
          const _MessageCard(
            icon: Icons.search_off_rounded,
            title: 'Пользователи не найдены',
            message: 'По текущему поисковому запросу нет пользователей.',
          )
        else
          _TableCard(
            child: DataTable(
              headingRowHeight: 48,
              dataRowMinHeight: 62,
              dataRowMaxHeight: 82,
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('ФИО')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Роль')),
                DataColumn(label: Text('Статус')),
                DataColumn(label: Text('Действия')),
              ],
              rows: users.map((user) {
                return DataRow(
                  cells: [
                    DataCell(Text(user.accountId.toString())),
                    DataCell(
                      SizedBox(
                        width: 220,
                        child: Text(
                          user.fullName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 230,
                        child: Text(
                          user.email,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      _RoleDropdown(
                        user: user,
                        roles: state.roles,
                        isBusy: state.isBusy,
                      ),
                    ),
                    DataCell(_StatusBadge(isBlocked: user.isBlocked)),
                    DataCell(
                      _BlockButton(
                        user: user,
                        isBusy: state.isBusy,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _UserSearchField extends StatefulWidget {
  final String initialValue;

  const _UserSearchField({
    required this.initialValue,
  });

  @override
  State<_UserSearchField> createState() => _UserSearchFieldState();
}

class _UserSearchFieldState extends State<_UserSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _UserSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (value) {
        context.read<AdminBloc>().add(
              AdminUserSearchChanged(query: value),
            );
      },
      decoration: const InputDecoration(
        labelText: 'Поиск пользователя',
        hintText: 'ФИО, email, роль, статус или ID',
        prefixIcon: Icon(Icons.search_rounded),
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  final AdminUser user;
  final List<AdminRole> roles;
  final bool isBusy;

  const _RoleDropdown({
    required this.user,
    required this.roles,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    final roleIds = roles.map((role) => role.id).toSet();
    final selectedRoleId = roleIds.contains(user.roleId) ? user.roleId : null;

    return SizedBox(
      width: 190,
      child: DropdownButton<int>(
        value: selectedRoleId,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        hint: Text(
          user.roleName.isEmpty ? 'Роль' : user.roleName,
          overflow: TextOverflow.ellipsis,
        ),
        items: roles.map((role) {
          return DropdownMenuItem<int>(
            value: role.id,
            child: Text(
              role.roleName,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: isBusy
            ? null
            : (roleId) {
                if (roleId == null || roleId == user.roleId) {
                  return;
                }

                context.read<AdminBloc>().add(
                      AdminUserRoleChanged(
                        accountId: user.accountId,
                        roleId: roleId,
                      ),
                    );
              },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isBlocked;

  const _StatusBadge({
    required this.isBlocked,
  });

  @override
  Widget build(BuildContext context) {
    final color = isBlocked ? Colors.red : Colors.green;
    final text = isBlocked ? 'Заблокирован' : 'Активен';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _BlockButton extends StatelessWidget {
  final AdminUser user;
  final bool isBusy;

  const _BlockButton({
    required this.user,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isBusy
          ? null
          : () {
              context.read<AdminBloc>().add(
                    AdminUserBlockStatusChanged(
                      accountId: user.accountId,
                      isBlocked: !user.isBlocked,
                    ),
                  );
            },
      icon: Icon(
        user.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
      ),
      label: Text(user.isBlocked ? 'Разблокировать' : 'Блокировать'),
    );
  }
}

class _AuditSection extends StatelessWidget {
  final List<AdminAuditLog> logs;

  const _AuditSection({
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const _MessageCard(
        icon: Icons.history_rounded,
        title: 'Журнал действий пуст',
        message: 'Пока нет записей аудита для отображения.',
      );
    }

    return _TableCard(
      child: DataTable(
        headingRowHeight: 48,
        dataRowMinHeight: 58,
        dataRowMaxHeight: 78,
        columns: const [
          DataColumn(label: Text('Дата')),
          DataColumn(label: Text('Пользователь')),
          DataColumn(label: Text('Действие')),
          DataColumn(label: Text('Сущность')),
          DataColumn(label: Text('ID записи')),
        ],
        rows: logs.map((log) {
          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 160,
                  child: Text(
                    _formatDateTime(log.actionDate),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 220,
                  child: Text(
                    log.accountEmail ?? 'Система',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 220,
                  child: Text(
                    log.actionName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 180,
                  child: Text(
                    log.entityName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(log.entityId?.toString() ?? '—')),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final Widget child;

  const _TableCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

class _AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  const _AdaptiveGrid({
    required this.children,
    required this.minItemWidth,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = (width / minItemWidth).floor().clamp(1, 4);
        final itemWidth = (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return _MessageCard(
      icon: Icons.error_outline_rounded,
      title: 'Ошибка загрузки административных данных',
      message: message,
      action: ElevatedButton.icon(
        onPressed: () {
          context.read<AdminBloc>().add(
                const AdminRefreshRequested(),
              );
        },
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Повторить'),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: 14),
                    action!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(String value) {
  final normalized = value.trim().replaceFirst(' ', 'T');
  final parsed = DateTime.tryParse(normalized);

  if (parsed == null) {
    return value.isEmpty ? '—' : value;
  }

  String twoDigits(int number) {
    return number.toString().padLeft(2, '0');
  }

  return '${twoDigits(parsed.day)}.${twoDigits(parsed.month)}.${parsed.year} '
      '${twoDigits(parsed.hour)}:${twoDigits(parsed.minute)}';
}