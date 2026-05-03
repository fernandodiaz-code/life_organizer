class AppConstants {
  static const supabaseUrl = 'https://yxemyoisejhdoqtxjzzt.supabase.co';

  // TODO: hardcodeado temporalmente — revertir a --dart-define cuando funcione en Android
  static const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl4ZW15b2lzZWpoZG9xdHhqenp0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0NDUwNDAsImV4cCI6MjA5MTAyMTA0MH0.p6gdoYWuu_SDzWgpgPeiDEtxNUYYmOnmP4Zxoe4eZ20';

  // TODO: hardcodeado temporalmente — revertir a --dart-define cuando funcione en Android
  static const n8nWebhookUrl = 'https://mi-vida-api.herramientafertom.workers.dev/agente';

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
