import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:client/src/core/utils/download_helper.dart';
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

        final items = state.items.whereType<SavedInfographic>().toList();

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(24),
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
                  _ErrorCard(
                    message: state.message ?? 'Ошибка загрузки данных',
                  )
                else if (items.isEmpty)
                  const _EmptyCard()
                else
                  _InfographicsList(
                    items: items,
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
          padding: const EdgeInsets.only(bottom: 16),
          child: _SavedInfographicCard(
            item: item,
            isBusy: isBusy,
          ),
        );
      }).toList(),
    );
  }
}

class _SavedInfographicCard extends StatefulWidget {
  final SavedInfographic item;
  final bool isBusy;

  const _SavedInfographicCard({
    required this.item,
    required this.isBusy,
  });

  @override
  State<_SavedInfographicCard> createState() => _SavedInfographicCardState();
}

class _SavedInfographicCardState extends State<_SavedInfographicCard> {
  final GlobalKey _exportKey = GlobalKey();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final result = _SavedInfographicResult.fromItem(widget.item);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SavedInfographicHeader(
              item: widget.item,
              result: result,
              isBusy: widget.isBusy || _isExporting,
              isExporting: _isExporting,
              onDelete: () => _delete(context),
              onExport: result.hasChartData ? () => _exportPng(context) : null,
            ),
            const SizedBox(height: 18),
            RepaintBoundary(
              key: _exportKey,
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (result.metrics.isNotEmpty) ...[
                      _MetricsGrid(metrics: result.metrics),
                      const SizedBox(height: 22),
                    ],
                    _ChartInfoBox(result: result),
                    const SizedBox(height: 18),
                    if (!result.hasChartData)
                      const _NoChartDataCard()
                    else
                      SizedBox(
                        height: result.visualType == _SavedVisualType.pie
                            ? 420
                            : 390,
                        child: _SavedChartView(result: result),
                      ),
                  ],
                ),
              ),
            ),
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
            'Вы действительно хотите удалить инфографику "${widget.item.title}"?',
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
          SavedInfographicDeleteRequested(id: widget.item.id),
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

      final fileName = '${_safeFileName(widget.item.title)}.png';

      if (!mounted) {
        return;
      }

      await context.read<SavedInfographicsRepository>().recordExport(
            infographicId: widget.item.id,
            fileName: fileName,
            fileFormat: 'PNG',
          );

      downloadFile(
        bytes: bytes,
        fileName: fileName,
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
}

class _SavedInfographicHeader extends StatelessWidget {
  final SavedInfographic item;
  final _SavedInfographicResult result;
  final bool isBusy;
  final bool isExporting;
  final VoidCallback onDelete;
  final VoidCallback? onExport;

