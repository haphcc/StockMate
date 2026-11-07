import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? avatarUrl;
  final String status;
  final String role;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.avatarUrl,
    required this.status,
    this.role = 'CUSTOMER',
  });

  bool get isAdmin => role == 'ADMIN';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['customer_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      avatarUrl: json['avatar_url'],
      status: json['status'] ?? 'ACTIVE',
      role: json['role'] ?? 'CUSTOMER',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'status': status,
      'role': role,
    };
  }

  @override
  List<Object?> get props =>
      [id, fullName, email, phoneNumber, avatarUrl, status, role];
}