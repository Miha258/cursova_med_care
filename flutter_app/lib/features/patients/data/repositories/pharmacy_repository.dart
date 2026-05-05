import '../../../core/network/api_service.dart';
import '../models/prescription_model.dart';

class PharmacyRepository {
  final ApiService _api = ApiService.instance;

  Future<List<PrescriptionModel>> getPrescriptions(String patientId) async {
    try {
      final response = await _api.get('/prescriptions/patient/$patientId');
      return (response.data as List).map((e) => PrescriptionModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Помилка завантаження рецептів: $e');
    }
  }

  Future<PrescriptionModel> createPrescription(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/prescriptions', data: data);
      return PrescriptionModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Помилка створення рецепта: $e');
    }
  }
}
