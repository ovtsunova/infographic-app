import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text(
          'Веб-приложение для генерации инфографики по учебной статистике',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Система предназначена для загрузки, обработки, анализа и визуального представления учебных данных в виде диаграмм, графиков и инфографических материалов.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            ElevatedButton.icon(
              onPressed: () => context.go(AppPaths.infographicBuilder),
              icon: const Icon(Icons.auto_graph_rounded),
              label: const Text('Создать инфографику'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go(AppPaths.educationalData),
              icon: const Icon(Icons.table_chart_rounded),
              label: const Text('Перейти к данным'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 1100 ? 3 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: MediaQuery.of(context).size.width > 1100 ? 1.35 : 3.2,
          children: const [
            _FeatureCard(
              icon: Icons.upload_file_rounded,
              title: 'Загрузка данных',
              description:
                  'Импорт учебной статистики, ручной ввод и последующая проверка корректности данных.',
            ),
            _FeatureCard(
              icon: Icons.filter_alt_rounded,
              title: 'Анализ показателей',
              description:
                  'Фильтрация по группам, дисциплинам, периодам и типам статистических показателей.',
            ),
            _FeatureCard(
              icon: Icons.insert_chart_rounded,
              title: 'Генерация инфографики',
              description:
                  'Построение визуальных материалов, сохранение результатов и экспорт в файл.',
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
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
            const SizedBox(height: 16),
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
                fontSize: 14,
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