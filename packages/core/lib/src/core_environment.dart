class CoreEnvironment {
  // String.fromEnvironment lee valores entregados por --dart-define en tiempo
  // de compilacion/ejecucion. No son variables leidas desde un archivo .env.
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const n8nWebhookUrl = String.fromEnvironment('N8N_WEBHOOK_URL');
  static const cloudflareBaseUrl = String.fromEnvironment(
    'CLOUDFLARE_BASE_URL',
  );

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static Uri cloudflareUri(String path) {
    if (cloudflareBaseUrl.isEmpty) {
      throw StateError('CLOUDFLARE_BASE_URL is not configured.');
    }

    // Permite llamar con "ruta" o "/ruta" sin duplicar barras al resolver URL.
    final base = Uri.parse(cloudflareBaseUrl);
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return base.resolve(normalizedPath);
  }
}
