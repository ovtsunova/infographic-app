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
  final List<AttendanceRecord> attendance;
  final String? message;

  const EducationalDataState({
    required this.status,
    required this.groups,
    required this.disciplines,
    required this.periods,
    required this.students,
    required this.grades,
    required this.attendance,
    this.message,
  });

  const EducationalDataState.initial()
      : status = EducationalDataStatus.initial,
        groups = const [],
        disciplines = const [],
        periods = const [],
        students = const [],
        grades = const [],
        attendance = const [],
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
        grades.isNotEmpty ||
        attendance.isNotEmpty;
  }

  EducationalDataState copyWith({
    EducationalDataStatus? status,
    List<StudyGroup>? groups,
    List<Discipline>? disciplines,
    List<StudyPeriod>? periods,
    List<Student>? students,
    List<GradeRecord>? grades,
    List<AttendanceRecord>? attendance,
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
      attendance: attendance ?? this.attendance,
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
        attendance,
        message,
      ];
}