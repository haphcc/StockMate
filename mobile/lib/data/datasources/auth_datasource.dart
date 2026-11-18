import 'package:dio/dio.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';

class AuthDatasource {
  final Dio _dio;

  AuthDatasource(DioClient client) : _dio = client.dio;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.authLogin,
        data: {'email': email, 'password': password},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> googleLogin({
    String? idToken,
    String? accessToken,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (idToken != null && idToken.isNotEmpty) 'id_token': idToken,
        if (accessToken != null && accessToken.isNotEmpty)
          'access_token': accessToken,
      };
      final response = await _dio.post<dynamic>(
        ApiEndpoints.authGoogle,
        data: payload,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.authRegister,
        data: data,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> me() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.authMe);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put<dynamic>(
        ApiEndpoints.authMe,
        data: data,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> changePassword({
    String? oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        ApiEndpoints.authPassword,
        data: {
          if (oldPassword != null && oldPassword.isNotEmpty)
            'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
