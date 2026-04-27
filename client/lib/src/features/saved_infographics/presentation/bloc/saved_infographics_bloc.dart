import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:client/src/features/saved_infographics/data/saved_infographics_models.dart';
import 'package:client/src/features/saved_infographics/data/saved_infographics_repository.dart';

part 'saved_infographics_event.dart';
part 'saved_infographics_state.dart';

class SavedInfographicsBloc
    extends Bloc<SavedInfographicsEvent, SavedInfographicsState> {
  final SavedInfographicsRepository _repository;

  SavedInfographicsBloc({
    required SavedInfographicsRepository repository,
  })  : _repository = repository,
        super(const SavedInfographicsState.initial()) {
    on<SavedInfographicsStarted>(_onStarted);
    on<SavedInfographicsRefreshRequested>(_onRefreshRequested);
    on<SavedInfographicDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onStarted(
    SavedInfographicsStarted event,
    Emitter<SavedInfographicsState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _onRefreshRequested(
    SavedInfographicsRefreshRequested event,
    Emitter<SavedInfographicsState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _onDeleteRequested(
    SavedInfographicDeleteRequested event,
    Emitter<SavedInfographicsState> emit,
  ) async {
    final previousState = state;

    emit(
      state.copyWith(
        status: SavedInfographicsStatus.submitting,
        clearMessage: true,
      ),
    );

    try {
      await _repository.deleteInfographic(id: event.id);

      final items = await _repository.loadMyInfographics();

      emit(
        SavedInfographicsState(
          status: SavedInfographicsStatus.success,
          items: items,
          message: 'Инфографика успешно удалена',
        ),
      );
    } catch (error) {
      emit(
        previousState.copyWith(
          status: SavedInfographicsStatus.success,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> _load(
    Emitter<SavedInfographicsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SavedInfographicsStatus.loading,
        clearMessage: true,
      ),
    );

    try {
      final items = await _repository.loadMyInfographics();

      emit(
        SavedInfographicsState(
          status: SavedInfographicsStatus.success,
          items: items,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: SavedInfographicsStatus.failure,
          message: error.toString(),
        ),
      );
    }
  }
}