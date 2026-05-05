import 'package:equatable/equatable.dart';

class PrescriptionModel extends Equatable {
  final String id;
  final String patientId;
  final String medicationName;
  final String dosage;
  final String instruction;
  final String status; // active, completed, cancelled
  final String createdAt;

  const PrescriptionModel({
    required this.id,
    required this.patientId,
    required this.medicationName,
    required this.dosage,
    this.instruction = '',
    this.status = 'active',
    required this.createdAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      medicationName: json['medicationName'] ?? json['testName'] ?? 'Медикамент', // фолбек на випадок змішаних даних
      dosage: json['dosage'] ?? '',
      instruction: json['instruction'] ?? json['notes'] ?? '',
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  @override
  List<Object?> get props => [id, patientId, medicationName, dosage, instruction, status, createdAt];
}
