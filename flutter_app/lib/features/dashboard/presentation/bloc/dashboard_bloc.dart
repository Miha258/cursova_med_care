import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/repositories/dashboard_repository.dart';

// Events
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class DashboardLoadRequested extends DashboardEvent {}

// States
abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;
  const DashboardLoaded(this.stats);
  @override
  List<Object?> get props => [stats];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _repository;

  DashboardBloc({DashboardRepository? repository})
      : _repository = repository ?? DashboardRepository(),
        super(DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(DashboardLoadRequested event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    try {
      final stats = await _repository.getStats();
      emit(DashboardLoaded(stats));
    } catch (e) {
      emit(DashboardError('Не вдалось завантажити дані: $e'));
    }
  }
}
