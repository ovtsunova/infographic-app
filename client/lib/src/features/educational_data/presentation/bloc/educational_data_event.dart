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