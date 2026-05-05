import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  // NestJS REST API base URL
  // localhost — для веб-браузера на тому ж Mac
  // 192.168.19.103 — для фізичного телефону в тій самій Wi-Fi мережі
  static String get baseUrl {
    // Твій реальний сервер
    return 'http://45.12.111.55:3001/api';
  }

  // Auth endpoints
  static const login = '/auth/login';
  static const refresh = '/auth/refresh';

  // Dashboard
  static const dashboardStats = '/dashboard/stats';

  // Patients
  static const patients = '/patients';
  static const patientSearch = '/patients/search';

  // Appointments
  static const appointments = '/appointments';
  static const appointmentsToday = '/appointments/today';
  static const appointmentSlots = '/appointments/slots';

  // Medical records
  static const medicalRecords = '/medical-records';

  // Pharmacy
  static const medications = '/medications';
  static const prescriptions = '/prescriptions';

  // Finance
  static const invoices = '/invoices';

  // Reports
  static const reportsAppointments = '/reports/appointments';
  static const reportsRevenue = '/reports/revenue';
  static const reportsDoctors = '/reports/doctors';

  // Doctors
  static const doctors = '/doctors';

  // Notifications (POST /notifications/sms via Twilio)
  static const notificationsSms = '/notifications/sms';

  // Timeouts
  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 10);
}
