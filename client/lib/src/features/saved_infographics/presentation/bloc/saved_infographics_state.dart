part of 'saved_infographics_bloc.dart';

enum SavedInfographicsStatus {
  initial,
  loading,
  submitting,
  success,
  failure,
}

class SavedInfographicsState extends Equatable {
  final SavedInfographicsStatus status;
  final List<SavedInfographic> items;
  final String? message;

  const SavedInfographicsState({
    required this.status,
    required this.items,
    this.message,
  });

  const SavedInfographicsState.initial()
      : status = SavedInfographicsStatus.initial,
        items = const [],
        message = null;

  bool get isBusy {
    return status == SavedInfographicsStatus.loading ||
        status == SavedInfographicsStatus.submitting;
  }

  bool get hasAnyData => items.isNotEmpty;

  SavedInfographicsState copyWith({
    SavedInfographicsStatus? status,
    List<SavedInfographic>? items,
    String? message,
    bool clearMessage = false,
  }) {
    return SavedInfographicsState(
      status: status ?? this.status,
      items: items ?? this.items,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        message,
      ];
}