  const _SavedInfographicHeader({
    required this.item,
    required this.result,
    required this.isBusy,
    required this.isExporting,
    required this.onDelete,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 760;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 22,
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
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _InfoBadge(
                  icon: result.visualType.icon,
                  text: result.visualType.title,
                ),
                _InfoBadge(
                  icon: Icons.calendar_today_rounded,
                  text: item.creationDate,
                ),
                if (item.author != null)
                  _InfoBadge(
                    icon: Icons.person_rounded,
                    text: item.author!,
                  ),
                if (item.templateName != null)
                  _InfoBadge(
                    icon: Icons.dashboard_customize_rounded,
                    text: item.templateName!,
                  ),
              ],
            ),
          ],
        );

        final actions = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: isBusy ? null : onExport,
              icon: isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(isExporting ? 'Экспорт...' : 'Экспорт PNG'),
            ),
            IconButton(
              tooltip: 'Удалить',
              onPressed: isBusy ? null : onDelete,
              icon: const Icon(Icons.delete_rounded),
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 14),
              actions,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 18),
            actions,
          ],
        );
      },
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBadge({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final List<_SavedMetric> metrics;

  const _MetricsGrid({
    required this.metrics,
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
          children: metrics.map((metric) {
            return SizedBox(
              width: itemWidth,
              child: _MetricCard(metric: metric),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _SavedMetric metric;

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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _ChartInfoBox extends StatelessWidget {
  final _SavedInfographicResult result;

  const _ChartInfoBox({
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
              'Сохранённый результат: ${result.chartTitle.toLowerCase()}. '
              'Тип диаграммы: ${result.visualType.title.toLowerCase()}. '
              'Сортировка: ${result.sortOrderLabel.toLowerCase()}. '
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

class _SavedChartView extends StatelessWidget {
  final _SavedInfographicResult result;

  const _SavedChartView({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    switch (result.visualType) {
      case _SavedVisualType.bar:
        return _SavedBarChart(result: result);
      case _SavedVisualType.line:
        return _SavedLineChart(result: result);
      case _SavedVisualType.pie:
        return _SavedPieChart(result: result);
    }
  }
}

class _SavedBarChart extends StatelessWidget {
  final _SavedInfographicResult result;

  const _SavedBarChart({
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

class _SavedLineChart extends StatelessWidget {
  final _SavedInfographicResult result;

  const _SavedLineChart({
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

class _SavedPieChart extends StatelessWidget {
  final _SavedInfographicResult result;

  const _SavedPieChart({
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

class _NoChartDataCard extends StatelessWidget {
  const _NoChartDataCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Row(
          children: [
            Icon(
              Icons.bar_chart_rounded,
              color: Color(0xFF2563EB),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'В сохранённой инфографике нет данных, которые можно отобразить на диаграмме.',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedInfographicResult {
  final String title;
  final String subtitle;
  final String chartTitle;
  final _SavedVisualType visualType;
  final _SavedColorScheme colorScheme;
  final String sortOrderLabel;
  final bool showLabels;
  final List<_SavedMetric> metrics;
  final List<_SavedChartItem> chartItems;

  const _SavedInfographicResult({
    required this.title,
    required this.subtitle,
    required this.chartTitle,
    required this.visualType,
    required this.colorScheme,
    required this.sortOrderLabel,
    required this.showLabels,
    required this.metrics,
    required this.chartItems,
  });

  bool get hasChartData {
    return chartItems.any((item) => item.value > 0);
  }

  factory _SavedInfographicResult.fromItem(SavedInfographic item) {
    final resultData = item.resultData;
    final parameters = item.parameters;

    final title = _readString(resultData['title'], fallback: item.title);
    final subtitle = _readString(
      resultData['subtitle'],
      fallback: 'Сохранённая инфографика',
    );

    final chartTitle = _chartTypeTitle(
      _readString(
        resultData['chartType'],
        fallback: _readString(parameters['chartType']),
      ),
    );

    final visualType = _SavedVisualTypeX.fromRaw(
      _readString(
        resultData['visualType'],
        fallback: _readString(
          parameters['visualType'],
          fallback: item.chartType,
        ),
      ),
    );

    final colorScheme = _SavedColorSchemeX.fromRaw(
      _readString(
        resultData['colorScheme'],
        fallback: _readString(parameters['colorScheme']),
      ),
    );

    final sortOrderLabel = _sortOrderTitle(
      _readString(
        resultData['sortOrder'],
        fallback: _readString(parameters['sortOrder']),
      ),
    );

    final showLabels = _readBool(
      resultData['showLabels'] ?? parameters['showLabels'],
      fallback: true,
    );

    return _SavedInfographicResult(
      title: title,
      subtitle: subtitle,
      chartTitle: chartTitle,
      visualType: visualType,
      colorScheme: colorScheme,
      sortOrderLabel: sortOrderLabel,
      showLabels: showLabels,
      metrics: _readMetricCards(resultData),
      chartItems: _readChartItems(resultData),
    );
  }
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
  final double value;

  const _SavedChartItem({
    required this.label,
    required this.value,
  });
}

enum _SavedVisualType {
  bar,
  line,
  pie,
}

extension _SavedVisualTypeX on _SavedVisualType {
  String get title {
    switch (this) {
      case _SavedVisualType.bar:
        return 'Столбчатая';
      case _SavedVisualType.line:
        return 'Линейная';
      case _SavedVisualType.pie:
        return 'Круговая';
    }
  }

  IconData get icon {
    switch (this) {
      case _SavedVisualType.bar:
        return Icons.bar_chart_rounded;
      case _SavedVisualType.line:
        return Icons.show_chart_rounded;
      case _SavedVisualType.pie:
        return Icons.pie_chart_rounded;
    }
  }

  static _SavedVisualType fromRaw(String value) {
    switch (value.trim().toLowerCase()) {
      case 'line':
      case 'линейная':
        return _SavedVisualType.line;
      case 'pie':
      case 'круговая':
        return _SavedVisualType.pie;
      case 'bar':
      case 'столбчатая':
      default:
        return _SavedVisualType.bar;
    }
  }
}

enum _SavedColorScheme {
  blue,
  green,
  orange,
  purple,
}

extension _SavedColorSchemeX on _SavedColorScheme {
  String get title {
    switch (this) {
      case _SavedColorScheme.blue:
        return 'Синяя';
      case _SavedColorScheme.green:
        return 'Зелёная';
      case _SavedColorScheme.orange:
        return 'Оранжевая';
      case _SavedColorScheme.purple:
        return 'Фиолетовая';
    }
  }

  static _SavedColorScheme fromRaw(String value) {
    switch (value.trim().toLowerCase()) {
      case 'green':
      case 'зелёная':
      case 'зеленая':
        return _SavedColorScheme.green;
      case 'orange':
      case 'оранжевая':
        return _SavedColorScheme.orange;
      case 'purple':
      case 'фиолетовая':
        return _SavedColorScheme.purple;
      case 'blue':
      case 'синяя':
      default:
        return _SavedColorScheme.blue;
    }
  }
}

List<_SavedMetric> _readMetricCards(Map<dynamic, dynamic> resultData) {
  final cards = resultData['cards'];

  if (cards is! List) {
    return [];
  }

  return cards.whereType<Map>().map((item) {
    return _SavedMetric(
      title: _readString(item['title']),
      value: _readString(item['value']),
    );
  }).where((metric) {
    return metric.title.isNotEmpty || metric.value.isNotEmpty;
  }).toList();
}

List<_SavedChartItem> _readChartItems(Map<dynamic, dynamic> resultData) {
  final items = resultData['chartItems'];

  if (items is! List) {
    return [];
  }

  return items.whereType<Map>().map((item) {
    return _SavedChartItem(
      label: _readString(item['label'], fallback: 'Без названия'),
      value: _readDouble(item['value']),
    );
  }).toList();
}

String _readString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';

  if (text.isEmpty) {
    return fallback;
  }

  return text;
}

double _readDouble(dynamic value) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
}

bool _readBool(dynamic value, {required bool fallback}) {
  if (value is bool) {
    return value;
  }

  final text = value?.toString().trim().toLowerCase();

  if (text == 'true' || text == '1' || text == 'yes') {
    return true;
  }

  if (text == 'false' || text == '0' || text == 'no') {
    return false;
  }

  return fallback;
}

String _chartTypeTitle(String value) {
  switch (value.trim().toLowerCase()) {
    case 'gradedistribution':
      return 'Распределение оценок';
    case 'averagegradebygroup':
      return 'Средний балл по группам';
    case 'attendancebygroup':
      return 'Посещаемость по группам';
    default:
      return value.trim().isEmpty ? 'Инфографика' : value;
  }
}

String _sortOrderTitle(String value) {
  switch (value.trim().toLowerCase()) {
    case 'ascending':
      return 'По возрастанию';
    case 'descending':
      return 'По убыванию';
    case 'source':
    default:
      return 'Без сортировки';
  }
}

double _maxChartValue(List<_SavedChartItem> items) {
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

Color _chartColor(
  BuildContext context,
  _SavedInfographicResult result,
  int index,
) {
  final colors = _schemeColors(context, result.colorScheme);

  return colors[index % colors.length];
}

List<Color> _schemeColors(
  BuildContext context,
  _SavedColorScheme scheme,
) {
  switch (scheme) {
    case _SavedColorScheme.blue:
      return [
        Theme.of(context).colorScheme.primary,
        Colors.lightBlue,
        Colors.indigo,
        Colors.cyan,
        Colors.blueGrey,
      ];
    case _SavedColorScheme.green:
      return [
        Colors.green,
        Colors.teal,
        Colors.lightGreen,
        Colors.lime,
        Colors.greenAccent,
      ];
    case _SavedColorScheme.orange:
      return [
        Colors.orange,
        Colors.deepOrange,
        Colors.amber,
        Colors.brown,
        Colors.yellow,
      ];
    case _SavedColorScheme.purple:
      return [
        Colors.purple,
        Colors.deepPurple,
        Colors.pink,
        Colors.indigo,
        Colors.purpleAccent,
      ];
  }
}