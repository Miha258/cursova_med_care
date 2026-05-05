import 'package:equatable/equatable.dart';

class MedicationModel extends Equatable {
  final String id;
  final String name;
  final int quantity;
  final int minQuantity;
  final String unit;
  final double price;
  final String expiryDate;

  const MedicationModel({
    required this.id,
    required this.name,
    this.quantity = 0,
    this.minQuantity = 0,
    this.unit = 'таб.',
    this.price = 0,
    this.expiryDate = '',
  });

  bool get isLowStock => quantity <= minQuantity;

  factory MedicationModel.fromJson(Map<String, dynamic> json) => MedicationModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        quantity: json['quantity'] ?? 0,
        minQuantity: json['minQuantity'] ?? 0,
        unit: json['unit'] ?? 'таб.',
        price: (json['price'] ?? 0).toDouble(),
        expiryDate: json['expiryDate'] ?? '',
      );

  @override
  List<Object?> get props => [id];
}

class PrescriptionModel extends Equatable {
  final String id;
  final String patientId;
  final String doctorId;
  final String medicationId;
  final String medicationName;
  final String dosage;
  final String frequency;
  final int durationDays;
  final String issuedAt;
  final String status;

  const PrescriptionModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.medicationId,
    this.medicationName = '',
    required this.dosage,
    required this.frequency,
    required this.durationDays,
    this.issuedAt = '',
    this.status = 'active',
  });

  String get statusLabel {
    switch (status) {
      case 'active': return 'Активний';
      case 'completed': return 'Виконано';
      case 'cancelled': return 'Скасовано';
      default: return status;
    }
  }

  String get formattedDate {
    if (issuedAt.isEmpty) return '—';
    try {
      final dt = DateTime.parse(issuedAt);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return issuedAt.substring(0, 10);
    }
  }

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    final med = json['medication'];
    return PrescriptionModel(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      medicationId: json['medicationId'] ?? '',
      medicationName: med != null ? (med['name'] ?? '') : '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      durationDays: json['durationDays'] ?? 0,
      issuedAt: json['issuedAt'] ?? '',
      status: json['status'] ?? 'active',
    );
  }

  @override
  List<Object?> get props => [id];
}
