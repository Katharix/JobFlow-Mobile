import 'dart:convert';

import 'package:http/http.dart' as http;

import '../state/app_session.dart';

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri buildUri(String path) {
    return Uri.parse(baseUrl + path);
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (AppSession.isAuthenticated) {
      headers['Authorization'] = 'Bearer ${AppSession.accessToken}';
    }
    return headers;
  }

  Map<String, String> _buildAuthHeaders() {
    final headers = <String, String>{};
    if (AppSession.isAuthenticated) {
      headers['Authorization'] = 'Bearer ${AppSession.accessToken}';
    }
    return headers;
  }

  Future<http.Response> get(String path) {
    return _client.get(
      buildUri(path),
      headers: _buildHeaders(),
    );
  }

  Future<http.Response> postJson(String path, Map<String, dynamic> body) {
    return _client.post(
      buildUri(path),
      headers: _buildHeaders(),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> putJson(String path, Map<String, dynamic> body) {
    return _client.put(
      buildUri(path),
      headers: _buildHeaders(),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> postMultipart(
    String path, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    final request = http.MultipartRequest('POST', buildUri(path));
    request.headers.addAll(_buildAuthHeaders());
    if (fields != null) {
      request.fields.addAll(fields);
    }
    if (files != null) {
      request.files.addAll(files);
    }

    final streamed = await _client.send(request);
    return http.Response.fromStream(streamed);
  }
}
