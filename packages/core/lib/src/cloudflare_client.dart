import 'dart:convert';

import 'package:http/http.dart' as http;

import 'core_environment.dart';

class CloudflareClient {
  // Se acepta http.Client externo para poder testear el cliente sin hacer
  // llamadas reales a internet.
  CloudflareClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> payload, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    // Todas las llamadas salen hacia Cloudflare, no directo a servicios con
    // credenciales sensibles. El Worker decide que hacer con el payload.
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

    // Algunos endpoints validos pueden responder 204 o body vacio.
    if (response.body.trim().isEmpty) {
      return const {};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    // Si el Worker devuelve una lista/string/numero, lo envolvemos para que el
    // contrato del cliente siga siendo Map<String, dynamic>.
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
