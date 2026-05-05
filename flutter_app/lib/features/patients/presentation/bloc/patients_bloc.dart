import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/prescription_model.dart';
import '../../data/repositories/patients_repository.dart';
import '../../data/repositories/pharmacy_repository.dart';

// Events
abstract class PatientsEvent extends Equatable {
  const PatientsEvent();
  @override List<Object?> get props => [];
}
class PatientsLoadRequested extends PatientsEvent {}
class PatientsSearchRequested extends PatientsEvent {
  final String query;
  const PatientsSearchRequested(this.query);
  @override List<Object?> get props => [query];
}
class PatientLoadRequested extends PatientsEvent {
  final String id;
  const PatientLoadRequested(this.id);
  @override List<Object?> get props => [id];
}
class PatientCreateRequested extends PatientsEvent {
  final Map<String, dynamic> data;
  const PatientCreateRequested(this.data);
  @override List<Object?> get props => [data];
}
class PatientPrescriptionsRequested extends PatientsEvent {
  final String patientId;
  const PatientPrescriptionsRequested(this.patientId);
  @override List<Object?> get props => [patientId];
}
class PatientPrescriptionCreateRequested extends PatientsEvent {
  final Map<String, dynamic> data;
  const PatientPrescriptionCreateRequested(this.data);
  @override List<Object?> get props => [data];
}

// States
abstract class PatientsState extends Equatable {
  const PatientsState();
  @override List<Object?> get props => [];
}
class PatientsInitial extends PatientsState {}
class PatientsLoading extends PatientsState {}
class PatientCreating extends PatientsState {}
class PatientCreated extends PatientsState {
  final PatientModel patient;
  const PatientCreated(this.patient);
  @override List<Object?> get props => [patient];
}
class PatientsLoaded extends PatientsState {
  final List<PatientModel> patients;
  const PatientsLoaded(this.patients);
  @override List<Object?> get props => [patients];
}
class PatientDetailLoaded extends PatientsState {
  final PatientModel patient;
  const PatientDetailLoaded(this.patient);
  @override List<Object?> get props => [patient];
}
class PatientsError extends PatientsState {
  final String message;
  const PatientsError(this.message);
  @override List<Object?> get props => [message];
}
class PatientPrescriptionsLoaded extends PatientsState {
  final List<PrescriptionModel> prescriptions;
  const PatientPrescriptionsLoaded(this.prescriptions);
  @override List<Object?> get props => [prescriptions];
}
class PatientPrescriptionCreated extends PatientsState {
  final PrescriptionModel prescription;
  const PatientPrescriptionCreated(this.prescription);
  @override List<Object?> get props => [prescription];
}

// BLoC
class PatientsBloc extends Bloc<PatientsEvent, PatientsState> {
  final PatientsRepository _repository;
  final PharmacyRepository _pharmacy = PharmacyRepository();

  PatientsBloc({PatientsRepository? repository})
      : _repository = repository ?? PatientsRepository(),
        super(PatientsInitial()) {
    on<PatientsLoadRequested>(_onLoad);
    on<PatientsSearchRequested>(_onSearch);
    on<PatientLoadRequested>(_onLoadOne);
    on<PatientCreateRequested>(_onCreate);
    on<PatientPrescriptionsRequested>(_onLoadPrescriptions);
    on<PatientPrescriptionCreateRequested>(_onCreatePrescription);
  }

  Future<void> _onLoad(PatientsLoadRequested event, Emitter<PatientsState> emit) async {
    emit(PatientsLoading());
    try {
      final patients = await _repository.getAll();
      emit(PatientsLoaded(patients));
    } catch (e) {
      emit(PatientsError('Помилка завантаження пацієнтів: $e'));
    }
  }

  Future<void> _onSearch(PatientsSearchRequested event, Emitter<PatientsState> emit) async {
    emit(PatientsLoading());
    try {
      final patients = await _repository.getAll(search: event.query);
      emit(PatientsLoaded(patients));
    } catch (e) {
      emit(PatientsError('Помилка пошуку: $e'));
    }
  }

  Future<void> _onLoadOne(PatientLoadRequested event, Emitter<PatientsState> emit) async {
    emit(PatientsLoading());
    try {
      final patient = await _repository.getById(event.id);
      emit(PatientDetailLoaded(patient));
    } catch (e) {
      emit(PatientsError('Пацієнта не знайдено'));
    }
  }

  Future<void> _onCreate(PatientCreateRequested event, Emitter<PatientsState> emit) async {
    emit(PatientCreating());
    try {
      final patient = await _repository.create(event.data);
      emit(PatientCreated(patient));
      final patients = await _repository.getAll();
      emit(PatientsLoaded(patients));
    } catch (e) {
      emit(PatientsError('Помилка створення пацієнта: $e'));
    }
  }

  Future<void> _onLoadPrescriptions(PatientPrescriptionsRequested event, Emitter<PatientsState> emit) async {
    try {
      final prescriptions = await _pharmacy.getPrescriptions(event.patientId);
      emit(PatientPrescriptionsLoaded(prescriptions));
    } catch (e) {
      emit(PatientsError(e.toString()));
    }
  }

  Future<void> _onCreatePrescription(PatientPrescriptionCreateRequested event, Emitter<PatientsState> emit) async {
    try {
      final p = await _pharmacy.createPrescription(event.data);
      emit(PatientPrescriptionCreated(p));
      add(PatientPrescriptionsRequested(p.patientId));
    } catch (e) {
      emit(PatientsError(e.toString()));
    }
  }
}
