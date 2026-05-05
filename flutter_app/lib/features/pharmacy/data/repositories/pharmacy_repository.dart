import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/pharmacy_models.dart';

class PharmacyRepository {
  final ApiService _api;
  PharmacyRepository({ApiService? api}) : _api = api ?? ApiService.instance;

  Future<List<MedicationModel>> getMedications() async {
    final r = await _api.get(ApiConstants.medications);
    return (r.data as List).map((e) => MedicationModel.fromJson(e)).toList();
  }

  Future<List<PrescriptionModel>> getByPatient(String patientId) async {
    final r = await _api.get('${ApiConstants.prescriptions}/patient/$patientId');
    return (r.data as List).map((e) => PrescriptionModel.fromJson(e)).toList();
  }

  Future<PrescriptionModel> create(Map<String, dynamic> data) async {
    final r = await _api.post(ApiConstants.prescriptions, data: data);
    return PrescriptionModel.fromJson(r.data);
  }
}
