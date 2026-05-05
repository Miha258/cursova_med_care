import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/patient_model.dart';

class PatientsRepository {
  final ApiService _api;
  PatientsRepository({ApiService? api}) : _api = api ?? ApiService.instance;

  // GET /patients — список всіх пацієнтів
  Future<List<PatientModel>> getAll({String? search}) async {
    final response = await _api.get(ApiConstants.patients, queryParameters: search != null ? {'search': search} : null);
    return (response.data as List).map((e) => PatientModel.fromJson(e)).toList();
  }

  // GET /patients/:id — кеш Redis TTL=5хв
  Future<PatientModel> getById(String id) async {
    final response = await _api.get('${ApiConstants.patients}/$id');
    return PatientModel.fromJson(response.data);
  }

  // POST /patients — реєстрація (HTTP 201 + UUID)
  Future<PatientModel> create(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConstants.patients, data: data);
    return PatientModel.fromJson(response.data);
  }

  // PATCH /patients/:id — оновлення
  Future<PatientModel> update(String id, Map<String, dynamic> data) async {
    final response = await _api.patch('${ApiConstants.patients}/$id', data: data);
    return PatientModel.fromJson(response.data);
  }

  // GET /patients/search?q= — повнотекстовий пошук (PostgreSQL pg_trgm)
  Future<List<PatientModel>> search(String q) async {
    final response = await _api.get(ApiConstants.patientSearch, queryParameters: {'q': q});
    return (response.data as List).map((e) => PatientModel.fromJson(e)).toList();
  }
}
