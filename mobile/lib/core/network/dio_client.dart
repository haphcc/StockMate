import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_endpoints.dart';

class DioClient {
  late final Dio dio;
  final TokenStorage tokenStorage;
  Future<void>? _refreshing;

  DioClient({TokenStorage? tokenStorage}) : tokenStorage = tokenStorage ?? const TokenStorage() {
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
        if (options.extra['skipAuth'] != true) {
          final token = await this.tokenStorage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        final request = e.requestOptions;
        final canRefresh = e.response?.statusCode == 401 &&
            request.extra['retried'] != true &&
            request.path != ApiEndpoints.authRefresh &&
            request.extra['skipRefresh'] != true;
        if (canRefresh) {
          try {
            await _refreshAccessToken();
            request.extra['retried'] = true;
            return handler.resolve(await dio.fetch(request));
          } catch (_) {
            await this.tokenStorage.clear();
          }
        }
        return handler.next(e);
      },
    ));
  }

  Future<void> _refreshAccessToken() {
    final active = _refreshing;
    if (active != null) return active;
    final future = _performRefresh();
    _refreshing = future;
    future.then((_) {
      if (identical(_refreshing, future)) _refreshing = null;
    }, onError: (Object _, StackTrace __) {
      if (identical(_refreshing, future)) _refreshing = null;
    });
    return future;
  }

  Future<void> _performRefresh() async {
    final refresh = await tokenStorage.readRefreshToken();
    if (refresh == null || refresh.isEmpty) throw StateError('Missing refresh token');
    final client = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
    final response = await client.post<dynamic>(
      ApiEndpoints.authRefresh,
      data: {'refresh_token': refresh},
    );
    final body = response.data;
    if (body is! Map || body['access_token'] == null || body['refresh_token'] == null) {
      throw StateError('Invalid refresh response');
    }
    await tokenStorage.saveTokens(
      accessToken: body['access_token'].toString(),
      refreshToken: body['refresh_token'].toString(),
    );
  }
}
