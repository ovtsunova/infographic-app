part of 'educational_data_bloc.dart';

abstract class EducationalDataEvent extends Equatable {
  const EducationalDataEvent();

  @override
  List<Object?> get props => [];
}

class EducationalDataStarted extends EducationalDataEvent {
  const EducationalDataStarted();
}

class EducationalDataRefreshRequested extends EducationalDataEvent {
  const EducationalDataRefreshRequested();
}

class EducationalGroupCreateRequested extends EducationalDataEvent {
  final String groupName;
  final int course;
  final String studyYear;
  final String? directionName;

  const EducationalGroupCreateRequested({
    required this.groupName,
    required this.course,
    required this.studyYear,
    required this.directionName,
  });

  @override
  List<Object?> get props => [
        groupName,
        course,
        studyYear,
        directionName,
      ];
}

class EducationalGroupUpdateRequested extends EducationalDataEvent {
  final int id;
  final String groupName;
  final int course;
  final String studyYear;
  final String? directionName;

  const EducationalGroupUpdateRequested({
    required this.id,
    required this.groupName,
    required this.course,
    required this.studyYear,
    required this.directionName,
  });

  @override
  List<Object?> get props => [
        id,
        groupName,
        course,
        studyYear,
        directionName,
      ];
}

class EducationalGroupDeleteRequested extends EducationalDataEvent {
  final int id;

  const EducationalGroupDeleteRequested({
    required this.id,
  });

  @override
  List<Object?> get props => [id];
}

class EducationalDisciplineCreateRequested extends EducationalDataEvent {
  final String disciplineName;
  final String? description;
  final String? teacherName;

  const EducationalDisciplineCreateRequested({
    required this.disciplineName,
    required this.description,
    required this.teacherName,
  });

  @override
  List<Object?> get props => [
        disciplineName,
        description,
        teacherName,
      ];
}

class EducationalDisciplineUpdateRequested extends EducationalDataEvent {
  final int id;
  final String disciplineName;
  final String? description;
  final String? teacherName;

  const EducationalDisciplineUpdateRequested({
    required this.id,
    required this.disciplineName,
    required this.description,
    required this.teacherName,
  });

  @override
  List<Object?> get props => [
        id,
        disciplineName,
        description,
        teacherName,
      ];
}

class EducationalDisciplineDeleteRequested extends EducationalDataEvent {
  final int id;

  const EducationalDisciplineDeleteRequested({
    required this.id,
  });

  @override
  List<Object?> get props => [id];
}

class EducationalPeriodCreateRequested extends EducationalDataEvent {
  final String studyYear;
  final int semester;
  final String startDate;
  final String endDate;

  const EducationalPeriodCreateRequested({
    required this.studyYear,
    required this.semester,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [
        studyYear,
        semester,
        startDate,
        endDate,
      ];
}

class EducationalPeriodUpdateRequested extends EducationalDataEvent {
  final int id;
  final String studyYear;
  final int semester;
  final String startDate;
  final String endDate;

  const EducationalPeriodUpdateRequested({
    required this.id,
    required this.studyYear,
    required this.semester,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [
        id,
        studyYear,
        semester,
        startDate,
        endDate,
      ];
}

class EducationalPeriodDeleteRequested extends EducationalDataEvent {
  final int id;

  const EducationalPeriodDeleteRequested({
    required this.id,
  });

  @override
  List<Object?> get props => [id];
}

class EducationalStudentCreateRequested extends EducationalDataEvent {
  final String lastName;
  final String firstName;
  final String? patronymic;
  final String? recordBookNumber;
  final int groupId;

  const EducationalStudentCreateRequested({
    required this.lastName,
    required this.firstName,
    required this.patronymic,
    required this.recordBookNumber,
    required this.groupId,
  });

  @override
  List<Object?> get props => [
        lastName,
        firstName,
        patronymic,
        recordBookNumber,
        groupId,
      ];
}

class EducationalStudentUpdateRequested extends EducationalDataEvent {
  final int id;
  final String lastName;
  final String firstName;
  final String? patronymic;
  final String? recordBookNumber;
  final int groupId;

  const EducationalStudentUpdateRequested({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.patronymic,
    required this.recordBookNumber,
    required this.groupId,
  });

  @override
  List<Object?> get props => [
        id,
        lastName,
        firstName,
        patronymic,
        recordBookNumber,
        groupId,
      ];
}

class EducationalStudentDeleteRequested extends EducationalDataEvent {
  final int id;

  const EducationalStudentDeleteRequested({
    required this.id,
  });

  @override
  List<Object?> get props => [id];
}

class EducationalGradeCreateRequested extends EducationalDataEvent {
  final int studentId;
  final int disciplineId;
  final int periodId;
  final int gradeValue;
  final String controlType;
  final String? gradeDate;

  const EducationalGradeCreateRequested({
    required this.studentId,
    required this.disciplineId,
    required this.periodId,
    required this.gradeValue,
    required this.controlType,
    required this.gradeDate,
  });

  @override
  List<Object?> get props => [
        studentId,
        disciplineId,
        periodId,
        gradeValue,
        controlType,
        gradeDate,
      ];
}

class EducationalGradeUpdateRequested extends EducationalDataEvent {
  final int id;
  final int studentId;
  final int disciplineId;
  final int periodId;
  final int gradeValue;
  final String controlType;
  final String gradeDate;

  const EducationalGradeUpdateRequested({
    required this.id,
    required this.studentId,
    required this.disciplineId,
    required this.periodId,
    required this.gradeValue,
    required this.controlType,
    required this.gradeDate,
  });

  @override
  List<Object?> get props => [
        id,
        studentId,
        disciplineId,
        periodId,
        gradeValue,
        controlType,
        gradeDate,
      ];
}

class EducationalGradeDeleteRequested extends EducationalDataEvent {
  final int id;

  const EducationalGradeDeleteRequested({
    required this.id,
  });

  @override
  List<Object?> get props => [id];
}

class EducationalAttendanceCreateRequested extends EducationalDataEvent {
  final int studentId;
  final int disciplineId;
  final int periodId;
  final int attendedCount;
  final int missedCount;

  const EducationalAttendanceCreateRequested({
    required this.studentId,
    required this.disciplineId,
    required this.periodId,
    required this.attendedCount,
    required this.missedCount,
  });

  @override
  List<Object?> get props => [
        studentId,
        disciplineId,
        periodId,
        attendedCount,
        missedCount,
      ];
}

class EducationalAttendanceUpdateRequested extends EducationalDataEvent {
  final int id;
  final int studentId;
  final int disciplineId;
  final int periodId;
  final int attendedCount;
  final int missedCount;

  const EducationalAttendanceUpdateRequested({
    required this.id,
    required this.studentId,
    required this.disciplineId,
    required this.periodId,
    required this.attendedCount,
    required this.missedCount,
  });

  @override
  List<Object?> get props => [
        id,
        studentId,
        disciplineId,
        periodId,
        attendedCount,
        missedCount,
      ];
}

class EducationalAttendanceDeleteRequested extends EducationalDataEvent {
  final int id;

  const EducationalAttendanceDeleteRequested({
    required this.id,
  });

  @override
  List<Object?> get props => [id];
}