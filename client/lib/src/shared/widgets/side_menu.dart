import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:client/src/app/app_router.dart';
import 'package:client/src/shared/models/app_user.dart';

class SideMenu extends StatelessWidget {
  final String currentPath;
  final AppUserRole role;
  final VoidCallback? onNavigate;
  final VoidCallback? onLogout;

  const SideMenu({
    super.key,
    required this.currentPath,
    required this.role,
    this.onNavigate,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final items = _getMenuItems(role);

    return Container(
      width: 280,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            children: [
              _Logo(role: role),
              const SizedBox(height: 28),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
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
              if (role == AppUserRole.guest)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go(AppPaths.login);
                      onNavigate?.call();
                    },
                    child: const Text('Войти'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Выйти'),
                  ),
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
        title: 'Панель',
        path: AppPaths.dashboard,
        icon: Icons.dashboard_rounded,
      ),
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
      return [
        ...commonItems,
        const _MenuItemData(
          title: 'Авторизация',
          path: AppPaths.login,
          icon: Icons.login_rounded,
        ),
        const _MenuItemData(
          title: 'Регистрация',
          path: AppPaths.register,
          icon: Icons.person_add_alt_1_rounded,
        ),
      ];
    }

    if (role == AppUserRole.admin) {
      return [
        ...commonItems,
        ...userItems,
        ...adminItems,
      ];
    }

    return [
      ...commonItems,
      ...userItems,
    ];
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(14),
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
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                role.title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
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
      color: selected ? const Color(0xFFEFF6FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? selectedColor : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 21,
                color: selected ? selectedColor : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? selectedColor : const Color(0xFF172033),
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