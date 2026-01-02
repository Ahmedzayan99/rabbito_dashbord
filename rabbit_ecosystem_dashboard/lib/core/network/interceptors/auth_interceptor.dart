import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final String? Function() getToken;

  AuthInterceptor(this.getToken);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired, could trigger logout here
      // For now, just pass the error
    }
    handler.next(err);
  }
}

