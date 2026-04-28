import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:client/src/app/app_router.dart';
import 'package:client/src/app/app_theme.dart';
import 'package:client/src/features/auth/presentation/bloc/auth_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isAuthenticated = state.isAuthenticated;
        final startPath = getAuthenticatedStartPath(state.role);

        return ListView(
          children: [
            _HeroSection(
              isAuthenticated: isAuthenticated,
              startPath: startPath,
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1050;

                return GridView.count(
                  crossAxisCount: isWide ? 3 : 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: isWide ? 1.65 : 4.2,
                  children: const [
                    _FeatureCard(
                      icon: Icons.upload_file_rounded,
                      title: 'Загрузка данных',
                      description:
                          'Импорт CSV, ручной ввод и проверка учебной статистики перед анализом.',
                    ),
                    _FeatureCard(
                      icon: Icons.filter_alt_rounded,
                      title: 'Анализ показателей',
                      description:
                          'Фильтрация по группам, дисциплинам и учебным периодам без ручных расчетов.',
                    ),
                    _FeatureCard(
                      icon: Icons.insert_chart_rounded,
                      title: 'Инфографика',
                      description:
                          'Построение диаграмм, сохранение результатов и экспорт готовых материалов.',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            const _ProcessCard(),
          ],
        );
      },
    );
  }
}

class _HeroSection extends StatelessWidget {
  final bool isAuthenticated;
  final String startPath;

  const _HeroSection({
    required this.isAuthenticated,
    required this.startPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFEEF4FF),
          ],
        ),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.softBlueColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Text(
                  'Учебная статистика в наглядном виде',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Веб-приложение для генерации инфографики по учебной статистике',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 14),
              const Text(
                'Система помогает загружать учебные данные, анализировать показатели и формировать понятные диаграммы для отчетов и аналитических материалов.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.mutedTextColor,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 26),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.go(
                      isAuthenticated ? AppPaths.infographicBuilder : AppPaths.login,
                    ),
                    icon: const Icon(Icons.auto_graph_rounded),
                    label: Text(
                      isAuthenticated ? 'Создать инфографику' : 'Начать работу',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go(
                      isAuthenticated ? startPath : AppPaths.login,
                    ),
                    icon: const Icon(Icons.table_chart_rounded),
                    label: Text(
                      isAuthenticated ? 'Открыть рабочую область' : 'Войти в систему',
                    ),
                  ),
                ],
              ),
            ],
          );

          if (!isWide) {
            return content;
          }

          return Row(
            children: [
              Expanded(
                flex: 3,
                child: content,
              ),
              const SizedBox(width: 34),
              const Expanded(
                flex: 2,
                child: _HeroPreview(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroPreview extends StatelessWidget {
  const _HeroPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 318,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Отчет по группе',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Средний балл и посещаемость',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppTheme.mutedTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _PreviewBar(label: 'Успеваемость', value: 0.86),
          const SizedBox(height: 12),
          const _PreviewBar(label: 'Посещаемость', value: 0.74),
          const SizedBox(height: 12),
          const _PreviewBar(label: 'Активность', value: 0.68),
          const SizedBox(height: 18),
          const Row(
            children: [
              _MiniMetric(value: '4.3', label: 'средний балл'),
              SizedBox(width: 12),
              _MiniMetric(value: '82%', label: 'посещаемость'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewBar extends StatelessWidget {
  final String label;
  final double value;

  const _PreviewBar({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(
                color: AppTheme.mutedTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 9,
            backgroundColor: const Color(0xFFE5E7EB),
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String value;
  final String label;

  const _MiniMetric({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.mutedTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.softBlueColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.mutedTextColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessCard extends StatelessWidget {
  const _ProcessCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Как работает приложение',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 16),
            _ProcessStep(
              number: '01',
              title: 'Добавьте учебные данные',
              text: 'Заполните группы, студентов, дисциплины, оценки и посещаемость вручную или через импорт CSV.',
            ),
            _ProcessStep(
              number: '02',
              title: 'Настройте параметры анализа',
              text: 'Выберите группу, дисциплину, период, тип диаграммы и шаблон оформления.',
            ),
            _ProcessStep(
              number: '03',
              title: 'Сохраните результат',
              text: 'Сформируйте инфографику, сохраните ее в системе и экспортируйте в файл.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessStep extends StatelessWidget {
  final String number;
  final String title;
  final String text;

  const _ProcessStep({
    required this.number,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.softBlueColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppTheme.mutedTextColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
