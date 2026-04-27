import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:client/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client/src/features/educational_data/data/educational_data_models.dart';
import 'package:client/src/features/educational_data/data/educational_data_repository.dart';
import 'package:client/src/features/educational_data/presentation/bloc/educational_data_bloc.dart';
import 'package:client/src/features/educational_data/presentation/widgets/attendance_widgets.dart';
import 'package:client/src/features/educational_data/presentation/widgets/grades_widgets.dart';
import 'package:client/src/shared/models/app_user.dart';

class EducationalDataPage extends StatelessWidget {
  const EducationalDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EducationalDataBloc(
        repository: context.read<EducationalDataRepository>(),
      )..add(const EducationalDataStarted()),
      child: const _EducationalDataView(),
    );
  }
}

class _EducationalDataView extends StatelessWidget {
  const _EducationalDataView();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAdmin = authState.role.isAdmin;

    return BlocConsumer<EducationalDataBloc, EducationalDataState>(
      listener: (context, state) {
        if (state.message == null || state.message!.trim().isEmpty) {
          return;
        }

        final isError = state.status == EducationalDataStatus.failure;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message!),
            backgroundColor: isError ? Colors.red : null,
          ),
        );
      },
      builder: (context, state) {
        final showInitialLoading =
            state.status == EducationalDataStatus.loading && !state.hasAnyData;

        return Stack(
          children: [
            ListView(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Учебные данные',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isAdmin)
                      PopupMenuButton<_AddEntityType>(
                        enabled: !state.isBusy,
                        tooltip: 'Добавить',
                        onSelected: (type) => _openCreateDialog(
                          context: context,
                          type: type,
                          state: state,
                        ),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: _AddEntityType.group,
                            child: Text('Добавить группу'),
                          ),
                          PopupMenuItem(
                            value: _AddEntityType.discipline,
                            child: Text('Добавить дисциплину'),
                          ),
                          PopupMenuItem(
                            value: _AddEntityType.period,
                            child: Text('Добавить период'),
                          ),
                          PopupMenuItem(
                            value: _AddEntityType.student,
                            child: Text('Добавить студента'),
                          ),
                          PopupMenuItem(
                            value: _AddEntityType.grade,
                            child: Text('Добавить оценку'),
                          ),
                          PopupMenuItem(
                            value: _AddEntityType.attendance,
                            child: Text('Добавить посещаемость'),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: state.isBusy
                                ? Colors.grey.shade300
                                : Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Добавить',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (isAdmin) const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: state.isBusy
                          ? null
                          : () {
                              context
                                  .read<EducationalDataBloc>()
                                  .add(const EducationalDataRefreshRequested());
                            },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Обновить'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Раздел предназначен для просмотра и администрирования учебных групп, дисциплин, учебных периодов, студентов, оценок и посещаемости.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                if (showInitialLoading)
                  const _LoadingCard()
                else if (state.status == EducationalDataStatus.failure &&
                    !state.hasAnyData)
                  _ErrorCard(message: state.message ?? 'Ошибка загрузки данных')
                else
                  _LoadedContent(
                    state: state,
                    isAdmin: isAdmin,
                  ),
              ],
            ),
            if (state.status == EducationalDataStatus.submitting)
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

  Future<void> _openCreateDialog({
    required BuildContext context,
    required _AddEntityType type,
    required EducationalDataState state,
  }) async {
    switch (type) {
      case _AddEntityType.group:
        final result = await showDialog<_GroupFormData>(
          context: context,
          builder: (_) => const _GroupFormDialog(),
        );

        if (result == null || !context.mounted) {
          return;
        }

        context.read<EducationalDataBloc>().add(
              EducationalGroupCreateRequested(
                groupName: result.groupName,
                course: result.course,
                studyYear: result.studyYear,
                directionName: result.directionName,
              ),
            );
        return;

      case _AddEntityType.discipline:
        final result = await showDialog<_DisciplineFormData>(
          context: context,
          builder: (_) => const _DisciplineFormDialog(),
        );

        if (result == null || !context.mounted) {
          return;
        }

        context.read<EducationalDataBloc>().add(
              EducationalDisciplineCreateRequested(
                disciplineName: result.disciplineName,
                description: result.description,
                teacherName: result.teacherName,
              ),
            );
        return;

      case _AddEntityType.period:
        final result = await showDialog<_PeriodFormData>(
          context: context,
          builder: (_) => const _PeriodFormDialog(),
        );

        if (result == null || !context.mounted) {
          return;
        }

        context.read<EducationalDataBloc>().add(
              EducationalPeriodCreateRequested(
                studyYear: result.studyYear,
                semester: result.semester,
                startDate: result.startDate,
                endDate: result.endDate,
              ),
            );
        return;

      case _AddEntityType.student:
        if (state.groups.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Сначала добавьте хотя бы одну учебную группу'),
            ),
          );
          return;
        }

        final result = await showDialog<_StudentFormData>(
          context: context,
          builder: (_) => _StudentFormDialog(groups: state.groups),
        );

        if (result == null || !context.mounted) {
          return;
        }

        context.read<EducationalDataBloc>().add(
              EducationalStudentCreateRequested(
                lastName: result.lastName,
                firstName: result.firstName,
                patronymic: result.patronymic,
                recordBookNumber: result.recordBookNumber,
                groupId: result.groupId,
              ),
            );
        return;

      case _AddEntityType.grade:
        if (state.students.isEmpty ||
            state.disciplines.isEmpty ||
            state.periods.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Для добавления оценки должны быть созданы студенты, дисциплины и учебные периоды',
              ),
            ),
          );
          return;
        }

        final result = await showDialog<GradeFormData>(
          context: context,
          builder: (_) => GradeFormDialog(
            students: state.students,
            disciplines: state.disciplines,
            periods: state.periods,
          ),
        );

        if (result == null || !context.mounted) {
          return;
        }

        context.read<EducationalDataBloc>().add(
              EducationalGradeCreateRequested(
                studentId: result.studentId,
                disciplineId: result.disciplineId,
                periodId: result.periodId,
                gradeValue: result.gradeValue,
                controlType: result.controlType,
                gradeDate: result.gradeDate,
              ),
            );
        return;

      case _AddEntityType.attendance:
        if (state.students.isEmpty ||
            state.disciplines.isEmpty ||
            state.periods.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Для добавления посещаемости должны быть созданы студенты, дисциплины и учебные периоды',
              ),
            ),
          );
          return;
        }

        final result = await showDialog<AttendanceFormData>(
          context: context,
          builder: (_) => AttendanceFormDialog(
            students: state.students,
            disciplines: state.disciplines,
            periods: state.periods,
          ),
        );

        if (result == null || !context.mounted) {
          return;
        }

        context.read<EducationalDataBloc>().add(
              EducationalAttendanceCreateRequested(
                studentId: result.studentId,
                disciplineId: result.disciplineId,
                periodId: result.periodId,
                attendedCount: result.attendedCount,
                missedCount: result.missedCount,
              ),
            );
        return;
    }
  }
}

