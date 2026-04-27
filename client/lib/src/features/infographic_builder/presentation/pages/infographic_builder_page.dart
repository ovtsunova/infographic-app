import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:client/src/features/educational_data/data/educational_data_repository.dart';
import 'package:client/src/features/infographic_builder/presentation/bloc/infographic_builder_bloc.dart';
import 'package:client/src/features/saved_infographics/data/saved_infographics_repository.dart';

class InfographicBuilderPage extends StatelessWidget {
  const InfographicBuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InfographicBuilderBloc(
        educationalDataRepository: context.read<EducationalDataRepository>(),
        savedInfographicsRepository: context.read<SavedInfographicsRepository>(),
      )..add(const InfographicBuilderStarted()),
      child: const _InfographicBuilderView(),
    );
  }
}

class _InfographicBuilderView extends StatelessWidget {
  const _InfographicBuilderView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InfographicBuilderBloc, InfographicBuilderState>(
      listener: (context, state) {
        final message = state.message;

        if (message == null || message.trim().isEmpty) {
          return;
        }

        final isError = state.status == InfographicBuilderStatus.failure;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.red : null,
          ),
        );
      },
      builder: (context, state) {
        if (state.status == InfographicBuilderStatus.loading &&
            state.result == null) {
          return const _LoadingView();
        }

        if (state.status == InfographicBuilderStatus.failure) {
          return _ErrorView(
            message: state.message ?? 'Не удалось загрузить данные',
          );
        }

        return ListView(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Генерация инфографики',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          context
                              .read<InfographicBuilderBloc>()
                              .add(const InfographicBuilderRefreshRequested());
                        },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Обновить данные'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'В этом разделе пользователь выбирает учебные данные, параметры анализа и тип диаграммы, после чего система формирует инфографику по оценкам и посещаемости.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            _FiltersCard(state: state),
            const SizedBox(height: 24),
            if (state.result == null)
              const _StartCard()
            else
              _InfographicResultCard(
                result: state.result!,
                isSaving: state.isSaving,
              ),
          ],
        );
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text(
          'Генерация инфографики',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Не удалось загрузить данные',
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
                    context
                        .read<InfographicBuilderBloc>()
                        .add(const InfographicBuilderRefreshRequested());
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FiltersCard extends StatelessWidget {
  final InfographicBuilderState state;

  const _FiltersCard({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<InfographicBuilderBloc>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Параметры построения',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _SelectBox<int>(
                  label: 'Учебная группа',
                  value: state.selectedGroupId,
                  options: [
                    const _SelectOption<int>(
                      value: null,
                      label: 'Все группы',
                    ),
                    ...state.groups.map(
                      (group) => _SelectOption<int>(
                        value: group.id,
                        label: group.groupName,
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    bloc.add(InfographicGroupChanged(groupId: value));
                  },
                ),
                _SelectBox<int>(
                  label: 'Дисциплина',
                  value: state.selectedDisciplineId,
                  options: [
                    const _SelectOption<int>(
                      value: null,
                      label: 'Все дисциплины',
                    ),
                    ...state.disciplines.map(
                      (discipline) => _SelectOption<int>(
                        value: discipline.id,
                        label: discipline.disciplineName,
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    bloc.add(
                      InfographicDisciplineChanged(disciplineId: value),
                    );
                  },
                ),
                _SelectBox<int>(
                  label: 'Учебный период',
                  value: state.selectedPeriodId,
                  options: [
                    const _SelectOption<int>(
                      value: null,
                      label: 'Все периоды',
                    ),
                    ...state.periods.map(
                      (period) => _SelectOption<int>(
                        value: period.id,
                        label: period.title,
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    bloc.add(InfographicPeriodChanged(periodId: value));
                  },
                ),
                _SelectBox<InfographicChartType>(
                  label: 'Показатель',
                  value: state.chartType,
                  options: InfographicChartType.values.map((type) {
                    return _SelectOption<InfographicChartType>(
                      value: type,
                      label: type.title,
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    bloc.add(InfographicChartTypeChanged(chartType: value));
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _VisualTypeSelector(
              selectedType: state.visualType,
              onChanged: (type) {
                bloc.add(InfographicVisualTypeChanged(visualType: type));
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: state.hasRequiredData
                  ? () {
                      bloc.add(const InfographicGenerateRequested());
                    }
                  : null,
              icon: const Icon(Icons.auto_graph_rounded),
              label: const Text('Сформировать инфографику'),
            ),
            if (!state.hasRequiredData) ...[
              const SizedBox(height: 12),
              const Text(
                'Для построения инфографики нужны студенты, дисциплины, периоды и хотя бы одна запись оценок или посещаемости.',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectBox<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<_SelectOption<T>> options;
  final ValueChanged<T?> onChanged;

  const _SelectBox({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  String get _selectedLabel {
    for (final option in options) {
      if (option.value == value) {
        return option.label;
      }
    }

    if (options.isEmpty) {
      return 'Нет данных';
    }

    return options.first.label;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 310,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: options.isEmpty ? null : () => _openDialog(context),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          child: Text(
            _selectedLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDialog(BuildContext context) async {
    final selected = await showDialog<T?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(label),
          content: SizedBox(
            width: 420,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option.value == value;

                return ListTile(
                  selected: isSelected,
                  title: Text(option.label),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    Navigator.of(dialogContext).pop(option.value);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(value),
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) {
      return;
    }

    onChanged(selected);
  }
}

class _SelectOption<T> {
  final T? value;
  final String label;

  const _SelectOption({
    required this.value,
    required this.label,
  });
}

class _VisualTypeSelector extends StatelessWidget {
  final InfographicVisualType selectedType;
  final ValueChanged<InfographicVisualType> onChanged;

  const _VisualTypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Тип диаграммы',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: InfographicVisualType.values.map((type) {
            final isSelected = type == selectedType;

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onChanged(type),
              child: Container(
                width: 190,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFFE5E7EB),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      type.icon,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        type.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.query_stats_rounded,
              size: 54,
              color: Color(0xFF2563EB),
            ),
            SizedBox(height: 16),
            Text(
              'Выберите параметры и сформируйте инфографику',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Система рассчитает средний балл, успеваемость, посещаемость и построит диаграмму по выбранным данным.',
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

class _InfographicResultCard extends StatelessWidget {
  final InfographicResult result;
  final bool isSaving;

  const _InfographicResultCard({
    required this.result,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              result.subtitle,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isSaving ? null : () => _save(context),
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(isSaving ? 'Сохранение...' : 'Сохранить инфографику'),
            ),
            const SizedBox(height: 22),
            _MetricsGrid(cards: result.cards),
            const SizedBox(height: 28),
            if (!result.hasChartData)
              const _NoChartDataMessage()
            else ...[
              _ChartExplanation(result: result),
              const SizedBox(height: 18),
              SizedBox(
                height: result.visualType == InfographicVisualType.pie
                    ? 420
                    : 390,
                child: _ChartView(result: result),
              ),
              const SizedBox(height: 18),
              _ChartDataLegend(result: result),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => const _SaveInfographicDialog(),
    );

    if (title == null || title.trim().isEmpty || !context.mounted) {
      return;
    }

    context.read<InfographicBuilderBloc>().add(
          InfographicSaveRequested(title: title),
        );
  }
}

class _MetricsGrid extends StatelessWidget {
  final List<InfographicSummaryMetric> cards;

  const _MetricsGrid({
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 6 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: MediaQuery.of(context).size.width > 1200 ? 1.55 : 1.75,
      children: cards.map((card) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                card.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                card.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  height: 1.1,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _NoChartDataMessage extends StatelessWidget {
  const _NoChartDataMessage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Недостаточно данных для построения диаграммы по выбранным параметрам.',
          style: TextStyle(
            color: Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ChartExplanation extends StatelessWidget {
  final InfographicResult result;

  const _ChartExplanation({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final isPie = result.visualType == InfographicVisualType.pie;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Расшифровка диаграммы',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.chartType.description,
            style: const TextStyle(
              color: Color(0xFF374151),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          if (isPie) ...[
            Text(
              'Сектор диаграммы: ${result.chartType.xAxisTitle}',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            Text(
              'Размер сектора: ${result.chartType.yAxisTitle}',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ] else ...[
            Text(
              'Ось X: ${result.chartType.xAxisTitle}',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            Text(
              'Ось Y: ${result.chartType.yAxisTitle}',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Вид диаграммы: ${result.visualType.title}',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartDataLegend extends StatelessWidget {
  final InfographicResult result;

  const _ChartDataLegend({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: result.chartItems.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            '${result.chartType.itemLabelPrefix} ${item.label}: ${_formatChartValue(item.value)}',
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ChartView extends StatelessWidget {
  final InfographicResult result;

  const _ChartView({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    switch (result.visualType) {
      case InfographicVisualType.bar:
        return _BarChart(result: result);

      case InfographicVisualType.line:
        return _LineChart(result: result);

      case InfographicVisualType.pie:
        return _PieChart(result: result);
    }
  }
}

class _BarChart extends StatelessWidget {
  final InfographicResult result;

  const _BarChart({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = _maxValue(result.chartItems);

    return BarChart(
      BarChartData(
        maxY: maxValue <= 0 ? 1 : maxValue * 1.25,
        minY: 0,
        barGroups: result.chartItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: item.value,
                width: 28,
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          );
        }).toList(),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: false,
        ),
        titlesData: _cartesianChartTitles(result),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = result.chartItems[group.x.toInt()];

              return BarTooltipItem(
                '${item.label}\n${_formatChartValue(item.value)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  final InfographicResult result;

  const _LineChart({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = _maxValue(result.chartItems);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: result.chartItems.length <= 1
            ? 1
            : (result.chartItems.length - 1).toDouble(),
        minY: 0,
        maxY: maxValue <= 0 ? 1 : maxValue * 1.25,
        lineBarsData: [
          LineChartBarData(
            spots: result.chartItems.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                entry.value.value,
              );
            }).toList(),
            isCurved: true,
            barWidth: 3,
            color: Theme.of(context).colorScheme.primary,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            ),
          ),
        ],
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: false,
        ),
        titlesData: _cartesianChartTitles(result),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final index = spot.x.toInt();

                if (index < 0 || index >= result.chartItems.length) {
                  return null;
                }

                final item = result.chartItems[index];

                return LineTooltipItem(
                  '${item.label}\n${_formatChartValue(item.value)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class _PieChart extends StatelessWidget {
  final InfographicResult result;

  const _PieChart({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final items = result.chartItems.where((item) => item.value > 0).toList();

    if (items.isEmpty) {
      return const _NoChartDataMessage();
    }

    final total = items.fold<double>(
      0,
      (previousValue, item) => previousValue + item.value,
    );

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 54,
              sections: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final percent = total <= 0 ? 0 : item.value / total * 100;

                return PieChartSectionData(
                  value: item.value,
                  title: '${percent.toStringAsFixed(0)}%',
                  radius: 92,
                  color: _pieColor(context, index),
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _pieColor(context, index),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${result.chartType.itemLabelPrefix} ${item.label}: ${_formatChartValue(item.value)}',
                  style: const TextStyle(
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

FlTitlesData _cartesianChartTitles(InfographicResult result) {
  final maxValue = _maxValue(result.chartItems);
  final interval = _leftInterval(maxValue);

  return FlTitlesData(
    topTitles: AxisTitles(
      axisNameWidget: Text(
        result.chartType.yAxisTitle,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        ),
      ),
      axisNameSize: 28,
      sideTitles: const SideTitles(showTitles: false),
    ),
    rightTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 48,
        interval: interval,
        getTitlesWidget: (value, meta) {
          if (value < 0) {
            return const SizedBox.shrink();
          }

          if (!_isMultipleOfInterval(value, interval)) {
            return const SizedBox.shrink();
          }

          return Text(
            _formatChartValue(value),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          );
        },
      ),
    ),
    bottomTitles: AxisTitles(
      axisNameWidget: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          result.chartType.xAxisTitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      axisNameSize: 38,
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 64,
        interval: 1,
        getTitlesWidget: (value, meta) {
          if (!_isMultipleOfInterval(value, 1)) {
            return const SizedBox.shrink();
          }

          final index = value.toInt();

          if (index < 0 || index >= result.chartItems.length) {
            return const SizedBox.shrink();
          }

          final label = result.chartItems[index].label;

          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SizedBox(
              width: 86,
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

double _maxValue(List<InfographicChartItem> items) {
  return items.map((item) => item.value).fold<double>(
    0,
    (previousValue, value) {
      return value > previousValue ? value : previousValue;
    },
  );
}

double _leftInterval(double maxValue) {
  if (maxValue <= 5) {
    return 1;
  }

  if (maxValue <= 20) {
    return 5;
  }

  if (maxValue <= 100) {
    return 10;
  }

  return 25;
}

bool _isMultipleOfInterval(double value, double interval) {
  final remainder = value % interval;

  return remainder.abs() < 0.0001 || (interval - remainder).abs() < 0.0001;
}

String _formatChartValue(double value) {
  if ((value - value.round()).abs() < 0.0001) {
    return value.round().toString();
  }

  return value.toStringAsFixed(2);
}

Color _pieColor(BuildContext context, int index) {
  final colors = [
    Theme.of(context).colorScheme.primary,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
  ];

  return colors[index % colors.length];
}

extension _InfographicChartTypeUiText on InfographicChartType {
  String get description {
    switch (this) {
      case InfographicChartType.gradeDistribution:
        return 'Диаграмма показывает, сколько раз каждая оценка встречается в выбранных учебных данных. Например, если значение для оценки 5 равно 2, значит оценка 5 была выставлена два раза.';

      case InfographicChartType.averageGradeByGroup:
        return 'Диаграмма показывает средний балл по каждой учебной группе с учетом выбранной дисциплины и учебного периода. Чем выше значение, тем выше средняя успеваемость группы.';

      case InfographicChartType.attendanceByGroup:
        return 'Диаграмма показывает средний процент посещаемости по каждой учебной группе с учетом выбранной дисциплины и учебного периода.';
    }
  }

  String get xAxisTitle {
    switch (this) {
      case InfographicChartType.gradeDistribution:
        return 'Оценка';

      case InfographicChartType.averageGradeByGroup:
        return 'Учебная группа';

      case InfographicChartType.attendanceByGroup:
        return 'Учебная группа';
    }
  }

  String get yAxisTitle {
    switch (this) {
      case InfographicChartType.gradeDistribution:
        return 'Количество оценок';

      case InfographicChartType.averageGradeByGroup:
        return 'Средний балл';

      case InfographicChartType.attendanceByGroup:
        return 'Средняя посещаемость, %';
    }
  }

  String get itemLabelPrefix {
    switch (this) {
      case InfographicChartType.gradeDistribution:
        return 'Оценка';

      case InfographicChartType.averageGradeByGroup:
        return 'Группа';

      case InfographicChartType.attendanceByGroup:
        return 'Группа';
    }
  }
}

class _SaveInfographicDialog extends StatefulWidget {
  const _SaveInfographicDialog();

  @override
  State<_SaveInfographicDialog> createState() => _SaveInfographicDialogState();
}

class _SaveInfographicDialogState extends State<_SaveInfographicDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    Navigator.of(context).pop(_titleController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Сохранение инфографики'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Название инфографики',
              hintText: 'Например: Успеваемость ИСП-31',
            ),
            autofocus: true,
            validator: (value) {
              final text = value?.trim() ?? '';

              if (text.isEmpty) {
                return 'Введите название инфографики';
              }

              if (text.length > 150) {
                return 'Название слишком длинное';
              }

              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}