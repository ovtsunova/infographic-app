import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:client/src/core/utils/download_helper.dart';
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
        savedInfographicsRepository:
            context.read<SavedInfographicsRepository>(),
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      },
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Генерация инфографики',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Выберите учебные данные, показатель, тип диаграммы и параметры оформления. После этого приложение сформирует инфографику по выбранной статистике.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (state.isLoading && state.groups.isEmpty)
              const _LoadingCard()
            else if (state.status == InfographicBuilderStatus.failure)
              _FailureCard(
                message: state.message ?? 'Не удалось загрузить данные',
              )
            else ...[
              _FiltersCard(state: state),
              const SizedBox(height: 24),
              if (!state.hasRequiredData)
                const _MessageCard(
                  icon: Icons.info_outline_rounded,
                  title: 'Недостаточно данных',
                  message:
                      'Для построения инфографики нужны учебные группы, дисциплины, периоды, студенты и хотя бы оценки или посещаемость.',
                ),
              if (state.result != null) ...[
                const SizedBox(height: 24),
                _InfographicResultCard(
                  result: state.result!,
                  isSaving: state.isSaving,
                ),
              ],
            ],
          ],
        );
      },
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
            _AdaptiveFieldsGrid(
              children: [
                _SelectBox<String>(
                  label: 'Учебная группа',
                  value: state.selectedGroupId?.toString() ?? '',
                  options: [
                    const _SelectOption(
                      value: '',
                      label: 'Все группы',
                    ),
                    ...state.groups.map((group) {
                      return _SelectOption(
                        value: group.id.toString(),
                        label: group.groupName,
                      );
                    }),
                  ],
                  onChanged: (value) {
                    bloc.add(
                      InfographicGroupChanged(
                        groupId: _parseNullableId(value),
                      ),
                    );
                  },
                ),
                _SelectBox<String>(
                  label: 'Дисциплина',
                  value: state.selectedDisciplineId?.toString() ?? '',
                  options: [
                    const _SelectOption(
                      value: '',
                      label: 'Все дисциплины',
                    ),
                    ...state.disciplines.map((discipline) {
                      return _SelectOption(
                        value: discipline.id.toString(),
                        label: discipline.disciplineName,
                      );
                    }),
                  ],
                  onChanged: (value) {
                    bloc.add(
                      InfographicDisciplineChanged(
                        disciplineId: _parseNullableId(value),
                      ),
                    );
                  },
                ),
                _SelectBox<String>(
                  label: 'Учебный период',
                  value: state.selectedPeriodId?.toString() ?? '',
                  options: [
                    const _SelectOption(
                      value: '',
                      label: 'Все периоды',
                    ),
                    ...state.periods.map((period) {
                      return _SelectOption(
                        value: period.id.toString(),
                        label: period.title,
                      );
                    }),
                  ],
                  onChanged: (value) {
                    bloc.add(
                      InfographicPeriodChanged(
                        periodId: _parseNullableId(value),
                      ),
                    );
                  },
                ),
                _SelectBox<InfographicChartType>(
                  label: 'Показатель',
                  value: state.chartType,
                  options: InfographicChartType.values.map((chartType) {
                    return _SelectOption(
                      value: chartType,
                      label: chartType.title,
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    bloc.add(
                      InfographicChartTypeChanged(chartType: value),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),
            _VisualTypeSelector(
              selectedType: state.visualType,
              onChanged: (visualType) {
                bloc.add(
                  InfographicVisualTypeChanged(visualType: visualType),
                );
              },
            ),
            const SizedBox(height: 28),
            _AppearanceSettings(
              state: state,
              onColorSchemeChanged: (colorScheme) {
                bloc.add(
                  InfographicColorSchemeChanged(colorScheme: colorScheme),
                );
              },
              onShowLabelsChanged: (showLabels) {
                bloc.add(
                  InfographicShowLabelsChanged(showLabels: showLabels),
                );
              },
              onSortOrderChanged: (sortOrder) {
                bloc.add(
                  InfographicSortOrderChanged(sortOrder: sortOrder),
                );
              },
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: state.hasRequiredData
                      ? () {
                          bloc.add(const InfographicGenerateRequested());
                        }
                      : null,
                  icon: const Icon(Icons.auto_graph_rounded),
                  label: const Text('Сформировать инфографику'),
                ),
                OutlinedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          bloc.add(
                            const InfographicBuilderRefreshRequested(),
                          );
                        },
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: const Text('Обновить данные'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdaptiveFieldsGrid extends StatelessWidget {
  final List<Widget> children;

  const _AdaptiveFieldsGrid({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 20.0;
        final width = constraints.maxWidth;

        final columns = width >= 1050
            ? 3
            : width >= 700
                ? 2
                : 1;

        final itemWidth = (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 18,
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

class _SelectBox<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<_SelectOption<T>> options;
  final ValueChanged<T?> onChanged;

  const _SelectBox({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final containsValue = options.any((option) => option.value == value);

    return DropdownButtonFormField<T>(
      value: containsValue ? value : null,
      isExpanded: true,
      items: options.map((option) {
        return DropdownMenuItem<T>(
          value: option.value,
          child: Text(
            option.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      selectedItemBuilder: (context) {
        return options.map((option) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList();
      },
      onChanged: onChanged,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ).copyWith(
        labelText: label,
      ),
    );
  }
}

class _SelectOption<T> {
  final T value;
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
          spacing: 14,
          runSpacing: 14,
          children: InfographicVisualType.values.map((type) {
            final isSelected = type == selectedType;

            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onChanged(type),
              child: Container(
                width: 255,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
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
                    const SizedBox(width: 12),
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

class _AppearanceSettings extends StatelessWidget {
  final InfographicBuilderState state;
  final ValueChanged<InfographicColorScheme> onColorSchemeChanged;
  final ValueChanged<bool> onShowLabelsChanged;
  final ValueChanged<InfographicSortOrder> onSortOrderChanged;

  const _AppearanceSettings({
    required this.state,
    required this.onColorSchemeChanged,
    required this.onShowLabelsChanged,
    required this.onSortOrderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Оформление инфографики',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        _AdaptiveFieldsGrid(
          children: [
            _SelectBox<InfographicSortOrder>(
              label: 'Сортировка данных',
              value: state.sortOrder,
              options: InfographicSortOrder.values.map((sortOrder) {
                return _SelectOption(
                  value: sortOrder,
                  label: sortOrder.title,
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                onSortOrderChanged(value);
              },
            ),
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Показывать подписи',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch.adaptive(
                    value: state.showLabels,
                    onChanged: onShowLabelsChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ColorSchemeSelector(
          selectedScheme: state.colorScheme,
          onChanged: onColorSchemeChanged,
        ),
      ],
    );
  }
}

class _ColorSchemeSelector extends StatelessWidget {
  final InfographicColorScheme selectedScheme;
  final ValueChanged<InfographicColorScheme> onChanged;

  const _ColorSchemeSelector({
    required this.selectedScheme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: InfographicColorScheme.values.map((scheme) {
        final isSelected = scheme == selectedScheme;
        final colors = _schemeColors(context, scheme);

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onChanged(scheme),
          child: Container(
            width: 238,
            padding: const EdgeInsets.all(16),
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
                Row(
                  children: colors.take(3).map((color) {
                    return Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    scheme.title,
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
    );
  }
}

class _InfographicResultCard extends StatefulWidget {
  final InfographicResult result;
  final bool isSaving;

  const _InfographicResultCard({
    required this.result,
    required this.isSaving,
  });

  @override
  State<_InfographicResultCard> createState() => _InfographicResultCardState();
}

class _InfographicResultCardState extends State<_InfographicResultCard> {
  final GlobalKey _exportKey = GlobalKey();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

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
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: widget.isSaving ? null : () => _save(context),
                  icon: widget.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    widget.isSaving
                        ? 'Сохранение...'
                        : 'Сохранить инфографику',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isExporting || !result.hasChartData
                      ? null
                      : () => _exportPng(context),
                  icon: _isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(_isExporting ? 'Экспорт...' : 'Экспорт PNG'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            RepaintBoundary(
              key: _exportKey,
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    ],
                  ],
                ),
              ),
            ),
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

  Future<void> _exportPng(BuildContext context) async {
    setState(() {
      _isExporting = true;
    });

    try {
      await WidgetsBinding.instance.endOfFrame;

      final renderObject = _exportKey.currentContext?.findRenderObject();

      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        throw Exception('Не удалось подготовить область для экспорта.');
      }

      final pixelRatio = MediaQuery.of(context)
          .devicePixelRatio
          .clamp(2.0, 3.0)
          .toDouble();

      final image = await renderObject.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      final Uint8List? bytes = byteData?.buffer.asUint8List();

      if (bytes == null || bytes.isEmpty) {
        throw Exception('Не удалось сформировать PNG-файл.');
      }

      downloadFile(
        bytes: bytes,
        fileName: '${_safeFileName(widget.result.title)}.png',
        mimeType: 'image/png',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Инфографика экспортирована в PNG'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка экспорта: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  String _safeFileName(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_');

    if (normalized.isEmpty) {
      return 'infographic';
    }

    return normalized;
  }
}

class _SaveInfographicDialog extends StatefulWidget {
  const _SaveInfographicDialog();

  @override
  State<_SaveInfographicDialog> createState() =>
      _SaveInfographicDialogState();
}

class _SaveInfographicDialogState extends State<_SaveInfographicDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Сохранение инфографики'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Название',
          hintText: 'Например: Средний балл по группам',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  void _submit() {
    final title = _controller.text.trim();

    if (title.isEmpty) {
      return;
    }

    Navigator.of(context).pop(title);
  }
}

class _MetricsGrid extends StatelessWidget {
  final List<InfographicSummaryMetric> cards;

  const _MetricsGrid({
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 14.0;
        final width = constraints.maxWidth;

        final columns = width >= 980
            ? 3
            : width >= 640
                ? 2
                : 1;

        final itemWidth = (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((card) {
            return SizedBox(
              width: itemWidth,
              child: _MetricCard(metric: card),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final InfographicSummaryMetric metric;

  const _MetricCard({
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            metric.value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            result.visualType.icon,
            color: _chartColor(context, result, 0),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Построена ${result.visualType.title.toLowerCase()} диаграмма: ${result.chartType.title.toLowerCase()}. '
              'Сортировка: ${result.sortOrder.title.toLowerCase()}. '
              'Цветовая схема: ${result.colorScheme.title.toLowerCase()}.',
              style: const TextStyle(
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
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
        return _BarInfographicChart(result: result);
      case InfographicVisualType.line:
        return _LineInfographicChart(result: result);
      case InfographicVisualType.pie:
        return _PieInfographicChart(result: result);
    }
  }
}

class _BarInfographicChart extends StatelessWidget {
  final InfographicResult result;

  const _BarInfographicChart({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final items = result.chartItems;
    final maxY = _maxChartValue(items);

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final index = group.x.toInt();

              if (index < 0 || index >= items.length) {
                return null;
              }

              final item = items[index];

              return BarTooltipItem(
                '${item.label}\n${_formatNumber(item.value)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatNumber(value),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 54,
              getTitlesWidget: (value, meta) {
                final roundedIndex = value.round();

                if ((value - roundedIndex).abs() > 0.01) {
                  return const SizedBox.shrink();
                }

                if (roundedIndex < 0 || roundedIndex >= items.length) {
                  return const SizedBox.shrink();
                }

                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: SizedBox(
                    width: 90,
                    child: Text(
                      _shortLabel(items[roundedIndex].label),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: item.value,
                width: 24,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                color: _chartColor(context, result, index),
              ),
            ],
            showingTooltipIndicators: const [],
          );
        }).toList(),
      ),
    );
  }
}

class _LineInfographicChart extends StatelessWidget {
  final InfographicResult result;

  const _LineInfographicChart({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final items = result.chartItems;

    final spots = items.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.value,
      );
    }).toList();

    final maxX = spots.length <= 1 ? 1.0 : (spots.length - 1).toDouble();
    final maxY = _maxChartValue(items);
    final color = _chartColor(context, result, 0);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: false,
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final index = spot.x.round();

                if (index < 0 || index >= items.length) {
                  return null;
                }

                final item = items[index];

                return LineTooltipItem(
                  '${item.label}\n${_formatNumber(item.value)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatNumber(value),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 64,
              getTitlesWidget: (value, meta) {
                final roundedIndex = value.round();

                if ((value - roundedIndex).abs() > 0.01) {
                  return const SizedBox.shrink();
                }

                if (roundedIndex < 0 || roundedIndex >= items.length) {
                  return const SizedBox.shrink();
                }

                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: SizedBox(
                    width: 90,
                    child: Text(
                      _shortLabel(items[roundedIndex].label),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            barWidth: 4,
            color: color,
            dotData: FlDotData(
              show: result.showLabels,
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _PieInfographicChart extends StatelessWidget {
  final InfographicResult result;

  const _PieInfographicChart({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final items = result.chartItems.where((item) => item.value > 0).toList();
    final total = items.fold<double>(
      0,
      (previousValue, item) => previousValue + item.value,
    );

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 58,
              sections: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final percent = total <= 0 ? 0 : item.value / total * 100;

                return PieChartSectionData(
                  value: item.value,
                  title: result.showLabels
                      ? '${percent.toStringAsFixed(0)}%'
                      : '',
                  radius: 110,
                  color: _chartColor(context, result, index),
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 10,
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
                    color: _chartColor(context, result, index),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${item.label}: ${_formatNumber(item.value)}',
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w600,
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Загрузка учебных данных...',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailureCard extends StatelessWidget {
  final String message;

  const _FailureCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return _MessageCard(
      icon: Icons.error_outline_rounded,
      title: 'Ошибка загрузки данных',
      message: message,
      action: OutlinedButton.icon(
        onPressed: () {
          context.read<InfographicBuilderBloc>().add(
                const InfographicBuilderRefreshRequested(),
              );
        },
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Повторить'),
      ),
    );
  }
}

class _NoChartDataMessage extends StatelessWidget {
  const _NoChartDataMessage();

  @override
  Widget build(BuildContext context) {
    return const _MessageCard(
      icon: Icons.bar_chart_rounded,
      title: 'Нет данных для диаграммы',
      message:
          'По выбранным параметрам нет значений, которые можно отобразить на диаграмме.',
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

int? _parseNullableId(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  return int.tryParse(value);
}

double _maxChartValue(List<InfographicChartItem> items) {
  if (items.isEmpty) {
    return 1;
  }

  final maxValue = items.fold<double>(
    0,
    (previousValue, item) {
      if (item.value > previousValue) {
        return item.value;
      }

      return previousValue;
    },
  );

  if (maxValue <= 0) {
    return 1;
  }

  return maxValue * 1.25;
}

String _formatNumber(double value) {
  final fixed = value.toStringAsFixed(2);

  return fixed
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

String _shortLabel(String value) {
  if (value.length <= 14) {
    return value;
  }

  return '${value.substring(0, 13)}…';
}

Color _chartColor(
  BuildContext context,
  InfographicResult result,
  int index,
) {
  final colors = _schemeColors(context, result.colorScheme);

  return colors[index % colors.length];
}

List<Color> _schemeColors(
  BuildContext context,
  InfographicColorScheme scheme,
) {
  switch (scheme) {
    case InfographicColorScheme.blue:
      return [
        Theme.of(context).colorScheme.primary,
        Colors.lightBlue,
        Colors.indigo,
        Colors.cyan,
        Colors.blueGrey,
      ];
    case InfographicColorScheme.green:
      return [
        Colors.green,
        Colors.teal,
        Colors.lightGreen,
        Colors.lime,
        Colors.greenAccent,
      ];
    case InfographicColorScheme.orange:
      return [
        Colors.orange,
        Colors.deepOrange,
        Colors.amber,
        Colors.brown,
        Colors.yellow,
      ];
    case InfographicColorScheme.purple:
      return [
        Colors.purple,
        Colors.deepPurple,
        Colors.pink,
        Colors.indigo,
        Colors.purpleAccent,
      ];
  }
}