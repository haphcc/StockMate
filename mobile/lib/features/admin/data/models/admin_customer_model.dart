import 'package:equatable/equatable.dart';
import 'admin_account_model.dart';

class AdminCustomerModel extends Equatable {
  final int customerId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role; // CUSTOMER | ADMIN
  final String status; // PENDING | ACTIVE | LOCKED | CLOSED
  final String? dateOfBirth;
  final String? idCardNumber;
  final String? address;
  final String? avatarUrl;
  final String createdAt;
  final int accountsCount;
  final List<AdminAccountModel> accounts; // chỉ có khi lấy chi tiết

  const AdminCustomerModel({
    required this.customerId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.status,
    this.dateOfBirth,
    this.idCardNumber,
    this.address,
    this.avatarUrl,
    this.createdAt = '',
    this.accountsCount = 0,
    this.accounts = const [],
  });

  bool get isAdmin => role == 'ADMIN';

  factory AdminCustomerModel.fromJson(Map<String, dynamic> json) {
    final rawAccounts = json['accounts'] as List<dynamic>? ?? [];
    return AdminCustomerModel(
      customerId: json['customer_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      role: json['role'] ?? 'CUSTOMER',
      status: json['status'] ?? 'ACTIVE',
      dateOfBirth: json['date_of_birth'],
      idCardNumber: json['id_card_number'],
      address: json['address'],
      avatarUrl: json['avatar_url'],
      createdAt: json['created_at']?.toString() ?? '',
      accountsCount: json['accounts_count'] ?? 0,
      accounts: rawAccounts
          .map((e) => AdminAccountModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  AdminCustomerModel copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? role,
    String? status,
    String? dateOfBirth,
    String? idCardNumber,
    String? address,
    String? avatarUrl,
    int? accountsCount,
    List<AdminAccountModel>? accounts,
  }) {
    return AdminCustomerModel(
      customerId: customerId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      status: status ?? this.status,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      accountsCount: accountsCount ?? this.accountsCount,
      accounts: accounts ?? this.accounts,
    );
  }

  @override
  List<Object?> get props => [
        customerId,
        fullName,
        email,
        phoneNumber,
        role,
        status,
        dateOfBirth,
        idCardNumber,
        address,
        avatarUrl,
        createdAt,
        accountsCount,
        accounts,
      ];
}