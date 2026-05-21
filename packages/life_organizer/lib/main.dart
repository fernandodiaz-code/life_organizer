import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'navigation/main_shell.dart';
import 'screens/auth/login_screen.dart';

Future<void> main() async {
  // Punto de entrada real de Flutter: antes de usar plugins o servicios
  // nativos, hay que asegurar que el binding este inicializado.
  WidgetsFlutterBinding.ensureInitialized();

  // Locale española para intl (fechas en español)
  await initializeDateFormatting('es', null);

  if (AppConstants.supabaseUrl.isNotEmpty &&
      AppConstants.supabaseAnonKey.isNotEmpty) {
    try {
      // Supabase solo se inicializa cuando la app recibe credenciales por
      // --dart-define. Si se llama Supabase.instance sin esto, Flutter muestra
      // una pantalla roja de assertion.
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );
      debugPrint('[Supabase] Inicializado correctamente.');
    } catch (e, stack) {
      debugPrint('[Supabase] ERROR al inicializar: $e');
      debugPrint('[Supabase] StackTrace: $stack');
    }
  } else {
    debugPrint('[Supabase] Configuración no definida. Usar --dart-define.');
  }

  // Barra de estado transparente
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const LifeOrganizerApp());
}

class LifeOrganizerApp extends StatelessWidget {
  const LifeOrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp define configuracion global de UI: tema, titulo y primera
    // pantalla. AuthGate decide despues si entra al login o a la app.
    return MaterialApp(
      title: 'Life Organizer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AuthGate(),
    );
  }
}

/// Escucha cambios de autenticación y decide qué pantalla mostrar.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // En Sprint 1 la app debe poder abrir aunque las credenciales vivan en
    // Cloudflare y no existan localmente. Por eso no tocamos Supabase.instance
    // hasta confirmar que esta configurado.
    if (AppConstants.supabaseUrl.isEmpty ||
        AppConstants.supabaseAnonKey.isEmpty) {
      return const LoginScreen(authEnabled: false);
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Usa la sesión actual si el stream aún no emitió
        final session = snapshot.hasData
            ? snapshot.data!.session
            : Supabase.instance.client.auth.currentSession;

        // Splash mientras no hay datos del stream y tampoco sesión en caché
        if (!snapshot.hasData && session == null) {
          return const _SplashScreen();
        }

        return session != null ? const MainShell() : const LoginScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy, color: AppColors.cyan, size: 64),
            SizedBox(height: 20),
            CircularProgressIndicator(color: AppColors.cyan, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
