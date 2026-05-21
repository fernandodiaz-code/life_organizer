import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authEnabled = true});

  // Permite mostrar la pantalla de login aunque Supabase no este configurado.
  // Asi la app no rompe durante desarrollo o cuando el backend real va por
  // Cloudflare.
  final bool authEnabled;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Primero se validan campos de UI. Si esto falla, no se toca la red.
    if (!_formKey.currentState!.validate()) return;

    // Guard de arquitectura: si no hay Supabase inicializado, no podemos usar
    // Supabase.instance. Este fue el origen del error rojo visto en Sprint 1.
    if (!widget.authEnabled) {
      _showSnack('Configura Supabase con --dart-define para iniciar sesión.');
      return;
    }

    setState(() => _loading = true);
    try {
      // A partir de este punto authEnabled garantiza que Supabase fue
      // inicializado por main.dart.
      final auth = Supabase.instance.client.auth;
      if (_isSignUp) {
        await auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
        if (mounted) {
          _showSnack(
            'Cuenta creada. Revisa tu correo para confirmar.',
            success: true,
          );
        }
      } else {
        await auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
      }
    } on AuthException catch (e) {
      if (mounted) _showSnack(e.message);
    } catch (e) {
      if (mounted) _showSnack('Error inesperado.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    // mounted evita intentar pintar mensajes cuando la pantalla ya fue
    // desmontada por navegacion o cambios de estado async.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.green : AppColors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Header
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cyanGlow,
                      border: Border.all(color: AppColors.cyan, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: AppColors.cyan,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Life Organizer',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 28,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isSignUp ? 'Crea tu cuenta' : 'Bienvenido de vuelta',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Email
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: AppColors.textMuted,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa tu correo';
                      if (!v.contains('@')) return 'Correo no válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.textMuted,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Submit
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(_isSignUp ? 'Crear cuenta' : 'Iniciar sesión'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Toggle sign up / sign in
                  TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? '¿Ya tienes cuenta? Inicia sesión'
                          : '¿No tienes cuenta? Crear una',
                      style: const TextStyle(color: AppColors.cyan),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
