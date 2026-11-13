import 'package:dio/dio.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';

class AuthDatasource {
  final Dio _dio;

  AuthDatasource(DioClient client) : _dio = client.dio;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.authLogin,
      data: {'email': email, 'password': password},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _dio.post<dynamic>(ApiEndpoints.authRegister, data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _dio.get<dynamic>(ApiEndpoints.authMe);
    return Map<String, dynamic>.from(response.data as Map);
  }
}
