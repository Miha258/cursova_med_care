import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/appointment_model.dart';
import '../../data/repositories/appointments_repository.dart';

// Events
abstract class AppointmentsEvent extends Equatable {
  const AppointmentsEvent();
  @override List<Object?> get props => [];
}
class AppointmentsLoadRequested extends AppointmentsEvent {}
class AppointmentSlotsRequested extends AppointmentsEvent {
  final String doctorId;
  final String date;
  const AppointmentSlotsRequested({required this.doctorId, required this.date});
  @override List<Object?> get props => [doctorId, date];
}
class AppointmentDoctorsRequested extends AppointmentsEvent {}
class AppointmentCreateRequested extends AppointmentsEvent {
  final Map<String, dynamic> data;
  const AppointmentCreateRequested(this.data);
  @override List<Object?> get props => [data];
}
class AppointmentPatientRequested extends AppointmentsEvent {
  final String patientId;
  const AppointmentPatientRequested(this.patientId);
  @override List<Object?> get props => [patientId];
}

// States
abstract class AppointmentsState extends Equatable {
  const AppointmentsState();
  @override List<Object?> get props => [];
}
class AppointmentsInitial extends AppointmentsState {}
class AppointmentsLoading extends AppointmentsState {}
class AppointmentsLoaded extends AppointmentsState {
  final List<AppointmentModel> appointments;
  const AppointmentsLoaded(this.appointments);
  @override List<Object?> get props => [appointments];
}
class AppointmentSlotsLoaded extends AppointmentsState {
  final List<TimeSlot> slots;
  final List<DoctorModel> doctors;
  const AppointmentSlotsLoaded({required this.slots, required this.doctors});
  @override List<Object?> get props => [slots, doctors];
}
class AppointmentCreated extends AppointmentsState {
  final AppointmentModel appointment;
  const AppointmentCreated(this.appointment);
  @override List<Object?> get props => [appointment];
}
class AppointmentsError extends AppointmentsState {
  final String message;
  const AppointmentsError(this.message);
  @override List<Object?> get props => [message];
}

// BLoC
class AppointmentsBloc extends Bloc<AppointmentsEvent, AppointmentsState> {
  final AppointmentsRepository _repository;
  List<DoctorModel> _doctors = [];
  List<TimeSlot> _slots = [];

  AppointmentsBloc({AppointmentsRepository? repository})
      : _repository = repository ?? AppointmentsRepository(),
        super(AppointmentsInitial()) {
    on<AppointmentsLoadRequested>(_onLoad);
    on<AppointmentPatientRequested>(_onPatient);
    on<AppointmentDoctorsRequested>(_onDoctors);
    on<AppointmentSlotsRequested>(_onSlots);
    on<AppointmentCreateRequested>(_onCreate);
  }

  Future<void> _onPatient(AppointmentPatientRequested event, Emitter<AppointmentsState> emit) async {
    emit(AppointmentsLoading());
    try {
      final list = await _repository.getByPatient(event.patientId);
      emit(AppointmentsLoaded(list));
    } catch (e) {
      emit(AppointmentsError('Помилка завантаження: $e'));
    }
  }

  Future<void> _onLoad(AppointmentsLoadRequested event, Emitter<AppointmentsState> emit) async {
    emit(AppointmentsLoading());
    try {
      final list = await _repository.getAll();
      emit(AppointmentsLoaded(list));
    } catch (e) {
      emit(AppointmentsError('Помилка завантаження: $e'));
    }
  }

  Future<void> _onDoctors(AppointmentDoctorsRequested event, Emitter<AppointmentsState> emit) async {
    emit(AppointmentsLoading());
    try {
      _doctors = await _repository.getDoctors();
      emit(AppointmentSlotsLoaded(slots: _slots, doctors: _doctors));
    } catch (e) {
      emit(AppointmentsError('Не вдалось завантажити лікарів'));
    }
  }

  Future<void> _onSlots(AppointmentSlotsRequested event, Emitter<AppointmentsState> emit) async {
    try {
      _slots = await _repository.getSlots(event.doctorId, event.date);
      emit(AppointmentSlotsLoaded(slots: _slots, doctors: _doctors));
    } catch (e) {
      emit(AppointmentsError('Не вдалось завантажити слоти'));
    }
  }

  Future<void> _onCreate(AppointmentCreateRequested event, Emitter<AppointmentsState> emit) async {
    emit(AppointmentsLoading());
    try {
      // POST /appointments → NestJS → PostgreSQL транзакція + FCM push
      final appointment = await _repository.create(event.data);
      emit(AppointmentCreated(appointment));
    } catch (e) {
      emit(AppointmentsError('Не вдалось записати: $e'));
    }
  }
}
