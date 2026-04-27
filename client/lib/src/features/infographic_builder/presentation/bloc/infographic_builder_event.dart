part of 'infographic_builder_bloc.dart';

abstract class InfographicBuilderEvent extends Equatable {
  const InfographicBuilderEvent();

  @override
  List<Object?> get props => [];
}

class InfographicBuilderStarted extends InfographicBuilderEvent {
  const InfographicBuilderStarted();
}

class InfographicBuilderRefreshRequested extends InfographicBuilderEvent {
  const InfographicBuilderRefreshRequested();
}

class InfographicGroupChanged extends InfographicBuilderEvent {
  final int? groupId;

  const InfographicGroupChanged({
    required this.groupId,
  });

  @override
  List<Object?> get props => [groupId];
}

class InfographicDisciplineChanged extends InfographicBuilderEvent {
  final int? disciplineId;

  const InfographicDisciplineChanged({
    required this.disciplineId,
  });

  @override
  List<Object?> get props => [disciplineId];
}

class InfographicPeriodChanged extends InfographicBuilderEvent {
  final int? periodId;

  const InfographicPeriodChanged({
    required this.periodId,
  });

  @override
  List<Object?> get props => [periodId];
}

class InfographicChartTypeChanged extends InfographicBuilderEvent {
  final InfographicChartType chartType;

  const InfographicChartTypeChanged({
    required this.chartType,
  });

  @override
  List<Object?> get props => [chartType];
}

class InfographicVisualTypeChanged extends InfographicBuilderEvent {
  final InfographicVisualType visualType;

  const InfographicVisualTypeChanged({
    required this.visualType,
  });

  @override
  List<Object?> get props => [visualType];
}

class InfographicGenerateRequested extends InfographicBuilderEvent {
  const InfographicGenerateRequested();
}

class InfographicSaveRequested extends InfographicBuilderEvent {
  final String title;

  const InfographicSaveRequested({
    required this.title,
  });

  @override
  List<Object?> get props => [title];
}