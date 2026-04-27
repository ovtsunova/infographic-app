import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:client/src/features/educational_data/data/educational_data_models.dart';
import 'package:client/src/features/educational_data/data/educational_data_repository.dart';

part 'educational_data_event.dart';
part 'educational_data_state.dart';

class EducationalDataBloc
    extends Bloc<EducationalDataEvent, EducationalDataState> {
  final EducationalDataRepository _repository;

  EducationalDataBloc({
    required EducationalDataRepository repository,
  })  : _repository = repository,
        super(const EducationalDataState.initial()) {
    on<EducationalDataStarted>(_onStarted);
    on<EducationalDataRefreshRequested>(_onRefreshRequested);
    on<EducationalGroupCreateRequested>(_onGroupCreateRequested);
    on<EducationalGroupUpdateRequested>(_onGroupUpdateRequested);
    on<EducationalGroupDeleteRequested>(_onGroupDeleteRequested);
  }

  Future<void> _onStarted(
    EducationalDataStarted event,
    Emitter<EducationalDataState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _onRefreshRequested(
    EducationalDataRefreshRequested event,
    Emitter<EducationalDataState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _onGroupCreateRequested(
    EducationalGroupCreateRequested event,
    Emitter<EducationalDataState> emit,
  ) async {
    emit(
      state.copyWith(
        status: EducationalDataStatus.submitting,
        clearMessage: true,
      ),
    );

    try {
      await _repository.createGroup(
        groupName: event.groupName,
        course: event.course,
        studyYear: event.studyYear,
        directionName: event.directionName,
      );

      final data = await _repository.loadAll();

      emit(
        EducationalDataState(
          status: EducationalDataStatus.success,
          groups: data.groups,
          disciplines: data.disciplines,
          periods: data.periods,
          students: data.students,
          message: 'Учебная группа успешно добавлена',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: EducationalDataStatus.failure,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> _onGroupUpdateRequested(
    EducationalGroupUpdateRequested event,
    Emitter<EducationalDataState> emit,
  ) async {
    emit(
      state.copyWith(
        status: EducationalDataStatus.submitting,
        clearMessage: true,
      ),
    );

    try {
      await _repository.updateGroup(
        id: event.id,
        groupName: event.groupName,
        course: event.course,
        studyYear: event.studyYear,
        directionName: event.directionName,
      );

      final data = await _repository.loadAll();

      emit(
        EducationalDataState(
          status: EducationalDataStatus.success,
          groups: data.groups,
          disciplines: data.disciplines,
          periods: data.periods,
          students: data.students,
          message: 'Учебная группа успешно обновлена',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: EducationalDataStatus.failure,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> _onGroupDeleteRequested(
    EducationalGroupDeleteRequested event,
    Emitter<EducationalDataState> emit,
  ) async {
    emit(
      state.copyWith(
        status: EducationalDataStatus.submitting,
        clearMessage: true,
      ),
    );

    try {
      await _repository.deleteGroup(id: event.id);

      final data = await _repository.loadAll();

      emit(
        EducationalDataState(
          status: EducationalDataStatus.success,
          groups: data.groups,
          disciplines: data.disciplines,
          periods: data.periods,
          students: data.students,
          message: 'Учебная группа успешно удалена',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: EducationalDataStatus.failure,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> _loadData(
    Emitter<EducationalDataState> emit,
  ) async {
    emit(
      state.copyWith(
        status: EducationalDataStatus.loading,
        clearMessage: true,
      ),
    );

    try {
      final data = await _repository.loadAll();

      emit(
        EducationalDataState(
          status: EducationalDataStatus.success,
          groups: data.groups,
          disciplines: data.disciplines,
          periods: data.periods,
          students: data.students,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: EducationalDataStatus.failure,
          message: error.toString(),
        ),
      );
    }
  }
}