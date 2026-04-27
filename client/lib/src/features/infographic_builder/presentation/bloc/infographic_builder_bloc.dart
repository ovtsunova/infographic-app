import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:client/src/features/educational_data/data/educational_data_models.dart';
import 'package:client/src/features/educational_data/data/educational_data_repository.dart';
import 'package:client/src/features/saved_infographics/data/saved_infographics_repository.dart';

part 'infographic_builder_event.dart';
part 'infographic_builder_state.dart';

class InfographicBuilderBloc
    extends Bloc<InfographicBuilderEvent, InfographicBuilderState> {
  final EducationalDataRepository _educationalDataRepository;
  final SavedInfographicsRepository _savedInfographicsRepository;

  InfographicBuilderBloc({
    required EducationalDataRepository educationalDataRepository,
    required SavedInfographicsRepository savedInfographicsRepository,
  })  : _educationalDataRepository = educationalDataRepository,
        _savedInfographicsRepository = savedInfographicsRepository,
        super(const InfographicBuilderState.initial()) {
    on<InfographicBuilderStarted>(_onStarted);
    on<InfographicBuilderRefreshRequested>(_onRefreshRequested);
    on<InfographicGroupChanged>(_onGroupChanged);
    on<InfographicDisciplineChanged>(_onDisciplineChanged);
    on<InfographicPeriodChanged>(_onPeriodChanged);
    on<InfographicChartTypeChanged>(_onChartTypeChanged);
    on<InfographicVisualTypeChanged>(_onVisualTypeChanged);
    on<InfographicGenerateRequested>(_onGenerateRequested);
    on<InfographicSaveRequested>(_onSaveRequested);
  }

  Future<void> _onStarted(
    InfographicBuilderStarted event,
    Emitter<InfographicBuilderState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _onRefreshRequested(
    InfographicBuilderRefreshRequested event,
    Emitter<InfographicBuilderState> emit,
  ) async {
    await _loadData(emit);
  }

  void _onGroupChanged(
    InfographicGroupChanged event,
    Emitter<InfographicBuilderState> emit,
  ) {
    emit(
      state.copyWith(
        selectedGroupId: event.groupId,
        updateSelectedGroupId: true,
        clearResult: true,
        clearMessage: true,
      ),
    );
  }

  void _onDisciplineChanged(
    InfographicDisciplineChanged event,
    Emitter<InfographicBuilderState> emit,
  ) {
    emit(
      state.copyWith(
        selectedDisciplineId: event.disciplineId,
        updateSelectedDisciplineId: true,
        clearResult: true,
        clearMessage: true,
      ),
    );
  }

  void _onPeriodChanged(
    InfographicPeriodChanged event,
    Emitter<InfographicBuilderState> emit,
  ) {
    emit(
      state.copyWith(
        selectedPeriodId: event.periodId,
        updateSelectedPeriodId: true,
        clearResult: true,
        clearMessage: true,
      ),
    );
  }

  void _onChartTypeChanged(
    InfographicChartTypeChanged event,
    Emitter<InfographicBuilderState> emit,
  ) {
    emit(
      state.copyWith(
        chartType: event.chartType,
        clearResult: true,
        clearMessage: true,
      ),
    );
  }

  void _onVisualTypeChanged(
    InfographicVisualTypeChanged event,
    Emitter<InfographicBuilderState> emit,
  ) {
    emit(
      state.copyWith(
        visualType: event.visualType,
        clearResult: true,
        clearMessage: true,
      ),
    );
  }

  void _onGenerateRequested(
    InfographicGenerateRequested event,
    Emitter<InfographicBuilderState> emit,
  ) {
    final result = _buildResult(state);

    emit(
      state.copyWith(
        status: InfographicBuilderStatus.ready,
        result: result,
        updateResult: true,
        message: result.hasSourceData
            ? 'Инфографика успешно сформирована'
            : 'По выбранным параметрам нет данных для построения',
      ),
    );
  }

  Future<void> _onSaveRequested(
    InfographicSaveRequested event,
    Emitter<InfographicBuilderState> emit,
  ) async {
    final result = state.result;

    if (result == null) {
      emit(
        state.copyWith(
          message: 'Сначала сформируйте инфографику',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSaving: true,
        clearMessage: true,
      ),
    );

    try {
      await _savedInfographicsRepository.saveInfographic(
        title: event.title,
        chartType: state.visualType.apiValue,
        parameters: {
          'groupId': state.selectedGroupId,
          'disciplineId': state.selectedDisciplineId,
          'periodId': state.selectedPeriodId,
          'chartType': state.chartType.name,
          'visualType': state.visualType.name,
        },
        resultData: {
          'title': result.title,
          'subtitle': result.subtitle,
          'visualType': result.visualType.name,
          'cards': result.cards.map((card) {
            return {
              'title': card.title,
              'value': card.value,
            };
          }).toList(),
          'chartItems': result.chartItems.map((item) {
            return {
              'label': item.label,
              'value': item.value,
            };
          }).toList(),
        },
      );

      emit(
        state.copyWith(
          isSaving: false,
          message: 'Инфографика успешно сохранена',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isSaving: false,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> _loadData(
    Emitter<InfographicBuilderState> emit,
  ) async {
    emit(
      state.copyWith(
        status: InfographicBuilderStatus.loading,
        clearMessage: true,
        clearResult: true,
      ),
    );

    try {
      final data = await _educationalDataRepository.loadAll();

      emit(
        state.copyWith(
          status: InfographicBuilderStatus.ready,
          groups: data.groups,
          disciplines: data.disciplines,
          periods: data.periods,
          students: data.students,
          grades: data.grades,
          attendance: data.attendance,
          clearMessage: true,
          clearResult: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: InfographicBuilderStatus.failure,
          message: error.toString(),
          clearResult: true,
        ),
      );
    }
  }

  InfographicResult _buildResult(
    InfographicBuilderState state,
  ) {
    final filteredGrades = _filteredGrades(state);
    final filteredAttendance = _filteredAttendance(state);

    final averageGrade = _averageGrade(filteredGrades);
    final successRate = _successRate(filteredGrades);
    final averageAttendance = _averageAttendance(filteredAttendance);

    final debtorCount = filteredGrades
        .where((grade) => grade.gradeValue <= 2)
        .map((grade) => grade.studentId)
        .toSet()
        .length;

    final excellentGradeCount = filteredGrades
        .where((grade) => grade.gradeValue == 5)
        .length;

    final cards = [
      InfographicSummaryMetric(
        title: 'Средний балл',
        value: filteredGrades.isEmpty ? '—' : averageGrade.toStringAsFixed(2),
      ),
      InfographicSummaryMetric(
        title: 'Успеваемость',
        value: filteredGrades.isEmpty
            ? '—'
            : '${successRate.toStringAsFixed(1)}%',
      ),
      InfographicSummaryMetric(
        title: 'Средняя посещаемость',
        value: filteredAttendance.isEmpty
            ? '—'
            : '${averageAttendance.toStringAsFixed(1)}%',
      ),
      InfographicSummaryMetric(
        title: 'Задолженности',
        value: debtorCount.toString(),
      ),
      InfographicSummaryMetric(
        title: 'Оценок «5»',
        value: excellentGradeCount.toString(),
      ),
      InfographicSummaryMetric(
        title: 'Записей посещаемости',
        value: filteredAttendance.length.toString(),
      ),
    ];

    final chartItems = _buildChartItems(
      state: state,
      filteredGrades: filteredGrades,
      filteredAttendance: filteredAttendance,
    );

    return InfographicResult(
      title: state.chartType.title,
      subtitle: _buildSubtitle(state),
      chartType: state.chartType,
      visualType: state.visualType,
      cards: cards,
      chartItems: chartItems,
      hasSourceData: filteredGrades.isNotEmpty || filteredAttendance.isNotEmpty,
    );
  }

  List<GradeRecord> _filteredGrades(
    InfographicBuilderState state,
  ) {
    final studentIds = _filteredStudents(state)
        .map((student) => student.id)
        .toSet();

    return state.grades.where((grade) {
      if (!studentIds.contains(grade.studentId)) {
        return false;
      }

      if (state.selectedDisciplineId != null &&
          grade.disciplineId != state.selectedDisciplineId) {
        return false;
      }

      if (state.selectedPeriodId != null &&
          grade.periodId != state.selectedPeriodId) {
        return false;
      }

      return true;
    }).toList();
  }

  List<AttendanceRecord> _filteredAttendance(
    InfographicBuilderState state,
  ) {
    final studentIds = _filteredStudents(state)
        .map((student) => student.id)
        .toSet();

    return state.attendance.where((record) {
      if (!studentIds.contains(record.studentId)) {
        return false;
      }

      if (state.selectedDisciplineId != null &&
          record.disciplineId != state.selectedDisciplineId) {
        return false;
      }

      if (state.selectedPeriodId != null &&
          record.periodId != state.selectedPeriodId) {
        return false;
      }

      return true;
    }).toList();
  }

  List<Student> _filteredStudents(
    InfographicBuilderState state,
  ) {
    if (state.selectedGroupId == null) {
      return state.students;
    }

    return state.students
        .where((student) => student.groupId == state.selectedGroupId)
        .toList();
  }

  List<InfographicChartItem> _buildChartItems({
    required InfographicBuilderState state,
    required List<GradeRecord> filteredGrades,
    required List<AttendanceRecord> filteredAttendance,
  }) {
    switch (state.chartType) {
      case InfographicChartType.gradeDistribution:
        return _buildGradeDistribution(filteredGrades);

      case InfographicChartType.averageGradeByGroup:
        return _buildAverageGradeByGroup(state);

      case InfographicChartType.attendanceByGroup:
        return _buildAttendanceByGroup(state);
    }
  }

  List<InfographicChartItem> _buildGradeDistribution(
    List<GradeRecord> grades,
  ) {
    final counts = <int, int>{
      2: 0,
      3: 0,
      4: 0,
      5: 0,
    };

    for (final grade in grades) {
      if (counts.containsKey(grade.gradeValue)) {
        counts[grade.gradeValue] = counts[grade.gradeValue]! + 1;
      }
    }

    return counts.entries.map((entry) {
      return InfographicChartItem(
        label: entry.key.toString(),
        value: entry.value.toDouble(),
      );
    }).toList();
  }

  List<InfographicChartItem> _buildAverageGradeByGroup(
    InfographicBuilderState state,
  ) {
    final groups = _visibleGroups(state);

    return groups.map((group) {
      final studentIds = state.students
          .where((student) => student.groupId == group.id)
          .map((student) => student.id)
          .toSet();

      final grades = state.grades.where((grade) {
        if (!studentIds.contains(grade.studentId)) {
          return false;
        }

        if (state.selectedDisciplineId != null &&
            grade.disciplineId != state.selectedDisciplineId) {
          return false;
        }

        if (state.selectedPeriodId != null &&
            grade.periodId != state.selectedPeriodId) {
          return false;
        }

        return true;
      }).toList();

      return InfographicChartItem(
        label: group.groupName,
        value: _averageGrade(grades),
      );
    }).toList();
  }

  List<InfographicChartItem> _buildAttendanceByGroup(
    InfographicBuilderState state,
  ) {
    final groups = _visibleGroups(state);

    return groups.map((group) {
      final studentIds = state.students
          .where((student) => student.groupId == group.id)
          .map((student) => student.id)
          .toSet();

      final attendance = state.attendance.where((record) {
        if (!studentIds.contains(record.studentId)) {
          return false;
        }

        if (state.selectedDisciplineId != null &&
            record.disciplineId != state.selectedDisciplineId) {
          return false;
        }

        if (state.selectedPeriodId != null &&
            record.periodId != state.selectedPeriodId) {
          return false;
        }

        return true;
      }).toList();

      return InfographicChartItem(
        label: group.groupName,
        value: _averageAttendance(attendance),
      );
    }).toList();
  }

  List<StudyGroup> _visibleGroups(
    InfographicBuilderState state,
  ) {
    if (state.selectedGroupId == null) {
      return state.groups;
    }

    return state.groups
        .where((group) => group.id == state.selectedGroupId)
        .toList();
  }

  double _averageGrade(
    List<GradeRecord> grades,
  ) {
    if (grades.isEmpty) {
      return 0;
    }

    final sum = grades.fold<int>(
      0,
      (previousValue, grade) => previousValue + grade.gradeValue,
    );

    return sum / grades.length;
  }

  double _successRate(
    List<GradeRecord> grades,
  ) {
    if (grades.isEmpty) {
      return 0;
    }

    final successfulCount = grades
        .where((grade) => grade.gradeValue >= 3)
        .length;

    return successfulCount / grades.length * 100;
  }

  double _averageAttendance(
    List<AttendanceRecord> attendance,
  ) {
    if (attendance.isEmpty) {
      return 0;
    }

    final sum = attendance.fold<double>(
      0,
      (previousValue, record) => previousValue + record.attendanceRate,
    );

    return sum / attendance.length;
  }

  String _buildSubtitle(
    InfographicBuilderState state,
  ) {
    final parts = <String>[];

    final group = _findGroup(state);
    final discipline = _findDiscipline(state);
    final period = _findPeriod(state);

    parts.add(group?.groupName ?? 'Все группы');
    parts.add(discipline?.disciplineName ?? 'Все дисциплины');
    parts.add(period?.title ?? 'Все периоды');

    return parts.join(' • ');
  }

  StudyGroup? _findGroup(
    InfographicBuilderState state,
  ) {
    for (final group in state.groups) {
      if (group.id == state.selectedGroupId) {
        return group;
      }
    }

    return null;
  }

  Discipline? _findDiscipline(
    InfographicBuilderState state,
  ) {
    for (final discipline in state.disciplines) {
      if (discipline.id == state.selectedDisciplineId) {
        return discipline;
      }
    }

    return null;
  }

  StudyPeriod? _findPeriod(
    InfographicBuilderState state,
  ) {
    for (final period in state.periods) {
      if (period.id == state.selectedPeriodId) {
        return period;
      }
    }

    return null;
  }
}