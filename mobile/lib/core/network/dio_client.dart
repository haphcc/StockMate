import 'package:dio/dio.dart';
import '../config/app_config.dart';

class DioClient {
  late final Dio dio;

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // TODO: Get token from secure storage and add to header
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // TODO: Handle 401 Unauthorized to refresh token
        return handler.next(e);
      },
    ));
  }
}
