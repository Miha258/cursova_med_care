import 'package:equatable/equatable.dart';

class AppointmentModel extends Equatable {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String reason;
  final String? notes;
  final bool admissionRequired;
  final Map<String, dynamic>? patient;
  final Map<String, dynamic>? doctor;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.reason,
    this.notes,
    this.admissionRequired = false,
    this.patient,
    this.doctor,
  });

  String get timeStr {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  String get patientName {
    if (patient == null) return 'Пацієнт';
    return '${patient!['lastName']} ${patient!['firstName']}';
  }

  String get doctorName {
    if (doctor == null) return 'Лікар';
    return '${doctor!['lastName']} ${doctor!['firstName']}';
  }

  String get doctorSpec => doctor?['specialization'] ?? '';

  String get reasonLabel {
    switch (reason) {
      case 'primary': return 'Первинний';
      case 'repeat': return 'Повторний';
      case 'preventive': return 'Профілактичний';
      case 'emergency': return 'Невідкладна';
      default: return reason;
    }
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) => AppointmentModel(
        id: json['id'] ?? '',
        patientId: json['patientId'] ?? '',
        doctorId: json['doctorId'] ?? '',
        startTime: DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now(),
        endTime: DateTime.tryParse(json['endTime'] ?? '') ?? DateTime.now(),
        status: json['status'] ?? 'scheduled',
        reason: json['reason'] ?? 'primary',
        notes: json['notes'],
        admissionRequired: json['admissionRequired'] ?? false,
        patient: json['patient'],
        doctor: json['doctor'],
      );

  @override
  List<Object?> get props => [id];
}

class TimeSlot extends Equatable {
  final String time;
  final bool busy;
  const TimeSlot({required this.time, required this.busy});
  factory TimeSlot.fromJson(Map<String, dynamic> json) =>
      TimeSlot(time: json['time'], busy: json['busy'] ?? false);
  @override
  List<Object?> get props => [time, busy];
}

class DoctorModel extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String specialization;
  final String officeNumber;

  const DoctorModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.specialization,
    this.officeNumber = '',
  });

  String get fullName => '$lastName $firstName';
  String get shortName => '$lastName ${firstName[0]}.';

  factory DoctorModel.fromJson(Map<String, dynamic> json) => DoctorModel(
        id: json['id'] ?? '',
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        specialization: json['specialization'] ?? '',
        officeNumber: json['officeNumber'] ?? '',
      );

  @override
  List<Object?> get props => [id];
}
