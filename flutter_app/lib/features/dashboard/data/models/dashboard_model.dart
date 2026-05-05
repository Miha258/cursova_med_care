import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int appointmentsToday;
  final int newPatientsToday;
  final int activePatients;
  final int occupancyPercent;
  final List<AppointmentSummary> upcomingAppointments;

  const DashboardStats({
    required this.appointmentsToday,
    required this.newPatientsToday,
    required this.activePatients,
    required this.occupancyPercent,
    required this.upcomingAppointments,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        appointmentsToday: json['appointmentsToday'] ?? 0,
        newPatientsToday: json['newPatientsToday'] ?? 0,
        activePatients: json['activePatients'] ?? 0,
        occupancyPercent: json['occupancyPercent'] ?? 0,
        upcomingAppointments: (json['upcomingAppointments'] as List? ?? [])
            .map((e) => AppointmentSummary.fromJson(e))
            .toList(),
      );

  @override
  List<Object?> get props => [appointmentsToday, activePatients];
}

class AppointmentSummary extends Equatable {
  final String id;
  final String patientName;
  final String specialization;
  final String time;
  final String status;

  const AppointmentSummary({
    required this.id,
    required this.patientName,
    required this.specialization,
    required this.time,
    required this.status,
  });

  factory AppointmentSummary.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'];
    final doctor = json['doctor'];
    final startTime = DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now();
    return AppointmentSummary(
      id: json['id'] ?? '',
      patientName: patient != null ? '${patient['lastName']} ${patient['firstName']}' : 'Пацієнт',
      specialization: doctor?['specialization'] ?? 'Лікар',
      time: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      status: json['status'] ?? 'scheduled',
    );
  }

  @override
  List<Object?> get props => [id];
}
