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