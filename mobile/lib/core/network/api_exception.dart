import 'package:dio/dio.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String code;
  final String message;
  final Map<String, dynamic> details;

  const ApiException({
    this.statusCode,
    required this.code,
    required this.message,
    this.details = const {},
  });

  factory ApiException.fromDio(DioException error) {
    final body = error.response?.data;
    if (body is Map && body['error'] is Map) {
      final raw = body['error'] as Map;
      return ApiException(
        statusCode: error.response?.statusCode,
        code: raw['code']?.toString() ?? 'HTTP_ERROR',
        message: raw['message']?.toString() ?? 'Có lỗi xảy ra.',
        details: raw['details'] is Map
            ? Map<String, dynamic>.from(raw['details'] as Map)
            : const {},
      );
    }
    return ApiException(
      statusCode: error.response?.statusCode,
      code: error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout
          ? 'NETWORK_ERROR'
          : 'HTTP_ERROR',
      message: error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout
          ? 'Không kết nối được máy chủ.'
          : 'Yêu cầu thất bại (${error.response?.statusCode ?? 'không rõ'}).',
    );
  }

  @override
  String toString() => message;
}
