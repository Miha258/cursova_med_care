import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/pharmacy_models.dart';
import '../../data/repositories/pharmacy_repository.dart';

// Events
abstract class PharmacyEvent extends Equatable {
  const PharmacyEvent();
  @override List<Object?> get props => [];
}
class PharmacyLoadRequested extends PharmacyEvent {
  final String patientId;
  const PharmacyLoadRequested(this.patientId);
  @override List<Object?> get props => [patientId];
}
class PharmacyCreatePrescription extends PharmacyEvent {
  final Map<String, dynamic> data;
  const PharmacyCreatePrescription(this.data);
  @override List<Object?> get props => [data];
}

// States
abstract class PharmacyState extends Equatable {
  const PharmacyState();
  @override List<Object?> get props => [];
}
class PharmacyInitial extends PharmacyState {}
class PharmacyLoading extends PharmacyState {}
class PharmacyLoaded extends PharmacyState {
  final List<PrescriptionModel> prescriptions;
  final List<MedicationModel> medications;
  const PharmacyLoaded({required this.prescriptions, required this.medications});
  @override List<Object?> get props => [prescriptions, medications];
}
class PharmacyCreating extends PharmacyState {
  final List<PrescriptionModel> prescriptions;
  final List<MedicationModel> medications;
  const PharmacyCreating({required this.prescriptions, required this.medications});
  @override List<Object?> get props => [prescriptions, medications];
}
class PharmacyPrescriptionCreated extends PharmacyState {
  final List<PrescriptionModel> prescriptions;
  final List<MedicationModel> medications;
  const PharmacyPrescriptionCreated({required this.prescriptions, required this.medications});
  @override List<Object?> get props => [prescriptions, medications];
}
class PharmacyError extends PharmacyState {
  final String message;
  const PharmacyError(this.message);
  @override List<Object?> get props => [message];
}

// BLoC
class PharmacyBloc extends Bloc<PharmacyEvent, PharmacyState> {
  final PharmacyRepository _repo;
  List<MedicationModel> _medications = [];
  List<PrescriptionModel> _prescriptions = [];

  PharmacyBloc({PharmacyRepository? repo})
      : _repo = repo ?? PharmacyRepository(),
        super(PharmacyInitial()) {
    on<PharmacyLoadRequested>(_onLoad);
    on<PharmacyCreatePrescription>(_onCreate);
  }

  Future<void> _onLoad(PharmacyLoadRequested event, Emitter<PharmacyState> emit) async {
    emit(PharmacyLoading());
    try {
      final results = await Future.wait([
        _repo.getMedications(),
        _repo.getByPatient(event.patientId),
      ]);
      _medications = results[0] as List<MedicationModel>;
      _prescriptions = results[1] as List<PrescriptionModel>;
      emit(PharmacyLoaded(prescriptions: _prescriptions, medications: _medications));
    } catch (e) {
      emit(PharmacyError('Помилка завантаження: $e'));
    }
  }

  Future<void> _onCreate(PharmacyCreatePrescription event, Emitter<PharmacyState> emit) async {
    emit(PharmacyCreating(prescriptions: _prescriptions, medications: _medications));
    try {
      final rx = await _repo.create(event.data);
      _prescriptions = [rx, ..._prescriptions];
      emit(PharmacyPrescriptionCreated(prescriptions: _prescriptions, medications: _medications));
      emit(PharmacyLoaded(prescriptions: _prescriptions, medications: _medications));
    } catch (e) {
      emit(PharmacyError('Помилка: $e'));
      emit(PharmacyLoaded(prescriptions: _prescriptions, medications: _medications));
    }
  }
}
