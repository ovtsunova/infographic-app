import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:client/src/features/saved_infographics/data/saved_infographics_models.dart';
import 'package:client/src/features/saved_infographics/data/saved_infographics_repository.dart';
import 'package:client/src/features/saved_infographics/presentation/bloc/saved_infographics_bloc.dart';

class SavedInfographicsPage extends StatelessWidget {
  const SavedInfographicsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SavedInfographicsBloc(
        repository: context.read<SavedInfographicsRepository>(),
      )..add(const SavedInfographicsStarted()),
      child: const _SavedInfographicsView(),
    );
  }
}

class _SavedInfographicsView extends StatelessWidget {
  const _SavedInfographicsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SavedInfographicsBloc, SavedInfographicsState>(
      listener: (context, state) {
        final message = state.message;

        if (message == null || message.trim().isEmpty) {
          return;
        }

        final isError = state.status == SavedInfographicsStatus.failure;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.red : null,
          ),
        );
      },
      builder: (context, state) {
        final showInitialLoading =
            state.status == SavedInfographicsStatus.loading &&
                !state.hasAnyData;

        return Stack(
          children: [
            ListView(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Сохранённые инфографики',
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
                              context.read<SavedInfographicsBloc>().add(
                                    const SavedInfographicsRefreshRequested(),
                                  );
                            },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Обновить'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Здесь отображаются ранее сформированные и сохранённые инфографические материалы пользователя.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                if (showInitialLoading)
                  const _LoadingCard()
                else if (state.status == SavedInfographicsStatus.failure &&
                    !state.hasAnyData)
                  _ErrorCard(message: state.message ?? 'Ошибка загрузки данных')
                else if (state.items.isEmpty)
                  const _EmptyCard()
                else
                  _InfographicsList(
                    items: state.items,
                    isBusy: state.isBusy,
                  ),
              ],
            ),
            if (state.status == SavedInfographicsStatus.submitting)
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Не удалось загрузить сохранённые инфографики',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                context.read<SavedInfographicsBloc>().add(
                      const SavedInfographicsRefreshRequested(),
                    );
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.insert_chart_outlined_rounded,
              size: 54,
              color: Color(0xFF2563EB),
            ),
            SizedBox(height: 16),
            Text(
              'Сохранённых инфографик пока нет',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Сформируйте инфографику в разделе генерации и сохраните результат.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfographicsList extends StatelessWidget {
  final List<SavedInfographic> items;
  final bool isBusy;

  const _InfographicsList({
    required this.items,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _InfographicCard(
            item: item,
            isBusy: isBusy,
          ),
        );
      }).toList(),
    );
  }
}

class _InfographicCard extends StatelessWidget {
  final SavedInfographic item;
  final bool isBusy;

  const _InfographicCard({
    required this.item,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    final metricCards = _readMetricCards(item.resultData);
    final chartItems = _readChartItems(item.resultData);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Удалить',
                  onPressed: isBusy ? null : () => _delete(context),
                  icon: const Icon(Icons.delete_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Тип диаграммы: ${item.chartType} • Дата создания: ${item.creationDate}',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            if (item.author != null) ...[
              const SizedBox(height: 4),
              Text(
                'Автор: ${item.author}',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 18),
            if (metricCards.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: metricCards.map((metric) {
                  return _MetricChip(
                    title: metric.title,
                    value: metric.value,
                  );
                }).toList(),
              ),
            if (chartItems.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Данные диаграммы: ${chartItems.map((item) => '${item.label}: ${item.value}').join(', ')}',
                style: const TextStyle(
                  color: Color(0xFF374151),
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Удаление инфографики'),
          content: Text(
            'Вы действительно хотите удалить инфографику "${item.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    context.read<SavedInfographicsBloc>().add(
          SavedInfographicDeleteRequested(id: item.id),
        );
  }
}

class _MetricChip extends StatelessWidget {
  final String title;
  final String value;

  const _MetricChip({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

List<_SavedMetric> _readMetricCards(Map<String, dynamic> resultData) {
  final cards = resultData['cards'];

  if (cards is! List) {
    return [];
  }

  return cards.whereType<Map>().map((item) {
    final map = Map<String, dynamic>.from(item);

    return _SavedMetric(
      title: map['title']?.toString() ?? '',
      value: map['value']?.toString() ?? '',
    );
  }).toList();
}

List<_SavedChartItem> _readChartItems(Map<String, dynamic> resultData) {
  final items = resultData['chartItems'];

  if (items is! List) {
    return [];
  }

  return items.whereType<Map>().map((item) {
    final map = Map<String, dynamic>.from(item);

    return _SavedChartItem(
      label: map['label']?.toString() ?? '',
      value: map['value']?.toString() ?? '',
    );
  }).toList();
}

class _SavedMetric {
  final String title;
  final String value;

  const _SavedMetric({
    required this.title,
    required this.value,
  });
}

class _SavedChartItem {
  final String label;
  final String value;

  const _SavedChartItem({
    required this.label,
    required this.value,
  });
}