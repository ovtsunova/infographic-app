import 'package:flutter/material.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text(
          'Административная панель',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Раздел предназначен для управления пользователями, учебными данными, шаблонами инфографики, журналом действий и резервным копированием.',
          style: TextStyle(
            color: Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 1100 ? 3 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: MediaQuery.of(context).size.width > 1100 ? 1.7 : 3.2,
          children: const [
            _AdminCard(
              icon: Icons.people_alt_rounded,
              title: 'Пользователи',
              description: 'Просмотр, блокировка и изменение ролей пользователей.',
            ),
            _AdminCard(
              icon: Icons.dataset_rounded,
              title: 'Учебные данные',
              description: 'Контроль групп, дисциплин, периодов и статистических записей.',
            ),
            _AdminCard(
              icon: Icons.history_rounded,
              title: 'Журнал действий',
              description: 'Просмотр действий пользователей и административных операций.',
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _AdminCard({
    required this.icon,
    required this.title,
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
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
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