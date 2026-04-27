part of 'educational_data_bloc.dart';

enum EducationalDataStatus {
  initial,
  loading,
  submitting,
  success,
  failure,
}

class EducationalDataState extends Equatable {
  final EducationalDataStatus status;
  final List<StudyGroup> groups;
  final List<Discipline> disciplines;
  final List<StudyPeriod> periods;
  final List<Student> students;
  final List<GradeRecord> grades;
  final String? message;

  const EducationalDataState({
    required this.status,
    required this.groups,
    required this.disciplines,
    required this.periods,
    required this.students,
    required this.grades,
    this.message,
  });

  const EducationalDataState.initial()
      : status = EducationalDataStatus.initial,
        groups = const [],
        disciplines = const [],
        periods = const [],
        students = const [],
        grades = const [],
        message = null;

  bool get isBusy {
    return status == EducationalDataStatus.loading ||
        status == EducationalDataStatus.submitting;
  }

  bool get hasAnyData {
    return groups.isNotEmpty ||
        disciplines.isNotEmpty ||
        periods.isNotEmpty ||
        students.isNotEmpty ||
        grades.isNotEmpty;
  }

  EducationalDataState copyWith({
    EducationalDataStatus? status,
    List<StudyGroup>? groups,
    List<Discipline>? disciplines,
    List<StudyPeriod>? periods,
    List<Student>? students,
    List<GradeRecord>? grades,
    String? message,
    bool clearMessage = false,
  }) {
    return EducationalDataState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      disciplines: disciplines ?? this.disciplines,
      periods: periods ?? this.periods,
      students: students ?? this.students,
      grades: grades ?? this.grades,
      message: clearMessage ? null : message ?? this.message,
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
        message,
      ];
}