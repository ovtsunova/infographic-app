class EducationalDataBundle {
  final List<StudyGroup> groups;
  final List<Discipline> disciplines;
  final List<StudyPeriod> periods;
  final List<Student> students;
  final List<GradeRecord> grades;

  const EducationalDataBundle({
    required this.groups,
    required this.disciplines,
    required this.periods,
    required this.students,
    required this.grades,
  });

  const EducationalDataBundle.empty()
      : groups = const [],
        disciplines = const [],
        periods = const [],
        students = const [],
        grades = const [];
}

class StudyGroup {
  final int id;
  final String groupName;
  final int course;
  final String studyYear;
  final String? directionName;

  const StudyGroup({
    required this.id,
    required this.groupName,
    required this.course,
    required this.studyYear,
    this.directionName,
  });

  factory StudyGroup.fromJson(Map<String, dynamic> json) {
    return StudyGroup(
      id: _readRequiredInt(json['id']),
      groupName: _readString(json['groupName']),
      course: _readRequiredInt(json['course']),
      studyYear: _readString(json['studyYear']),
      directionName: _readNullableString(json['directionName']),
    );
  }
}

class Discipline {
  final int id;
  final String disciplineName;
  final String? description;
  final String? teacherName;

  const Discipline({
    required this.id,
    required this.disciplineName,
    this.description,
    this.teacherName,
  });

  factory Discipline.fromJson(Map<String, dynamic> json) {
    return Discipline(
      id: _readRequiredInt(json['id']),
      disciplineName: _readString(json['disciplineName']),
      description: _readNullableString(json['description']),
      teacherName: _readNullableString(json['teacherName']),
    );
  }
}

class StudyPeriod {
  final int id;
  final String studyYear;
  final int semester;
  final String? startDate;
  final String? endDate;

  const StudyPeriod({
    required this.id,
    required this.studyYear,
    required this.semester,
    this.startDate,
    this.endDate,
  });

  factory StudyPeriod.fromJson(Map<String, dynamic> json) {
    return StudyPeriod(
      id: _readRequiredInt(json['id']),
      studyYear: _readString(json['studyYear']),
      semester: _readRequiredInt(json['semester']),
      startDate: _readNullableString(json['startDate']),
      endDate: _readNullableString(json['endDate']),
    );
  }

  String get title => '$studyYear, семестр $semester';
}

class Student {
  final int id;
  final String lastName;
  final String firstName;
  final String? patronymic;
  final String? recordBookNumber;
  final int groupId;
  final String groupName;

  const Student({
    required this.id,
    required this.lastName,
    required this.firstName,
    this.patronymic,
    this.recordBookNumber,
    required this.groupId,
    required this.groupName,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: _readRequiredInt(json['id']),
      lastName: _readString(json['lastName']),
      firstName: _readString(json['firstName']),
      patronymic: _readNullableString(json['patronymic']),
      recordBookNumber: _readNullableString(json['recordBookNumber']),
      groupId: _readRequiredInt(json['groupId']),
      groupName: _readString(json['groupName']),
    );
  }

  String get fullName {
    final parts = [
      lastName,
      firstName,
      patronymic,
    ].where((value) => value != null && value.trim().isNotEmpty);

    return parts.join(' ');
  }
}

class GradeRecord {
  final int id;
  final int gradeValue;
  final String controlType;
  final String? gradeDate;
  final int studentId;
  final String studentName;
  final int disciplineId;
  final String disciplineName;
  final int periodId;
  final String studyYear;
  final int semester;

  const GradeRecord({
    required this.id,
    required this.gradeValue,
    required this.controlType,
    required this.gradeDate,
    required this.studentId,
    required this.studentName,
    required this.disciplineId,
    required this.disciplineName,
    required this.periodId,
    required this.studyYear,
    required this.semester,
  });

  factory GradeRecord.fromJson(Map<String, dynamic> json) {
    return GradeRecord(
      id: _readRequiredInt(json['id']),
      gradeValue: _readRequiredInt(json['gradeValue']),
      controlType: _readString(json['controlType']),
      gradeDate: _readNullableString(json['gradeDate']),
      studentId: _readRequiredInt(json['studentId']),
      studentName: _readString(json['studentName']),
      disciplineId: _readRequiredInt(json['disciplineId']),
      disciplineName: _readString(json['disciplineName']),
      periodId: _readRequiredInt(json['periodId']),
      studyYear: _readString(json['studyYear']),
      semester: _readRequiredInt(json['semester']),
    );
  }

  String get periodTitle => '$studyYear, семестр $semester';
}

int _readRequiredInt(dynamic value) {
  return _readInt(value) ?? 0;
}

int? _readInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

String _readString(dynamic value) {
  return value?.toString().trim() ?? '';
}

String? _readNullableString(dynamic value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();

  if (text.isEmpty) {
    return null;
  }

  return text;
}