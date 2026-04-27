part of 'saved_infographics_bloc.dart';

abstract class SavedInfographicsEvent extends Equatable {
  const SavedInfographicsEvent();

  @override
  List<Object?> get props => [];
}

class SavedInfographicsStarted extends SavedInfographicsEvent {
  const SavedInfographicsStarted();
}

class SavedInfographicsRefreshRequested extends SavedInfographicsEvent {
  const SavedInfographicsRefreshRequested();
}

class SavedInfographicDeleteRequested extends SavedInfographicsEvent {
  final int id;

  const SavedInfographicDeleteRequested({
    required this.id,
  });

  @override
  List<Object?> get props => [id];
}