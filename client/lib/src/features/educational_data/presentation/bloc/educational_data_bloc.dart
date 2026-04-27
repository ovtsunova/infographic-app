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

    on<EducationalDisciplineCreateRequested>(_onDisciplineCreateRequested);
    on<EducationalDisciplineUpdateRequested>(_onDisciplineUpdateRequested);
    on<EducationalDisciplineDeleteRequested>(_onDisciplineDeleteRequested);

    on<EducationalPeriodCreateRequested>(_onPeriodCreateRequested);
    on<EducationalPeriodUpdateRequested>(_onPeriodUpdateRequested);
    on<EducationalPeriodDeleteRequested>(_onPeriodDeleteRequested);

    on<EducationalStudentCreateRequested>(_onStudentCreateRequested);
    on<EducationalStudentUpdateRequested>(_onStudentUpdateRequested);
    on<EducationalStudentDeleteRequested>(_onStudentDeleteRequested);

    on<EducationalGradeCreateRequested>(_onGradeCreateRequested);
    on<EducationalGradeUpdateRequested>(_onGradeUpdateRequested);
    on<EducationalGradeDeleteRequested>(_onGradeDeleteRequested);
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
    await _submitAndReload(
      emit: emit,
      successMessage: 'Учебная группа успешно добавлена',
      action: () => _repository.createGroup(
        groupName: event.groupName,
        course: event.course,
        studyYear: event.studyYear,
        directionName: event.directionName,
      ),
    );
  }

  Future<void> _onGroupUpdateRequested(
    EducationalGroupUpdateRequested event,
    Emitter<EducationalDataState> emit,
  ) async {
    await _submitAndReload(
      emit: emit,
      successMessage: 'Учебная группа успешно обновлена',
      action: () => _repository.updateGroup(
        id: event.id,
        groupName: event.groupName,
        course: event.course,
        studyYear: event.studyYear,
        directionName: event.directionName,
      ),
    );
  }

  Future<void> _onGroupDeleteRequested(
    EducationalGroupDeleteRequested event,
    Emitter<EducationalDataState> emit,
  ) async {
    await _submitAndReload(
      emit: emit,
      successMessage: 'Учебная группа успешно удалена',
      action: () => _repository.deleteGroup(
        id: event.id,
      ),
    );
  }

  Future<void> _onDisciplineCreateRequested(
    EducationalDisciplineCreateRequested event,
    Emitter<EducationalDataState> emit,
  ) async {
    await _submitAndReload(
      emit: emit,
      successMessage: 'Дисциплина успешно добавлена',
      action: () => _repository.createDiscipline(
        disciplineName: event.disciplineName,
        description: event.description,
        teacherName: event.teacherName,
      ),
    );
  }

  Future<void> _onDisciplineUpdateRequested(
    EducationalDisciplineUpdateRequested event,
    Emitter<EducationalDataState> emit,
  ) async {
    await _submitAndReload(
      emit: emit,
      successMessage: 'Дисциплина успешно обновлена',
      action: () => _repository.updateDiscipline(
        id: event.id,
        disciplineName: event.disciplineName,
        description: event.description,
        teacherName: event.teacherName,
      ),
    );
  }

  Future<void> _onDisciplineDeleteRequested(
    EducationalDisciplineDeleteRequested event,
    Emitter<EducationalDataState> emit,
  ) async {
    await _submitAndReload(
      emit: emit,
      successMessage: 'Дисциплина успешно удалена',
      action: () => _repository.deleteDiscipline(
        id: event.id,
      ),
    );
  }

  Future<void> _onPeriodCreateRequested(
    EducationalPeriodCreateRequested event,
    Emitter<EducationalDataState> emit,
  ) async {
    await _submitAndReload(
      emit: emit,
      successMessage: 'Учебный период успешно добавлен',
      action: () => _repository.createPeriod(
        studyYear: event.studyYear,
        semester: event.semester,
        startDate: event.startDate,
        endDate: event.endDate,
      ),
    );
  }

  Future<void> _onPeriodUpdateRequested(
    EducationalPeriodUpdateRequested event,
    Emitter<EducationalDataState> emit,
  ) async {
    await _submitAndReload(
      emit: emit,
      successMessage: 'Учебный период успешно обновлен',
      action: () => _repository.updatePeriod(
        id: event.id,
        studyYear: event.studyYear,
        semester: event.semester,
        startDate: event.startDate,
        endDate: event.endDate,
      ),
    );
  }

  Future<void> _onPeriodDeleteRequested(
    EducationalPeriodDeleteRequested event,
    Emitter<EducationalDataState> emit,
  ) async {
    await _submitAndReload(
      emit: emit,
      successMessage: 'Учебный период успешно удален',
      action: () => _repository.deletePeriod(
        id: event.id,
      ),
    );
  }

  Future<void> _onStudentCreateRequested(
    EducationalStudentCreateRequested event,
    Emitter<EducationalDataState> emit,
  ) async {
    await _submitAndReload(
      emit: emit,
      successMessage: 'Студент успешно добавлен',
      action: () => _repository.createStudent(
        lastName: event.lastName,
        firstName: event.firstName,
        patronymic: event.patronymic,
        recordBookNumber: event.recordBookNumber,
        groupId: event.groupId,
      ),
    );
  }

  Future<void> _onStudentUpdateRequested(
    EducationalStudentUpdateRequested event,
    Emitter<EducationalDataState> emit,
  ) async {
    await _submitAndReload(
      emit: emit,
      successMessage: 'Студент успешно обновлен',
      action: () => _repository.updateStudent(
        id: event.id,
        lastName: event.lastName,
        firstName: event.firstName,
        patronymic: event.patronymic,
        recordBookNumber: event.recordBookNumber,
        groupId: event.groupId,
      ),
    );
  }

  Future<void> _onStudentDeleteRequested(
    EducationalStudentDeleteRequested event,
    Emitter<EducationalDataState> emit,
  ) async {
    await _submitAndReload(
      emit: emit,
      successMessage: 'Студент успешно удален',
      action: () => _repository.deleteStudent(
        id: event.id,
      ),
    );
  }

  Future<void> _onGradeCreateRequested(
    EducationalGradeCreateRequested event,
    Emitter<EducationalDataState> emit,
  ) async {
    await _submitAndReload(
      emit: emit,
      successMessage: 'Оценка успешно добавлена',
      action: () => _repository.createGrade(
        studentId: event.studentId,
        disciplineId: event.disciplineId,
        periodId: event.periodId,
        gradeValue: event.gradeValue,
        controlType: event.controlType,
        gradeDate: event.gradeDate,
      ),
    );
  }

  Future<void> _onGradeUpdateRequested(
    EducationalGradeUpdateRequested event,
    Emitter<EducationalDataState> emit,
  ) async {
    await _submitAndReload(
      emit: emit,
      successMessage: 'Оценка успешно обновлена',
      action: () => _repository.updateGrade(
        id: event.id,
        studentId: event.studentId,
        disciplineId: event.disciplineId,
        periodId: event.periodId,
        gradeValue: event.gradeValue,
        controlType: event.controlType,
        gradeDate: event.gradeDate,
      ),
    );
  }

  Future<void> _onGradeDeleteRequested(
    EducationalGradeDeleteRequested event,
    Emitter<EducationalDataState> emit,
  ) async {
    await _submitAndReload(
      emit: emit,
      successMessage: 'Оценка успешно удалена',
      action: () => _repository.deleteGrade(
        id: event.id,
      ),
    );
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
          grades: data.grades,
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

  Future<void> _submitAndReload({
    required Emitter<EducationalDataState> emit,
    required String successMessage,
    required Future<void> Function() action,
  }) async {
    final previousState = state;

    emit(
      state.copyWith(
        status: EducationalDataStatus.submitting,
        clearMessage: true,
      ),
    );

    try {
      await action();

      final data = await _repository.loadAll();

      emit(
        EducationalDataState(
          status: EducationalDataStatus.success,
          groups: data.groups,
          disciplines: data.disciplines,
          periods: data.periods,
          students: data.students,
          grades: data.grades,
          message: successMessage,
        ),
      );
    } catch (error) {
      emit(
        previousState.copyWith(
          status: EducationalDataStatus.success,
          message: error.toString(),
        ),
      );
    }
  }
}