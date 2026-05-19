import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class JarvisService {
  static Future<String> sendMessage(String message, String userId) async {
    if (AppConstants.n8nWebhookUrl.isEmpty) {
      return 'Jarvis no está configurado. Falta N8N_WEBHOOK_URL.';
    }

    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.n8nWebhookUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message, 'user_id': userId}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = response.body.trim();
        if (body.isEmpty) return 'Recibido.';

        // n8n puede devolver JSON o texto plano
        try {
          final data = jsonDecode(body);
          if (data is Map) {
            return (data['response'] ??
                    data['message'] ??
                    data['text'] ??
                    data['output'] ??
                    data['answer'] ??
                    'Entendido.')
                .toString();
          }
          if (data is List && data.isNotEmpty) {
            final first = data.first;
            if (first is Map) {
              return (first['response'] ??
                      first['message'] ??
                      first['text'] ??
                      first['output'] ??
                      'Entendido.')
                  .toString();
            }
          }
          return data.toString();
        } catch (_) {
          return body;
        }
      }
      return 'Error del servidor (${response.statusCode}).';
    } on Exception {
      return 'No pude conectar con Jarvis. Verifica tu webhook.';
    }
  }
}
