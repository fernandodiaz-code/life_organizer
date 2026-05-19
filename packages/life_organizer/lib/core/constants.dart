import 'package:life_core/core.dart';

class AppConstants {
  static const supabaseUrl = CoreEnvironment.supabaseUrl;
  static const supabaseAnonKey = CoreEnvironment.supabaseAnonKey;
  static const n8nWebhookUrl = CoreEnvironment.n8nWebhookUrl;

  // Para mostrar en UI (con tilde, capitalizado)
  static const diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static const diasCortos = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  // Para comparar con la BD (minúsculas, sin tilde)
  static const diasDb = [
    'lunes', 'martes', 'miercoles', 'jueves',
    'viernes', 'sabado', 'domingo',
  ];

  // Texto bonito para mostrar ("Miércoles")
  static String diaDeHoy() => diasSemana[DateTime.now().weekday - 1];

  // Valor normalizado para queries a Supabase ("miercoles")
  static String diaDeHoyDb() => diasDb[DateTime.now().weekday - 1];
}