enum _AddEntityType {
  group,
  discipline,
  period,
  student,
  grade,
  attendance,
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
              'Не удалось загрузить учебные данные',
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
                    .read<EducationalDataBloc>()
                    .add(const EducationalDataRefreshRequested());
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

class _LoadedContent extends StatelessWidget {
  final EducationalDataState state;
  final bool isAdmin;

  const _LoadedContent({
    required this.state,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 6 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: MediaQuery.of(context).size.width > 1200 ? 1.55 : 1.75,
          children: [
            _SummaryCard(
              title: 'Группы',
              value: state.groups.length.toString(),
              icon: Icons.groups_rounded,
            ),
            _SummaryCard(
              title: 'Дисциплины',
              value: state.disciplines.length.toString(),
              icon: Icons.menu_book_rounded,
            ),
            _SummaryCard(
              title: 'Периоды',
              value: state.periods.length.toString(),
              icon: Icons.calendar_month_rounded,
            ),
            _SummaryCard(
              title: 'Студенты',
              value: state.students.length.toString(),
              icon: Icons.school_rounded,
            ),
            _SummaryCard(
              title: 'Оценки',
              value: state.grades.length.toString(),
              icon: Icons.grade_rounded,
            ),
            _SummaryCard(
              title: 'Посещаемость',
              value: state.attendance.length.toString(),
              icon: Icons.event_available_rounded,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: DefaultTabController(
              length: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'Учебные группы'),
                      Tab(text: 'Дисциплины'),
                      Tab(text: 'Периоды'),
                      Tab(text: 'Студенты'),
                      Tab(text: 'Оценки'),
                      Tab(text: 'Посещаемость'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 430,
                    child: TabBarView(
                      children: [
                        _GroupsTable(
                          groups: state.groups,
                          isAdmin: isAdmin,
                          isBusy: state.isBusy,
                        ),
                        _DisciplinesTable(
                          disciplines: state.disciplines,
                          isAdmin: isAdmin,
                          isBusy: state.isBusy,
                        ),
                        _PeriodsTable(
                          periods: state.periods,
                          isAdmin: isAdmin,
                          isBusy: state.isBusy,
                        ),
                        _StudentsTable(
                          students: state.students,
                          groups: state.groups,
                          isAdmin: isAdmin,
                          isBusy: state.isBusy,
                        ),
                        GradesTable(
                          grades: state.grades,
                          students: state.students,
                          disciplines: state.disciplines,
                          periods: state.periods,
                          isAdmin: isAdmin,
                          isBusy: state.isBusy,
                        ),
                        AttendanceTable(
                          attendance: state.attendance,
                          students: state.students,
                          disciplines: state.disciplines,
                          periods: state.periods,
                          isAdmin: isAdmin,
                          isBusy: state.isBusy,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 26,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupsTable extends StatelessWidget {
  final List<StudyGroup> groups;
  final bool isAdmin;
  final bool isBusy;

  const _GroupsTable({
    required this.groups,
    required this.isAdmin,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const _EmptyListMessage(text: 'Учебные группы пока отсутствуют.');
    }

    return _TableScroll(
      child: DataTable(
        columns: [
          const DataColumn(label: Text('ID')),
          const DataColumn(label: Text('Группа')),
          const DataColumn(label: Text('Курс')),
          const DataColumn(label: Text('Учебный год')),
          const DataColumn(label: Text('Направление')),
          if (isAdmin) const DataColumn(label: Text('Действия')),
        ],
        rows: groups.map((group) {
          return DataRow(
            cells: [
              DataCell(Text(group.id.toString())),
              DataCell(Text(group.groupName)),
              DataCell(Text(group.course.toString())),
              DataCell(Text(group.studyYear)),
              DataCell(Text(group.directionName ?? '—')),
              if (isAdmin)
                DataCell(
                  _TableActions(
                    isBusy: isBusy,
                    onEdit: () => _openEditDialog(context, group),
                    onDelete: () => _openDeleteDialog(context, group),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _openEditDialog(
    BuildContext context,
    StudyGroup group,
  ) async {
    final result = await showDialog<_GroupFormData>(
      context: context,
      builder: (_) => _GroupFormDialog(group: group),
    );

    if (result == null || !context.mounted) {
      return;
    }

    context.read<EducationalDataBloc>().add(
          EducationalGroupUpdateRequested(
            id: group.id,
            groupName: result.groupName,
            course: result.course,
            studyYear: result.studyYear,
            directionName: result.directionName,
          ),
        );
  }

  Future<void> _openDeleteDialog(
    BuildContext context,
    StudyGroup group,
  ) async {
    final state = context.read<EducationalDataBloc>().state;
    final hasStudents = state.students.any(
      (student) => student.groupId == group.id,
    );

    if (hasStudents) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Нельзя удалить группу, пока к ней привязаны студенты.',
          ),
        ),
      );
      return;
    }

    final confirmed = await _showDeleteDialog(
      context: context,
      title: 'Удаление учебной группы',
      message: 'Вы действительно хотите удалить группу "${group.groupName}"?',
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    context.read<EducationalDataBloc>().add(
          EducationalGroupDeleteRequested(id: group.id),
        );
  }
}

class _DisciplinesTable extends StatelessWidget {
  final List<Discipline> disciplines;
  final bool isAdmin;
  final bool isBusy;

  const _DisciplinesTable({
    required this.disciplines,
    required this.isAdmin,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    if (disciplines.isEmpty) {
      return const _EmptyListMessage(text: 'Дисциплины пока отсутствуют.');
    }

    return _TableScroll(
      child: DataTable(
        columns: [
          const DataColumn(label: Text('ID')),
          const DataColumn(label: Text('Название')),
          const DataColumn(label: Text('Описание')),
          const DataColumn(label: Text('Преподаватель')),
          if (isAdmin) const DataColumn(label: Text('Действия')),
        ],
        rows: disciplines.map((discipline) {
          return DataRow(
            cells: [
              DataCell(Text(discipline.id.toString())),
              DataCell(Text(discipline.disciplineName)),
              DataCell(Text(discipline.description ?? '—')),
              DataCell(Text(discipline.teacherName ?? '—')),
              if (isAdmin)
                DataCell(
                  _TableActions(
                    isBusy: isBusy,
                    onEdit: () => _openEditDialog(context, discipline),
                    onDelete: () => _openDeleteDialog(context, discipline),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _openEditDialog(
    BuildContext context,
    Discipline discipline,
  ) async {
    final result = await showDialog<_DisciplineFormData>(
      context: context,
      builder: (_) => _DisciplineFormDialog(discipline: discipline),
    );

    if (result == null || !context.mounted) {
      return;
    }

    context.read<EducationalDataBloc>().add(
          EducationalDisciplineUpdateRequested(
            id: discipline.id,
            disciplineName: result.disciplineName,
            description: result.description,
            teacherName: result.teacherName,
          ),
        );
  }

  Future<void> _openDeleteDialog(
    BuildContext context,
    Discipline discipline,
  ) async {
    final state = context.read<EducationalDataBloc>().state;

    final hasGrades = state.grades.any(
      (grade) => grade.disciplineId == discipline.id,
    );

    final hasAttendance = state.attendance.any(
      (attendance) => attendance.disciplineId == discipline.id,
    );

    if (hasGrades || hasAttendance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Нельзя удалить дисциплину, пока к ней привязаны оценки или посещаемость.',
          ),
        ),
      );
      return;
    }

    final confirmed = await _showDeleteDialog(
      context: context,
      title: 'Удаление дисциплины',
      message:
          'Вы действительно хотите удалить дисциплину "${discipline.disciplineName}"?',
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    context.read<EducationalDataBloc>().add(
          EducationalDisciplineDeleteRequested(id: discipline.id),
        );
  }
}

class _PeriodsTable extends StatelessWidget {
  final List<StudyPeriod> periods;
  final bool isAdmin;
  final bool isBusy;

  const _PeriodsTable({
    required this.periods,
    required this.isAdmin,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) {
      return const _EmptyListMessage(text: 'Учебные периоды пока отсутствуют.');
    }

    return _TableScroll(
      child: DataTable(
        columns: [
          const DataColumn(label: Text('ID')),
          const DataColumn(label: Text('Учебный год')),
          const DataColumn(label: Text('Семестр')),
          const DataColumn(label: Text('Дата начала')),
          const DataColumn(label: Text('Дата окончания')),
          if (isAdmin) const DataColumn(label: Text('Действия')),
        ],
        rows: periods.map((period) {
          return DataRow(
            cells: [
              DataCell(Text(period.id.toString())),
              DataCell(Text(period.studyYear)),
              DataCell(Text(period.semester.toString())),
              DataCell(Text(period.startDate ?? '—')),
              DataCell(Text(period.endDate ?? '—')),
              if (isAdmin)
                DataCell(
                  _TableActions(
                    isBusy: isBusy,
                    onEdit: () => _openEditDialog(context, period),
                    onDelete: () => _openDeleteDialog(context, period),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _openEditDialog(
    BuildContext context,
    StudyPeriod period,
  ) async {
    final result = await showDialog<_PeriodFormData>(
      context: context,
      builder: (_) => _PeriodFormDialog(period: period),
    );

    if (result == null || !context.mounted) {
      return;
    }

    context.read<EducationalDataBloc>().add(
          EducationalPeriodUpdateRequested(
            id: period.id,
            studyYear: result.studyYear,
            semester: result.semester,
            startDate: result.startDate,
            endDate: result.endDate,
          ),
        );
  }

  Future<void> _openDeleteDialog(
    BuildContext context,
    StudyPeriod period,
  ) async {
    final state = context.read<EducationalDataBloc>().state;

    final hasGrades = state.grades.any(
      (grade) => grade.periodId == period.id,
    );

    final hasAttendance = state.attendance.any(
      (attendance) => attendance.periodId == period.id,
    );

    if (hasGrades || hasAttendance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Нельзя удалить период, пока к нему привязаны оценки или посещаемость.',
          ),
        ),
      );
      return;
    }

    final confirmed = await _showDeleteDialog(
      context: context,
      title: 'Удаление учебного периода',
      message: 'Вы действительно хотите удалить период "${period.title}"?',
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    context.read<EducationalDataBloc>().add(
          EducationalPeriodDeleteRequested(id: period.id),
        );
  }
}

class _StudentsTable extends StatelessWidget {
  final List<Student> students;
  final List<StudyGroup> groups;
  final bool isAdmin;
  final bool isBusy;

  const _StudentsTable({
    required this.students,
    required this.groups,
    required this.isAdmin,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const _EmptyListMessage(text: 'Студенты пока отсутствуют.');
    }

    return _TableScroll(
      child: DataTable(
        columns: [
          const DataColumn(label: Text('ID')),
          const DataColumn(label: Text('Фамилия')),
          const DataColumn(label: Text('Имя')),
          const DataColumn(label: Text('Отчество')),
          const DataColumn(label: Text('Зачетная книжка')),
          const DataColumn(label: Text('Группа')),
          if (isAdmin) const DataColumn(label: Text('Действия')),
        ],
        rows: students.map((student) {
          return DataRow(
            cells: [
              DataCell(Text(student.id.toString())),
              DataCell(Text(student.lastName)),
              DataCell(Text(student.firstName)),
              DataCell(Text(student.patronymic ?? '—')),
              DataCell(Text(student.recordBookNumber ?? '—')),
              DataCell(Text(student.groupName)),
              if (isAdmin)
                DataCell(
                  _TableActions(
                    isBusy: isBusy,
                    onEdit: () => _openEditDialog(context, student),
                    onDelete: () => _openDeleteDialog(context, student),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _openEditDialog(
    BuildContext context,
    Student student,
  ) async {
    final result = await showDialog<_StudentFormData>(
      context: context,
      builder: (_) => _StudentFormDialog(
        student: student,
        groups: groups,
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }

    context.read<EducationalDataBloc>().add(
          EducationalStudentUpdateRequested(
            id: student.id,
            lastName: result.lastName,
            firstName: result.firstName,
            patronymic: result.patronymic,
            recordBookNumber: result.recordBookNumber,
            groupId: result.groupId,
          ),
        );
  }

  Future<void> _openDeleteDialog(
    BuildContext context,
    Student student,
  ) async {
    final state = context.read<EducationalDataBloc>().state;

    final hasGrades = state.grades.any(
      (grade) => grade.studentId == student.id,
    );

    final hasAttendance = state.attendance.any(
      (attendance) => attendance.studentId == student.id,
    );

    if (hasGrades || hasAttendance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Нельзя удалить студента, пока к нему привязаны оценки или посещаемость.',
          ),
        ),
      );
      return;
    }

    final confirmed = await _showDeleteDialog(
      context: context,
      title: 'Удаление студента',
      message: 'Вы действительно хотите удалить студента "${student.fullName}"?',
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    context.read<EducationalDataBloc>().add(
          EducationalStudentDeleteRequested(id: student.id),
        );
  }
}

class _TableScroll extends StatelessWidget {
  final Widget child;

  const _TableScroll({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: child,
        ),
      ),
    );
  }
}

class _TableActions extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TableActions({
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Редактировать',
          onPressed: isBusy ? null : onEdit,
          icon: const Icon(Icons.edit_rounded),
        ),
        IconButton(
          tooltip: 'Удалить',
          onPressed: isBusy ? null : onDelete,
          icon: const Icon(Icons.delete_rounded),
        ),
      ],
    );
  }
}

class _EmptyListMessage extends StatelessWidget {
  final String text;

  const _EmptyListMessage({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}

Future<bool?> _showDeleteDialog({
  required BuildContext context,
  required String title,
  required String message,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
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
}

class _GroupFormDialog extends StatefulWidget {
  final StudyGroup? group;

  const _GroupFormDialog({
    this.group,
  });

  @override
  State<_GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<_GroupFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _groupNameController;
  late final TextEditingController _courseController;
  late final TextEditingController _studyYearController;
  late final TextEditingController _directionNameController;

  bool get _isEditMode => widget.group != null;

  @override
  void initState() {
    super.initState();

    final group = widget.group;

    _groupNameController = TextEditingController(
      text: group?.groupName ?? '',
    );
    _courseController = TextEditingController(
      text: group?.course.toString() ?? '',
    );
    _studyYearController = TextEditingController(
      text: group?.studyYear ?? '',
    );
    _directionNameController = TextEditingController(
      text: group?.directionName ?? '',
    );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _courseController.dispose();
    _studyYearController.dispose();
    _directionNameController.dispose();
    super.dispose();
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final course = int.tryParse(_courseController.text.trim());

    if (course == null) {
      return;
    }

    Navigator.of(context).pop(
      _GroupFormData(
        groupName: _groupNameController.text.trim(),
        course: course,
        studyYear: _studyYearController.text.trim(),
        directionName: _nullIfEmpty(_directionNameController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditMode ? 'Редактирование группы' : 'Добавление группы',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _groupNameController,
                  decoration: const InputDecoration(
                    labelText: 'Название группы',
                    hintText: 'Например: ИСП-31',
                  ),
                  validator: (value) => _requiredTextValidator(
                    value,
                    emptyMessage: 'Введите название группы',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _courseController,
                  decoration: const InputDecoration(
                    labelText: 'Курс',
                    hintText: 'Например: 3',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => _intRangeValidator(
                    value,
                    emptyMessage: 'Введите курс',
                    min: 1,
                    max: 6,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _studyYearController,
                  decoration: const InputDecoration(
                    labelText: 'Учебный год',
                    hintText: 'Например: 2025/2026',
                  ),
                  validator: (value) => _requiredTextValidator(
                    value,
                    emptyMessage: 'Введите учебный год',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _directionNameController,
                  decoration: const InputDecoration(
                    labelText: 'Направление подготовки',
                    hintText: 'Необязательное поле',
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

class _GroupFormData {
  final String groupName;
  final int course;
  final String studyYear;
  final String? directionName;

  const _GroupFormData({
    required this.groupName,
    required this.course,
    required this.studyYear,
    required this.directionName,
  });
}

class _DisciplineFormDialog extends StatefulWidget {
  final Discipline? discipline;

  const _DisciplineFormDialog({
    this.discipline,
  });

  @override
  State<_DisciplineFormDialog> createState() => _DisciplineFormDialogState();
}

class _DisciplineFormDialogState extends State<_DisciplineFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _disciplineNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _teacherNameController;

  bool get _isEditMode => widget.discipline != null;

  @override
  void initState() {
    super.initState();

    final discipline = widget.discipline;

    _disciplineNameController = TextEditingController(
      text: discipline?.disciplineName ?? '',
    );
    _descriptionController = TextEditingController(
      text: discipline?.description ?? '',
    );
    _teacherNameController = TextEditingController(
      text: discipline?.teacherName ?? '',
    );
  }

  @override
  void dispose() {
    _disciplineNameController.dispose();
    _descriptionController.dispose();
    _teacherNameController.dispose();
    super.dispose();
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    Navigator.of(context).pop(
      _DisciplineFormData(
        disciplineName: _disciplineNameController.text.trim(),
        description: _nullIfEmpty(_descriptionController.text),
        teacherName: _nullIfEmpty(_teacherNameController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditMode
            ? 'Редактирование дисциплины'
            : 'Добавление дисциплины',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _disciplineNameController,
                  decoration: const InputDecoration(
                    labelText: 'Название дисциплины',
                    hintText: 'Например: Математика',
                  ),
                  validator: (value) => _requiredTextValidator(
                    value,
                    emptyMessage: 'Введите название дисциплины',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    hintText: 'Необязательное поле',
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _teacherNameController,
                  decoration: const InputDecoration(
                    labelText: 'Преподаватель',
                    hintText: 'Необязательное поле',
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

class _DisciplineFormData {
  final String disciplineName;
  final String? description;
  final String? teacherName;

  const _DisciplineFormData({
    required this.disciplineName,
    required this.description,
    required this.teacherName,
  });
}

class _PeriodFormDialog extends StatefulWidget {
  final StudyPeriod? period;

  const _PeriodFormDialog({
    this.period,
  });

  @override
  State<_PeriodFormDialog> createState() => _PeriodFormDialogState();
}

class _PeriodFormDialogState extends State<_PeriodFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _studyYearController;
  late final TextEditingController _semesterController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;

  bool get _isEditMode => widget.period != null;

  @override
  void initState() {
    super.initState();

    final period = widget.period;

    _studyYearController = TextEditingController(
      text: period?.studyYear ?? '',
    );
    _semesterController = TextEditingController(
      text: period?.semester.toString() ?? '',
    );
    _startDateController = TextEditingController(
      text: period?.startDate ?? '',
    );
    _endDateController = TextEditingController(
      text: period?.endDate ?? '',
    );
  }

  @override
  void dispose() {
    _studyYearController.dispose();
    _semesterController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final semester = int.tryParse(_semesterController.text.trim());

    if (semester == null) {
      return;
    }

    Navigator.of(context).pop(
      _PeriodFormData(
        studyYear: _studyYearController.text.trim(),
        semester: semester,
        startDate: _startDateController.text.trim(),
        endDate: _endDateController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditMode
            ? 'Редактирование учебного периода'
            : 'Добавление учебного периода',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _studyYearController,
                  decoration: const InputDecoration(
                    labelText: 'Учебный год',
                    hintText: 'Например: 2025/2026',
                  ),
                  validator: (value) => _requiredTextValidator(
                    value,
                    emptyMessage: 'Введите учебный год',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _semesterController,
                  decoration: const InputDecoration(
                    labelText: 'Семестр',
                    hintText: 'Например: 1',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => _intRangeValidator(
                    value,
                    emptyMessage: 'Введите номер семестра',
                    min: 1,
                    max: 12,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _startDateController,
                  decoration: const InputDecoration(
                    labelText: 'Дата начала',
                    hintText: 'Например: 2025-09-01',
                  ),
                  validator: (value) => _requiredTextValidator(
                    value,
                    emptyMessage: 'Введите дату начала',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _endDateController,
                  decoration: const InputDecoration(
                    labelText: 'Дата окончания',
                    hintText: 'Например: 2026-01-31',
                  ),
                  validator: (value) => _requiredTextValidator(
                    value,
                    emptyMessage: 'Введите дату окончания',
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

class _PeriodFormData {
  final String studyYear;
  final int semester;
  final String startDate;
  final String endDate;

  const _PeriodFormData({
    required this.studyYear,
    required this.semester,
    required this.startDate,
    required this.endDate,
  });
}

class _StudentFormDialog extends StatefulWidget {
  final Student? student;
  final List<StudyGroup> groups;

  const _StudentFormDialog({
    this.student,
    required this.groups,
  });

  @override
  State<_StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<_StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _lastNameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _patronymicController;
  late final TextEditingController _recordBookNumberController;

  int? _selectedGroupId;

  bool get _isEditMode => widget.student != null;

  @override
  void initState() {
    super.initState();

    final student = widget.student;

    _lastNameController = TextEditingController(
      text: student?.lastName ?? '',
    );
    _firstNameController = TextEditingController(
      text: student?.firstName ?? '',
    );
    _patronymicController = TextEditingController(
      text: student?.patronymic ?? '',
    );
    _recordBookNumberController = TextEditingController(
      text: student?.recordBookNumber ?? '',
    );

    _selectedGroupId = _hasGroup(student?.groupId) ? student?.groupId : null;
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _patronymicController.dispose();
    _recordBookNumberController.dispose();
    super.dispose();
  }

  bool _hasGroup(int? id) {
    if (id == null) {
      return false;
    }

    return widget.groups.any((group) => group.id == id);
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final groupId = _selectedGroupId;

    if (groupId == null) {
      return;
    }

    Navigator.of(context).pop(
      _StudentFormData(
        lastName: _lastNameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        patronymic: _nullIfEmpty(_patronymicController.text),
        recordBookNumber: _nullIfEmpty(_recordBookNumberController.text),
        groupId: groupId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditMode ? 'Редактирование студента' : 'Добавление студента',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Фамилия',
                    hintText: 'Например: Иванов',
                  ),
                  validator: (value) => _requiredTextValidator(
                    value,
                    emptyMessage: 'Введите фамилию',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя',
                    hintText: 'Например: Иван',
                  ),
                  validator: (value) => _requiredTextValidator(
                    value,
                    emptyMessage: 'Введите имя',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _patronymicController,
                  decoration: const InputDecoration(
                    labelText: 'Отчество',
                    hintText: 'Необязательное поле',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _recordBookNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Номер зачетной книжки',
                    hintText: 'Необязательное поле',
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: _selectedGroupId,
                  decoration: const InputDecoration(
                    labelText: 'Учебная группа',
                  ),
                  items: widget.groups.map((group) {
                    return DropdownMenuItem<int>(
                      value: group.id,
                      child: Text(group.groupName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGroupId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Выберите учебную группу';
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

class _StudentFormData {
  final String lastName;
  final String firstName;
  final String? patronymic;
  final String? recordBookNumber;
  final int groupId;

  const _StudentFormData({
    required this.lastName,
    required this.firstName,
    required this.patronymic,
    required this.recordBookNumber,
    required this.groupId,
  });
}

String? _requiredTextValidator(
  String? value, {
  required String emptyMessage,
}) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) {
    return emptyMessage;
  }

  if (text.length > 150) {
    return 'Значение слишком длинное';
  }

  return null;
}

String? _intRangeValidator(
  String? value, {
  required String emptyMessage,
  required int min,
  required int max,
}) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) {
    return emptyMessage;
  }

  final number = int.tryParse(text);

  if (number == null) {
    return 'Введите целое число';
  }

  if (number < min || number > max) {
    return 'Введите значение от $min до $max';
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