import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String role;
  final String firstName;
  final String lastName;

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
  });

  String get fullName => '$lastName $firstName';
  String get shortName => '$lastName ${firstName[0]}.';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        email: json['email'],
        role: json['role'],
        firstName: json['firstName'],
        lastName: json['lastName'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        'firstName': firstName,
        'lastName': lastName,
      };

  @override
  List<Object?> get props => [id, email, role];
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  AuthResponse({required this.accessToken, required this.refreshToken, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'],
        refreshToken: json['refreshToken'],
        user: UserModel.fromJson(json['user']),
      );
}
