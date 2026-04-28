import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:client/src/app/app_router.dart';
import 'package:client/src/app/app_theme.dart';
import 'package:client/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client/src/shared/models/app_user.dart';

class SideMenu extends StatelessWidget {
  final String currentPath;
  final AppUserRole role;
  final VoidCallback? onNavigate;

  const SideMenu({
    super.key,
    required this.currentPath,
    required this.role,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final items = _getMenuItems(role);

    return Container(
      width: 280,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.sidebarColor,
        border: Border(
          right: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            children: [
              _Logo(role: role),
              const SizedBox(height: 26),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return _MenuTile(
                      item: item,
                      selected: currentPath == item.path,
                      onTap: () {
                        if (currentPath != item.path) {
                          context.go(item.path);
                        }

                        onNavigate?.call();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _BottomAction(
                role: role,
                onNavigate: onNavigate,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_MenuItemData> _getMenuItems(AppUserRole role) {
    final commonItems = <_MenuItemData>[
      const _MenuItemData(
        title: 'Главная',
        path: AppPaths.home,
        icon: Icons.home_rounded,
      ),
    ];

    final userItems = <_MenuItemData>[
      const _MenuItemData(
        title: 'Учебные данные',
        path: AppPaths.educationalData,
        icon: Icons.table_chart_rounded,
      ),
      const _MenuItemData(
        title: 'Генерация инфографики',
        path: AppPaths.infographicBuilder,
        icon: Icons.auto_graph_rounded,
      ),
      const _MenuItemData(
        title: 'Сохранённые результаты',
        path: AppPaths.savedInfographics,
        icon: Icons.folder_copy_rounded,
      ),
      const _MenuItemData(
        title: 'Профиль',
        path: AppPaths.profile,
        icon: Icons.person_rounded,
      ),
    ];

    final adminItems = <_MenuItemData>[
      const _MenuItemData(
        title: 'Администрирование',
        path: AppPaths.admin,
        icon: Icons.admin_panel_settings_rounded,
      ),
    ];

    if (role == AppUserRole.guest) {
      return commonItems;
    }

    if (role == AppUserRole.admin) {
      return [
        ...commonItems,
        ...adminItems,
        ...userItems,
      ];
    }

    return [
      ...commonItems,
      ...userItems,
    ];
  }
}

class _BottomAction extends StatelessWidget {
  final AppUserRole role;
  final VoidCallback? onNavigate;

  const _BottomAction({
    required this.role,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    if (role == AppUserRole.guest) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            context.go(AppPaths.login);
            onNavigate?.call();
          },
          icon: const Icon(Icons.login_rounded),
          label: const Text('Войти'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          final router = GoRouter.of(context);
          final authBloc = context.read<AuthBloc>();

          authBloc.add(const AuthLogoutRequested());
          router.go(AppPaths.home);

          onNavigate?.call();
        },
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Выйти'),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final AppUserRole role;

  const _Logo({
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                Color(0xFF4F46E5),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.insert_chart_rounded,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EduInfo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                role.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.mutedTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final _MenuItemData item;
  final bool selected;
  final VoidCallback onTap;

  const _MenuTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).colorScheme.primary;

    return Material(
      color: selected ? AppTheme.softBlueColor : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? selectedColor : AppTheme.borderColor,
            ),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 22,
                color: selected ? selectedColor : AppTheme.mutedTextColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? selectedColor : AppTheme.textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItemData {
  final String title;
  final String path;
  final IconData icon;

  const _MenuItemData({
    required this.title,
    required this.path,
    required this.icon,
  });
}
