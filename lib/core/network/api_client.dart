import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

const apiBaseUrl = String.fromEnvironment(
  'SAFEFLOW_API_BASE_URL',
  defaultValue:
      'https://safeflow-api-chbaa6fxbbdja6b2.southeastasia-01.azurewebsites.net/api/v1/',
);

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.requestId});

  final String message;
  final int? statusCode;
  final String? requestId;

  @override
  String toString() => message;
}

/// Shared REST client. It owns the bearer header and the persisted session,
/// while feature repositories define their own endpoint contracts.
class ApiClient {
  ApiClient({SharedPreferences? preferences}) : _preferences = preferences;

  SharedPreferences? _preferences;
  String? _token;
  DateTime? _expiresAt;
  final HttpClient _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15);

  String? get token => _token;
  DateTime? get expiresAt => _expiresAt;
  bool get hasValidSession =>
      _token != null &&
      _expiresAt != null &&
      _expiresAt!.isAfter(DateTime.now());

  Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
    _token = _preferences!.getString('session.token');
    final expiry = _preferences!.getString('session.expiresAt');
    _expiresAt = expiry == null ? null : DateTime.tryParse(expiry)?.toLocal();
    if (!hasValidSession) await clearSession();
  }

  Future<void> saveSession(String token, DateTime expiry) async {
    _preferences ??= await SharedPreferences.getInstance();
    _token = token;
    _expiresAt = expiry.toLocal();
    await _preferences!.setString('session.token', token);
    await _preferences!.setString(
      'session.expiresAt',
      expiry.toUtc().toIso8601String(),
    );
  }

  Future<void> clearSession() async {
    _preferences ??= await SharedPreferences.getInstance();
    _token = null;
    _expiresAt = null;
    await _preferences!.remove('session.token');
    await _preferences!.remove('session.expiresAt');
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      request('GET', path, query: query);

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      request('POST', path, body: body);

  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      request('PUT', path, body: body);

  Future<dynamic> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$path').replace(queryParameters: query);
    try {
      final request = await _http.openUrl(method, uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final currentToken = hasValidSession ? _token : null;
      if (currentToken != null) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $currentToken',
        );
      }
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final payload = await utf8.decoder.bind(response).join();
      dynamic decoded;
      if (payload.isNotEmpty) {
        try {
          decoded = jsonDecode(payload);
        } on FormatException {
          decoded = payload;
        }
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401) await clearSession();
        final error = decoded is Map ? decoded : const <String, dynamic>{};
        final serverMessage = _firstNonEmpty([
          error['message'],
          error['error'],
          if (response.statusCode < 500) error['detail'],
          if (response.statusCode < 500) error['title'],
        ]);
        final requestId = _firstNonEmpty([
          response.headers.value('x-correlation-id'),
          response.headers.value('request-id'),
          response.headers.value('x-ms-request-id'),
        ]);
        final message =
            serverMessage ??
            (response.statusCode >= 500
                ? 'El servidor de SafeFlow tuvo un error interno (${response.statusCode}). Tu solicitud no pudo completarse. Inténtalo más tarde.'
                : 'No se pudo completar la solicitud (${response.statusCode}).');
        final messageWithReference = requestId == null
            ? message
            : '$message Referencia: $requestId.';
        throw ApiException(
          messageWithReference,
          statusCode: response.statusCode,
          requestId: requestId,
        );
      }
      return decoded;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'La solicitud tardó demasiado. Revisa tu conexión e intenta nuevamente.',
      );
    } on SocketException {
      throw const ApiException(
        'No se pudo conectar con SafeFlow. Revisa tu conexión.',
      );
    } on HttpException {
      throw const ApiException('No se pudo conectar con SafeFlow.');
    }
  }

  String? _firstNonEmpty(Iterable<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}
