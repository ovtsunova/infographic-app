import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:client/src/features/educational_data/data/educational_data_models.dart';
import 'package:client/src/features/educational_data/presentation/bloc/educational_data_bloc.dart';

class AttendanceTable extends StatelessWidget {
  final List<AttendanceRecord> attendance;
  final List<Student> students;
  final List<Discipline> disciplines;
  final List<StudyPeriod> periods;
  final bool isAdmin;
  final bool isBusy;

  const AttendanceTable({
    super.key,
    required this.attendance,
    required this.students,
    required this.disciplines,
    required this.periods,
    required this.isAdmin,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    if (attendance.isEmpty) {
      return const Center(
        child: Text(
          'Записи посещаемости пока отсутствуют.',
          style: TextStyle(
            color: Color(0xFF6B7280),
          ),
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: [
              const DataColumn(label: Text('ID')),
              const DataColumn(label: Text('Студент')),
              const DataColumn(label: Text('Дисциплина')),
              const DataColumn(label: Text('Период')),
              const DataColumn(label: Text('Посещено')),
              const DataColumn(label: Text('Пропущено')),
              const DataColumn(label: Text('Всего')),
              const DataColumn(label: Text('% посещаемости')),
              if (isAdmin) const DataColumn(label: Text('Действия')),
            ],
            rows: attendance.map((record) {
              return DataRow(
                cells: [
                  DataCell(Text(record.id.toString())),
                  DataCell(Text(record.studentName)),
                  DataCell(Text(record.disciplineName)),
                  DataCell(Text(record.periodTitle)),
                  DataCell(Text(record.attendedCount.toString())),
                  DataCell(Text(record.missedCount.toString())),
                  DataCell(Text(record.totalClasses.toString())),
                  DataCell(Text('${record.attendanceRate.toStringAsFixed(2)}%')),
                  if (isAdmin)
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Редактировать',
                            onPressed: isBusy
                                ? null
                                : () => _openEditDialog(context, record),
                            icon: const Icon(Icons.edit_rounded),
                          ),
                          IconButton(
                            tooltip: 'Удалить',
                            onPressed: isBusy
                                ? null
                                : () => _openDeleteDialog(context, record),
                            icon: const Icon(Icons.delete_rounded),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _openEditDialog(
    BuildContext context,
    AttendanceRecord record,
  ) async {
    final result = await showDialog<AttendanceFormData>(
      context: context,
      builder: (_) => AttendanceFormDialog(
        record: record,
        students: students,
        disciplines: disciplines,
        periods: periods,
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }

    context.read<EducationalDataBloc>().add(
          EducationalAttendanceUpdateRequested(
            id: record.id,
            studentId: result.studentId,
            disciplineId: result.disciplineId,
            periodId: result.periodId,
            attendedCount: result.attendedCount,
            missedCount: result.missedCount,
          ),
        );
  }

  Future<void> _openDeleteDialog(
    BuildContext context,
    AttendanceRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Удаление посещаемости'),
          content: Text(
            'Вы действительно хотите удалить запись посещаемости '
            'студента "${record.studentName}" по дисциплине '
            '"${record.disciplineName}"?',
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

    context.read<EducationalDataBloc>().add(
          EducationalAttendanceDeleteRequested(id: record.id),
        );
  }
}

class AttendanceFormDialog extends StatefulWidget {
  final AttendanceRecord? record;
  final List<Student> students;
  final List<Discipline> disciplines;
  final List<StudyPeriod> periods;

  const AttendanceFormDialog({
    super.key,
    this.record,
    required this.students,
    required this.disciplines,
    required this.periods,
  });

  @override
  State<AttendanceFormDialog> createState() => _AttendanceFormDialogState();
}

class _AttendanceFormDialogState extends State<AttendanceFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _attendedCountController;
  late final TextEditingController _missedCountController;

  int? _selectedStudentId;
  int? _selectedDisciplineId;
  int? _selectedPeriodId;

  bool get _isEditMode => widget.record != null;

  @override
  void initState() {
    super.initState();

    final record = widget.record;

    _selectedStudentId = _hasStudent(record?.studentId)
        ? record?.studentId
        : null;

    _selectedDisciplineId = _hasDiscipline(record?.disciplineId)
        ? record?.disciplineId
        : null;

    _selectedPeriodId = _hasPeriod(record?.periodId)
        ? record?.periodId
        : null;

    _attendedCountController = TextEditingController(
      text: record?.attendedCount.toString() ?? '',
    );

    _missedCountController = TextEditingController(
      text: record?.missedCount.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _attendedCountController.dispose();
    _missedCountController.dispose();
    super.dispose();
  }

  bool _hasStudent(int? id) {
    if (id == null) {
      return false;
    }

    return widget.students.any((student) => student.id == id);
  }

  bool _hasDiscipline(int? id) {
    if (id == null) {
      return false;
    }

    return widget.disciplines.any((discipline) => discipline.id == id);
  }

  bool _hasPeriod(int? id) {
    if (id == null) {
      return false;
    }

    return widget.periods.any((period) => period.id == id);
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final studentId = _selectedStudentId;
    final disciplineId = _selectedDisciplineId;
    final periodId = _selectedPeriodId;
    final attendedCount = int.tryParse(_attendedCountController.text.trim());
    final missedCount = int.tryParse(_missedCountController.text.trim());

    if (studentId == null ||
        disciplineId == null ||
        periodId == null ||
        attendedCount == null ||
        missedCount == null) {
      return;
    }

    Navigator.of(context).pop(
      AttendanceFormData(
        studentId: studentId,
        disciplineId: disciplineId,
        periodId: periodId,
        attendedCount: attendedCount,
        missedCount: missedCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditMode
            ? 'Редактирование посещаемости'
            : 'Добавление посещаемости',
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: _selectedStudentId,
                  decoration: const InputDecoration(
                    labelText: 'Студент',
                  ),
                  items: widget.students.map((student) {
                    return DropdownMenuItem<int>(
                      value: student.id,
                      child: Text(student.fullName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStudentId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Выберите студента';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: _selectedDisciplineId,
                  decoration: const InputDecoration(
                    labelText: 'Дисциплина',
                  ),
                  items: widget.disciplines.map((discipline) {
                    return DropdownMenuItem<int>(
                      value: discipline.id,
                      child: Text(discipline.disciplineName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDisciplineId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Выберите дисциплину';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: _selectedPeriodId,
                  decoration: const InputDecoration(
                    labelText: 'Учебный период',
                  ),
                  items: widget.periods.map((period) {
                    return DropdownMenuItem<int>(
                      value: period.id,
                      child: Text(period.title),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriodId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Выберите учебный период';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _attendedCountController,
                  decoration: const InputDecoration(
                    labelText: 'Количество посещенных занятий',
                    hintText: 'Например: 24',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => _nonNegativeIntValidator(
                    value,
                    emptyMessage: 'Введите количество посещенных занятий',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _missedCountController,
                  decoration: const InputDecoration(
                    labelText: 'Количество пропущенных занятий',
                    hintText: 'Например: 3',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => _nonNegativeIntValidator(
                    value,
                    emptyMessage: 'Введите количество пропущенных занятий',
                  ),
                ),
              ],
            ),
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
          child: Text(_isEditMode ? 'Сохранить' : 'Добавить'),
        ),
      ],
    );
  }
}

class AttendanceFormData {
  final int studentId;
  final int disciplineId;
  final int periodId;
  final int attendedCount;
  final int missedCount;

  const AttendanceFormData({
    required this.studentId,
    required this.disciplineId,
    required this.periodId,
    required this.attendedCount,
    required this.missedCount,
  });
}

String? _nonNegativeIntValidator(
  String? value, {
  required String emptyMessage,
}) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) {
    return emptyMessage;
  }

  final number = int.tryParse(text);

  if (number == null) {
    return 'Введите целое число';
  }

  if (number < 0) {
    return 'Значение не может быть отрицательным';
  }

  if (number > 999) {
    return 'Значение не должно превышать 999';
  }

  return null;
}