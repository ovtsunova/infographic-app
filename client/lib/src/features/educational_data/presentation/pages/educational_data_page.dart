import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:client/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client/src/features/educational_data/data/educational_data_models.dart';
import 'package:client/src/features/educational_data/data/educational_data_repository.dart';
import 'package:client/src/features/educational_data/presentation/bloc/educational_data_bloc.dart';
import 'package:client/src/shared/models/app_user.dart';

class EducationalDataPage extends StatelessWidget {
  const EducationalDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EducationalDataBloc>(
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
                    if (isAdmin) ...[
                      ElevatedButton.icon(
                        onPressed: state.isBusy
                            ? null
                            : () => _openGroupCreateDialog(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Добавить группу'),
                      ),
                      const SizedBox(width: 12),
                    ],
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
                  'Раздел предназначен для просмотра учебных групп, дисциплин, учебных периодов и студентов. Администратор может добавлять, редактировать и удалять учебные группы.',
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

  Future<void> _openGroupCreateDialog(BuildContext context) async {
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
          crossAxisCount: MediaQuery.of(context).size.width > 1100 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.9,
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
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: DefaultTabController(
              length: 4,
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
                        _DisciplinesTable(disciplines: state.disciplines),
                        _PeriodsTable(periods: state.periods),
                        _StudentsTable(students: state.students),
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
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 34,
            ),
            const SizedBox(width: 14),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Редактировать',
                        onPressed:
                            isBusy ? null : () => _openEditDialog(context, group),
                        icon: const Icon(Icons.edit_rounded),
                      ),
                      IconButton(
                        tooltip: 'Удалить',
                        onPressed: isBusy
                            ? null
                            : () => _openDeleteDialog(context, group),
                        icon: const Icon(Icons.delete_rounded),
                      ),
                    ],
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удаление учебной группы'),
        content: Text(
          'Вы действительно хотите удалить группу "${group.groupName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
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

  const _DisciplinesTable({
    required this.disciplines,
  });

  @override
  Widget build(BuildContext context) {
    if (disciplines.isEmpty) {
      return const _EmptyListMessage(text: 'Дисциплины пока отсутствуют.');
    }

    return _TableScroll(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Дисциплина')),
          DataColumn(label: Text('Преподаватель')),
          DataColumn(label: Text('Описание')),
        ],
        rows: disciplines.map((discipline) {
          return DataRow(
            cells: [
              DataCell(Text(discipline.id.toString())),
              DataCell(Text(discipline.disciplineName)),
              DataCell(Text(discipline.teacherName ?? '—')),
              DataCell(Text(discipline.description ?? '—')),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _PeriodsTable extends StatelessWidget {
  final List<StudyPeriod> periods;

  const _PeriodsTable({
    required this.periods,
  });

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) {
      return const _EmptyListMessage(text: 'Учебные периоды пока отсутствуют.');
    }

    return _TableScroll(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Учебный год')),
          DataColumn(label: Text('Семестр')),
          DataColumn(label: Text('Дата начала')),
          DataColumn(label: Text('Дата окончания')),
        ],
        rows: periods.map((period) {
          return DataRow(
            cells: [
              DataCell(Text(period.id.toString())),
              DataCell(Text(period.studyYear)),
              DataCell(Text(period.semester.toString())),
              DataCell(Text(period.startDate ?? '—')),
              DataCell(Text(period.endDate ?? '—')),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _StudentsTable extends StatelessWidget {
  final List<Student> students;

  const _StudentsTable({
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const _EmptyListMessage(text: 'Студенты пока отсутствуют.');
    }

    return _TableScroll(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('ФИО')),
          DataColumn(label: Text('Группа')),
          DataColumn(label: Text('Зачётная книжка')),
        ],
        rows: students.map((student) {
          return DataRow(
            cells: [
              DataCell(Text(student.id.toString())),
              DataCell(Text(student.fullName)),
              DataCell(Text(student.groupName)),
              DataCell(Text(student.recordBookNumber ?? '—')),
            ],
          );
        }).toList(),
      ),
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

    final course = int.parse(_courseController.text.trim());

    Navigator.of(context).pop(
      _GroupFormData(
        groupName: _groupNameController.text.trim(),
        course: course,
        studyYear: _studyYearController.text.trim(),
        directionName: _directionNameController.text.trim().isEmpty
            ? null
            : _directionNameController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditMode ? 'Редактирование группы' : 'Добавление группы',
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 460,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Название группы',
                  hintText: 'Например: ИСП-31',
                ),
                maxLength: 40,
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return 'Введите название учебной группы';
                  }

                  if (text.length > 40) {
                    return 'Название не должно превышать 40 символов';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _courseController,
                decoration: const InputDecoration(
                  labelText: 'Курс',
                  hintText: 'Например: 3',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final course = int.tryParse(value?.trim() ?? '');

                  if (course == null) {
                    return 'Введите курс числом';
                  }

                  if (course < 1 || course > 6) {
                    return 'Курс должен быть от 1 до 6';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _studyYearController,
                decoration: const InputDecoration(
                  labelText: 'Учебный год',
                  hintText: 'Например: 2025/2026',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  final pattern = RegExp(r'^\d{4}/\d{4}$');

                  if (text.isEmpty) {
                    return 'Введите учебный год';
                  }

                  if (!pattern.hasMatch(text)) {
                    return 'Формат учебного года: 2025/2026';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _directionNameController,
                decoration: const InputDecoration(
                  labelText: 'Направление подготовки',
                  hintText: 'Можно оставить пустым',
                ),
                maxLength: 120,
              ),
            ],
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
          child: Text(
            _isEditMode ? 'Сохранить' : 'Добавить',
          ),
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