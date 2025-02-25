import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shop_app/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Define los colores principales
  static const primaryBlue = Color(0xFF1E88E5);
  static const secondaryBlue = Color(0xFF64B5F6);
  static const accentBlue = Color(0xFFBBDEFB);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text;
        final password = _passwordController.text;

        final response = await http.post(
          Uri.parse('https://farmaciaserver-ashen.vercel.app/api/v1/ingresar'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'email': email,
            'password': password,
          }),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final userData = responseData['user'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userRole', userData['rol']);
          await prefs.setString('userName', userData['nombre']);
          await prefs.setInt('userId', userData['id']);

          if (mounted) {
            _showSuccessMessage('¡Bienvenido, ${userData['nombre']}!');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        } else {
          _showErrorMessage('Credenciales incorrectas');
        }
      } catch (e) {
        _showErrorMessage('Error de conexión. Intenta más tarde.');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text('¿Salir de la aplicación?'),
            content: const Text('¿Estás seguro de que quieres salir?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Salir'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;
    final padding = isSmallScreen ? 16.0 : 24.0;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Colors.white,
                accentBlue.withOpacity(0.3),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Container
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/cinnamorrollnurse.png',
                            width: isSmallScreen ? 100 : 120,
                            height: isSmallScreen ? 100 : 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image: $error');
                              return Icon(
                                Icons.error_outline,
                                size: isSmallScreen ? 70 : 85,
                                color: primaryBlue,
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: padding),

                      // Título Principal
                      Text(
                        'Farmacia Cinnamoroll',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 28 : 32,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cuidando tu salud con una sonrisa',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          color: secondaryBlue,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: padding * 1.5),

                      // Formulario Card
                      Card(
                        elevation: 10,
                        shadowColor: primaryBlue.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Container(
                          width: min(size.width * 0.9, 400),
                          padding: EdgeInsets.all(padding * 1.2),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: _emailController,
                                  icon: Icons.email_outlined,
                                  label: 'Correo electrónico',
                                  hint: 'ejemplo@correo.com',
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                SizedBox(height: padding),
                                _buildTextField(
                                  controller: _passwordController,
                                  icon: Icons.lock_outline,
                                  label: 'Contraseña',
                                  hint: '••••••••',
                                  obscureText: !_isPasswordVisible,
                                  focusNode: _passwordFocusNode,
                                  suffixIcon: _buildPasswordVisibilityToggle(),
                                ),
                                SizedBox(height: padding * 1.5),
                                _buildLoginButton(isSmallScreen),
                                SizedBox(height: padding),
                                TextButton(
                                  onPressed: () {
                                    // Implementar recuperación de contraseña
                                  },
                                  child: const Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: TextStyle(
                                      color: secondaryBlue,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    FocusNode? focusNode,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: !_isLoading,
      style: const TextStyle(fontSize: 16),
      // Añadir el manejador de teclas
      onFieldSubmitted: (value) {
        if (focusNode == _passwordFocusNode) {
          _login();
        }
      },
      // Configurar la acción del teclado
      textInputAction: focusNode == _passwordFocusNode
          ? TextInputAction.done
          : TextInputAction.next,
      // Si no es el campo de contraseña, mover al siguiente campo
      onEditingComplete: focusNode == _passwordFocusNode
          ? () => _login()
          : () => FocusScope.of(context).nextFocus(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryBlue),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: accentBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: secondaryBlue),
        floatingLabelStyle: const TextStyle(color: primaryBlue),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Este campo es requerido';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordVisibilityToggle() {
    return IconButton(
      icon: Icon(
        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
        color: secondaryBlue,
      ),
      onPressed: () {
        setState(() {
          _isPasswordVisible = !_isPasswordVisible;
        });
      },
    );
  }

  Widget _buildLoginButton(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 50 : 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [primaryBlue, secondaryBlue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Iniciar sesión',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  double min(double a, double b) => a < b ? a : b;
}
