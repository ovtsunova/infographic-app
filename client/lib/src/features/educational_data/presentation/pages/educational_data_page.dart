import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:client/src/features/educational_data/data/educational_data_models.dart';
import 'package:client/src/features/educational_data/data/educational_data_repository.dart';
import 'package:client/src/features/educational_data/presentation/bloc/educational_data_bloc.dart';

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
    return BlocBuilder<EducationalDataBloc, EducationalDataState>(
      builder: (context, state) {
        return ListView(
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
                OutlinedButton.icon(
                  onPressed: state.status == EducationalDataStatus.loading
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
              'Раздел предназначен для просмотра учебных групп, дисциплин, учебных периодов и студентов, полученных с серверной части приложения.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (state.status == EducationalDataStatus.loading)
              const _LoadingCard()
            else if (state.status == EducationalDataStatus.failure)
              _ErrorCard(message: state.message ?? 'Ошибка загрузки данных')
            else
              _LoadedContent(state: state),
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

  const _LoadedContent({
    required this.state,
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
                        _GroupsTable(groups: state.groups),
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

  const _GroupsTable({
    required this.groups,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const _EmptyListMessage(text: 'Учебные группы пока отсутствуют.');
    }

    return _TableScroll(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Группа')),
          DataColumn(label: Text('Курс')),
          DataColumn(label: Text('Учебный год')),
          DataColumn(label: Text('Направление')),
        ],
        rows: groups.map((group) {
          return DataRow(
            cells: [
              DataCell(Text(group.id.toString())),
              DataCell(Text(group.groupName)),
              DataCell(Text(group.course.toString())),
              DataCell(Text(group.studyYear)),
              DataCell(Text(group.directionName ?? '—')),
            ],
          );
        }).toList(),
      ),
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