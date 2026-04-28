import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:client/src/features/educational_data/data/educational_data_models.dart';
import 'package:client/src/features/educational_data/presentation/bloc/educational_data_bloc.dart';

class GradesTable extends StatelessWidget {
  final List<GradeRecord> grades;
  final List<Student> students;
  final List<Discipline> disciplines;
  final List<StudyPeriod> periods;
  final bool isAdmin;
  final bool isBusy;

  const GradesTable({
    super.key,
    required this.grades,
    required this.students,
    required this.disciplines,
    required this.periods,
    required this.isAdmin,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    if (grades.isEmpty) {
      return const Center(
        child: Text(
          'Оценки пока отсутствуют.',
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
              const DataColumn(label: Text('Оценка')),
              const DataColumn(label: Text('Тип контроля')),
              const DataColumn(label: Text('Дата')),
              if (isAdmin) const DataColumn(label: Text('Действия')),
            ],
            rows: grades.map((grade) {
              return DataRow(
                cells: [
                  DataCell(Text(grade.id.toString())),
                  DataCell(Text(grade.studentName)),
                  DataCell(Text(grade.disciplineName)),
                  DataCell(Text(grade.periodTitle)),
                  DataCell(Text(grade.gradeValue.toString())),
                  DataCell(Text(grade.controlType)),
                  DataCell(Text(grade.gradeDate ?? '—')),
                  if (isAdmin)
                    DataCell(
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: isBusy
                                ? null
                                : () => _openEditDialog(context, grade),
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: const Text('Изменить'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: isBusy
                                ? null
                                : () => _openDeleteDialog(context, grade),
                            icon: const Icon(Icons.delete_rounded, size: 18),
                            label: const Text('Удалить'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
    GradeRecord grade,
  ) async {
    final result = await showDialog<GradeFormData>(
      context: context,
      builder: (_) => GradeFormDialog(
        grade: grade,
        students: students,
        disciplines: disciplines,
        periods: periods,
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }

    context.read<EducationalDataBloc>().add(
          EducationalGradeUpdateRequested(
            id: grade.id,
            studentId: result.studentId,
            disciplineId: result.disciplineId,
            periodId: result.periodId,
            gradeValue: result.gradeValue,
            controlType: result.controlType,
            gradeDate: result.gradeDate ?? '',
          ),
        );
  }

  Future<void> _openDeleteDialog(
    BuildContext context,
    GradeRecord grade,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Удаление оценки'),
          content: Text(
            'Вы действительно хотите удалить оценку студента '
            '"${grade.studentName}" по дисциплине "${grade.disciplineName}"?',
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
          EducationalGradeDeleteRequested(id: grade.id),
        );
  }
}

class GradeFormDialog extends StatefulWidget {
  final GradeRecord? grade;
  final List<Student> students;
  final List<Discipline> disciplines;
  final List<StudyPeriod> periods;

  const GradeFormDialog({
    super.key,
    this.grade,
    required this.students,
    required this.disciplines,
    required this.periods,
  });

  @override
  State<GradeFormDialog> createState() => _GradeFormDialogState();
}

class _GradeFormDialogState extends State<GradeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _gradeValueController;
  late final TextEditingController _controlTypeController;
  late final TextEditingController _gradeDateController;

  int? _selectedStudentId;
  int? _selectedDisciplineId;
  int? _selectedPeriodId;

  bool get _isEditMode => widget.grade != null;

  @override
  void initState() {
    super.initState();

    final grade = widget.grade;

    _selectedStudentId = _hasStudent(grade?.studentId)
        ? grade?.studentId
        : null;

    _selectedDisciplineId = _hasDiscipline(grade?.disciplineId)
        ? grade?.disciplineId
        : null;

    _selectedPeriodId = _hasPeriod(grade?.periodId)
        ? grade?.periodId
        : null;

    _gradeValueController = TextEditingController(
      text: grade?.gradeValue.toString() ?? '',
    );

    _controlTypeController = TextEditingController(
      text: grade?.controlType ?? '',
    );

    _gradeDateController = TextEditingController(
      text: grade?.gradeDate ?? '',
    );
  }

  @override
  void dispose() {
    _gradeValueController.dispose();
    _controlTypeController.dispose();
    _gradeDateController.dispose();
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
    final gradeValue = int.tryParse(_gradeValueController.text.trim());

    if (studentId == null ||
        disciplineId == null ||
        periodId == null ||
        gradeValue == null) {
      return;
    }

    Navigator.of(context).pop(
      GradeFormData(
        studentId: studentId,
        disciplineId: disciplineId,
        periodId: periodId,
        gradeValue: gradeValue,
        controlType: _controlTypeController.text.trim(),
        gradeDate: _nullIfEmpty(_gradeDateController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditMode ? 'Редактирование оценки' : 'Добавление оценки',
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
                  controller: _gradeValueController,
                  decoration: const InputDecoration(
                    labelText: 'Оценка',
                    hintText: 'Например: 5',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _gradeValueValidator,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _controlTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Тип контроля',
                    hintText: 'Например: Экзамен',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Введите тип контроля';
                    }

                    if (text.length > 100) {
                      return 'Тип контроля слишком длинный';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _gradeDateController,
                  decoration: const InputDecoration(
                    labelText: 'Дата оценки',
                    hintText: 'Например: 2026-04-27',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Введите дату оценки';
                    }

                    return null;
                  },
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

class GradeFormData {
  final int studentId;
  final int disciplineId;
  final int periodId;
  final int gradeValue;
  final String controlType;
  final String? gradeDate;

  const GradeFormData({
    required this.studentId,
    required this.disciplineId,
    required this.periodId,
    required this.gradeValue,
    required this.controlType,
    required this.gradeDate,
  });
}

String? _gradeValueValidator(String? value) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) {
    return 'Введите оценку';
  }

  final number = int.tryParse(text);

  if (number == null) {
    return 'Введите целое число';
  }

  if (number < 2 || number > 5) {
    return 'Оценка должна быть от 2 до 5';
  }

  return null;
}

String? _nullIfEmpty(String value) {
  final text = value.trim();

  if (text.isEmpty) {
    return null;
  }

  return text;
}