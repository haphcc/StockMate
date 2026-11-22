import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? avatarUrl;
  final String status;
  final String role;
  final String authProvider;
  final bool hasPassword;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.avatarUrl,
    required this.status,
    this.role = 'CUSTOMER',
    this.authProvider = 'LOCAL',
    this.hasPassword = true,
  });

  bool get isAdmin => role == 'ADMIN';
  bool get isGoogleAccount => authProvider.toUpperCase() == 'GOOGLE';
  bool get hasPlaceholderPhone => phoneNumber.startsWith('G');
  String get displayPhoneNumber =>
      hasPlaceholderPhone ? 'Chưa cập nhật' : phoneNumber;

  UserModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? status,
    String? role,
    String? authProvider,
    bool? hasPassword,
  }) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      role: role ?? this.role,
      authProvider: authProvider ?? this.authProvider,
      hasPassword: hasPassword ?? this.hasPassword,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['customer_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      avatarUrl: json['avatar_url'],
      status: json['status'] ?? 'ACTIVE',
      role: json['role'] ?? 'CUSTOMER',
      authProvider: json['auth_provider'] ?? 'LOCAL',
      hasPassword: json['has_password'] ?? true,
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
      'auth_provider': authProvider,
      'has_password': hasPassword,
    };
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        phoneNumber,
        avatarUrl,
        status,
        role,
        authProvider,
        hasPassword,
      ];
}
