import 'package:equatable/equatable.dart';

class PatientModel extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String middleName;
  final String birthDate;
  final String phone;
  final String email;
  final String insuranceNo;
  final String bloodGroup;
  final String rhFactor;
  final List<String> allergies;
  final String? primaryDoctorId;
  final String createdAt;

  const PatientModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName = '',
    required this.birthDate,
    this.phone = '',
    this.email = '',
    this.insuranceNo = '',
    this.bloodGroup = '',
    this.rhFactor = '',
    this.allergies = const [],
    this.primaryDoctorId,
    this.createdAt = '',
  });

  String get fullName => '$lastName $firstName${middleName.isNotEmpty ? ' $middleName' : ''}';
  String get shortFullName => '$lastName $firstName';

  int get age {
    final birth = DateTime.tryParse(birthDate);
    if (birth == null) return 0;
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) age--;
    return age;
  }

  String get bloodGroupFull => '$bloodGroup${rhFactor.isNotEmpty ? ' $rhFactor' : ''}';

  factory PatientModel.fromJson(Map<String, dynamic> json) => PatientModel(
        id: json['id'] ?? '',
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        middleName: json['middleName'] ?? '',
        birthDate: json['birthDate'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'] ?? '',
        insuranceNo: json['insuranceNo'] ?? '',
        bloodGroup: json['bloodGroup'] ?? '',
        rhFactor: json['rhFactor'] ?? '',
        allergies: List<String>.from(json['allergies'] ?? []),
        primaryDoctorId: json['primaryDoctorId'],
        createdAt: json['createdAt'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'middleName': middleName,
        'birthDate': birthDate,
        'phone': phone,
        'email': email,
        'insuranceNo': insuranceNo,
        'bloodGroup': bloodGroup,
        'rhFactor': rhFactor,
        'allergies': allergies,
        'primaryDoctorId': primaryDoctorId,
      };

  @override
  List<Object?> get props => [id];
}
