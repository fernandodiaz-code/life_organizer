import 'dart:convert';

import 'package:http/http.dart' as http;

import 'core_environment.dart';

class CloudflareClient {
  CloudflareClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> payload, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final response = await _httpClient
        .post(
          CoreEnvironment.cloudflareUri(path),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CloudflareException(response.statusCode, response.body);
    }

    if (response.body.trim().isEmpty) {
      return const {};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {'data': decoded};
  }
}

class CloudflareException implements Exception {
  const CloudflareException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'CloudflareException($statusCode): $body';
}

