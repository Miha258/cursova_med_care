import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/appointment_model.dart';

class AppointmentsRepository {
  final ApiService _api;
  AppointmentsRepository({ApiService? api}) : _api = api ?? ApiService.instance;

  Future<List<AppointmentModel>> getAll() async {
    final response = await _api.get(ApiConstants.appointments);
    return (response.data as List).map((e) => AppointmentModel.fromJson(e)).toList();
  }

  Future<List<AppointmentModel>> getToday() async {
    final response = await _api.get(ApiConstants.appointmentsToday);
    return (response.data as List).map((e) => AppointmentModel.fromJson(e)).toList();
  }

  // GET /appointments/slots?doctorId=X&date=Y — вільні слоти (SQL JOIN ~45мс)
  Future<List<TimeSlot>> getSlots(String doctorId, String date) async {
    final response = await _api.get(ApiConstants.appointmentSlots, queryParameters: {'doctorId': doctorId, 'date': date});
    return (response.data as List).map((e) => TimeSlot.fromJson(e)).toList();
  }

  // GET /doctors — список лікарів для вибору
  Future<List<DoctorModel>> getDoctors({String? specialization}) async {
    final response = await _api.get(ApiConstants.doctors, queryParameters: specialization != null ? {'specialization': specialization} : null);
    return (response.data as List).map((e) => DoctorModel.fromJson(e)).toList();
  }

  // POST /appointments — запис + автоматична FCM нотифікація (Firebase)
  Future<AppointmentModel> create(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConstants.appointments, data: data);
    return AppointmentModel.fromJson(response.data);
  }

  Future<List<AppointmentModel>> getByPatient(String patientId) async {
    final response = await _api.get(ApiConstants.appointments, queryParameters: {'patientId': patientId});
    return (response.data as List).map((e) => AppointmentModel.fromJson(e)).toList();
  }

  Future<void> cancel(String id) => _api.delete('${ApiConstants.appointments}/$id');
}
