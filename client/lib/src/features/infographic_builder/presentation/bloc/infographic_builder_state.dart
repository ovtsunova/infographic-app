part of 'infographic_builder_bloc.dart';

enum InfographicBuilderStatus {
  initial,
  loading,
  ready,
  failure,
}

enum InfographicChartType {
  gradeDistribution,
  averageGradeByGroup,
  attendanceByGroup,
}

extension InfographicChartTypeTitle on InfographicChartType {
  String get title {
    switch (this) {
      case InfographicChartType.gradeDistribution:
        return 'Распределение оценок';

      case InfographicChartType.averageGradeByGroup:
        return 'Средний балл по группам';

      case InfographicChartType.attendanceByGroup:
        return 'Посещаемость по группам';
    }
  }
}

enum InfographicVisualType {
  bar,
  line,
  pie,
}

extension InfographicVisualTypeInfo on InfographicVisualType {
  String get title {
    switch (this) {
      case InfographicVisualType.bar:
        return 'Столбчатая';

      case InfographicVisualType.line:
        return 'Линейная';

      case InfographicVisualType.pie:
        return 'Круговая';
    }
  }

  String get apiValue {
    switch (this) {
      case InfographicVisualType.bar:
        return 'bar';

      case InfographicVisualType.line:
        return 'line';

      case InfographicVisualType.pie:
        return 'pie';
    }
  }

  IconData get icon {
    switch (this) {
      case InfographicVisualType.bar:
        return Icons.bar_chart_rounded;

      case InfographicVisualType.line:
        return Icons.show_chart_rounded;

      case InfographicVisualType.pie:
        return Icons.pie_chart_rounded;
    }
  }
}

class InfographicBuilderState extends Equatable {
  final InfographicBuilderStatus status;

  final List<StudyGroup> groups;
  final List<Discipline> disciplines;
  final List<StudyPeriod> periods;
  final List<Student> students;
  final List<GradeRecord> grades;
  final List<AttendanceRecord> attendance;

  final int? selectedGroupId;
  final int? selectedDisciplineId;
  final int? selectedPeriodId;

  final InfographicChartType chartType;
  final InfographicVisualType visualType;

  final InfographicResult? result;
  final String? message;
  final bool isSaving;

  const InfographicBuilderState({
    required this.status,
    required this.groups,
    required this.disciplines,
    required this.periods,
    required this.students,
    required this.grades,
    required this.attendance,
    required this.selectedGroupId,
    required this.selectedDisciplineId,
    required this.selectedPeriodId,
    required this.chartType,
    required this.visualType,
    required this.result,
    required this.message,
    required this.isSaving,
  });

  const InfographicBuilderState.initial()
      : status = InfographicBuilderStatus.initial,
        groups = const [],
        disciplines = const [],
        periods = const [],
        students = const [],
        grades = const [],
        attendance = const [],
        selectedGroupId = null,
        selectedDisciplineId = null,
        selectedPeriodId = null,
        chartType = InfographicChartType.gradeDistribution,
        visualType = InfographicVisualType.bar,
        result = null,
        message = null,
        isSaving = false;

  bool get isLoading => status == InfographicBuilderStatus.loading;

  bool get hasRequiredData {
    return students.isNotEmpty &&
        disciplines.isNotEmpty &&
        periods.isNotEmpty &&
        (grades.isNotEmpty || attendance.isNotEmpty);
  }

  InfographicBuilderState copyWith({
    InfographicBuilderStatus? status,
    List<StudyGroup>? groups,
    List<Discipline>? disciplines,
    List<StudyPeriod>? periods,
    List<Student>? students,
    List<GradeRecord>? grades,
    List<AttendanceRecord>? attendance,
    int? selectedGroupId,
    bool updateSelectedGroupId = false,
    int? selectedDisciplineId,
    bool updateSelectedDisciplineId = false,
    int? selectedPeriodId,
    bool updateSelectedPeriodId = false,
    InfographicChartType? chartType,
    InfographicVisualType? visualType,
    InfographicResult? result,
    bool updateResult = false,
    bool clearResult = false,
    String? message,
    bool clearMessage = false,
    bool? isSaving,
  }) {
    return InfographicBuilderState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      disciplines: disciplines ?? this.disciplines,
      periods: periods ?? this.periods,
      students: students ?? this.students,
      grades: grades ?? this.grades,
      attendance: attendance ?? this.attendance,
      selectedGroupId:
          updateSelectedGroupId ? selectedGroupId : this.selectedGroupId,
      selectedDisciplineId: updateSelectedDisciplineId
          ? selectedDisciplineId
          : this.selectedDisciplineId,
      selectedPeriodId:
          updateSelectedPeriodId ? selectedPeriodId : this.selectedPeriodId,
      chartType: chartType ?? this.chartType,
      visualType: visualType ?? this.visualType,
      result: clearResult
          ? null
          : updateResult
              ? result
              : this.result,
      message: clearMessage ? null : message ?? this.message,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [
        status,
        groups,
        disciplines,
        periods,
        students,
        grades,
        attendance,
        selectedGroupId,
        selectedDisciplineId,
        selectedPeriodId,
        chartType,
        visualType,
        result,
        message,
        isSaving,
      ];
}

class InfographicResult extends Equatable {
  final String title;
  final String subtitle;
  final InfographicChartType chartType;
  final InfographicVisualType visualType;
  final List<InfographicSummaryMetric> cards;
  final List<InfographicChartItem> chartItems;
  final bool hasSourceData;

  const InfographicResult({
    required this.title,
    required this.subtitle,
    required this.chartType,
    required this.visualType,
    required this.cards,
    required this.chartItems,
    required this.hasSourceData,
  });

  bool get hasChartData {
    return chartItems.any((item) => item.value > 0);
  }

  @override
  List<Object?> get props => [
        title,
        subtitle,
        chartType,
        visualType,
        cards,
        chartItems,
        hasSourceData,
      ];
}

class InfographicSummaryMetric extends Equatable {
  final String title;
  final String value;

  const InfographicSummaryMetric({
    required this.title,
    required this.value,
  });

  @override
  List<Object?> get props => [
        title,
        value,
      ];
}

class InfographicChartItem extends Equatable {
  final String label;
  final double value;

  const InfographicChartItem({
    required this.label,
    required this.value,
  });

  @override
  List<Object?> get props => [
        label,
        value,
      ];
}