import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../providers/app_provider.dart';
import '../themes/app_theme.dart';
import 'main_nav_screen.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        // Login
        await AuthService.instance.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          // Verificar si el usuario ya tiene un perfil
          final hasProfile = await FirestoreService.instance.hasUserProfile();

          if (hasProfile) {
            // Si tiene perfil, cargar datos y navegar al home
            final appProvider =
                Provider.of<AppProvider>(context, listen: false);
            await appProvider.loadInitialData();
            _navigateToHome();
          } else {
            // Si no tiene perfil, ir a configuración de perfil
            _navigateToProfileSetup();
          }
        }
      } else {
        // Registro
        await AuthService.instance.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          // Extraer sugerencia de nombre del email
          final emailPart = _emailController.text.trim().split('@').first;
          final nameSuggestion = _extractNameFromEmail(emailPart);

          // Navegar a configuración de perfil con sugerencia
          _navigateToProfileSetup(nameSuggestion: nameSuggestion);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _extractNameFromEmail(String emailPart) {
    // Reemplazar puntos, guiones y guiones bajos por espacios
    String name = emailPart.replaceAll(RegExp(r'[._-]'), ' ');

    // Capitalizar cada palabra
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void _navigateToProfileSetup({String? nameSuggestion}) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProfileSetupScreen(emailSuggestion: nameSuggestion),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
            CurveTween(curve: Curves.easeInOut),
          );
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
            CurveTween(curve: Curves.easeInOut),
          );
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo/Icono
                      Hero(
                        tag: 'logo',
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withAlpha(50),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.savings_rounded,
                            size: 45,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Título
                      Text(
                        'Ahorros',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                      ),
                      const SizedBox(height: 24),

                      // Card de Login/Registro
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Text(
                                _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isLogin
                                    ? 'Ingresa tus credenciales para continuar'
                                    : 'Registra una cuenta para comenzar',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary.withAlpha(180),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Campo Email
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.backgroundColor,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Email no válido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Campo Contraseña
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.backgroundColor,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu contraseña';
                                  }
                                  if (value.length < 6) {
                                    return 'La contraseña debe tener al menos 6 caracteres';
                                  }
                                  return null;
                                },
                              ),

                              // Mensaje de error
                              if (_errorMessage != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorColor.withAlpha(20),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: AppTheme.errorColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: AppTheme.errorColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 24),

                              // Botón principal
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Text(
                                          _isLogin
                                              ? 'Iniciar Sesión'
                                              : 'Registrarse',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Botón cambiar modo
                              TextButton(
                                onPressed: _toggleMode,
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: _isLogin
                                            ? '¿No tienes una cuenta? '
                                            : '¿Ya tienes una cuenta? ',
                                      ),
                                      TextSpan(
                                        text: _isLogin
                                            ? 'Regístrate'
                                            : 'Inicia Sesión',
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Footer
                      Text(
                        'Tu información está segura con Firebase',
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
