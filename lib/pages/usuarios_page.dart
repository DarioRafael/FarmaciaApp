import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}//

class _UsuariosPageState extends State<UsuariosPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _usuariosActivos = [];
  List<Map<String, dynamic>> _usuariosInactivos = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Definición de la paleta de colores
  final Color _primaryColor = const Color(0xFF1A73E8);
  final Color _accentColor = const Color(0xFF4285F4);
  final Color _backgroundColor = Colors.white;
  final Color _cardColor = Colors.white;
  final Color _activeColor = const Color(0xFF34A853);
  final Color _inactiveColor = const Color(0xFFEA4335);
  final Color _textColor = const Color(0xFF202124);
  final Color _secondaryTextColor = const Color(0xFF5F6368);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarUsuarios();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuarios() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await http.get(
        Uri.parse('https://modelo-server.vercel.app/api/v1/trabajadores'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _usuariosActivos = data
              .where((user) => user['estado'] == 'activo')
              .map((user) => user as Map<String, dynamic>)
              .toList();
          _usuariosInactivos = data
              .where((user) => user['estado'] == 'inactivo')
              .map((user) => user as Map<String, dynamic>)
              .toList();

          _usuariosActivos.sort((a, b) => a['rol'] == 'propietario' ? -1 : 1);
          _usuariosInactivos.sort((a, b) => a['rol'] == 'propietario' ? -1 : 1);

          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error al cargar usuarios: ${response.statusCode}';
          _isLoading = false;
        });
        print('Error al cargar usuarios: ${response.statusCode}');
        print('Respuesta: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión';
        _isLoading = false;
      });
      print('Error de conexión al cargar usuarios: $e');
    }
  }

  Future<void> _cambiarEstadoUsuario(dynamic id, String nuevoEstado) async {
    try {
      final response = await http.patch(
        Uri.parse('https://modelo-server.vercel.app/api/v1/trabajadores/$id/estado'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': nuevoEstado}),
      );

      if (response.statusCode == 200) {
        _mostrarSnackbar(
          nuevoEstado == 'activo' ? 'Usuario activado exitosamente' : 'Usuario desactivado exitosamente',
          nuevoEstado == 'activo' ? _activeColor : _inactiveColor,
        );
        _cargarUsuarios();
      } else {
        _mostrarSnackbar(
          'Error al cambiar estado del usuario: ${response.statusCode}',
          Colors.red,
        );
        print('Error al cambiar estado del usuario: ${response.statusCode}');
        print('Respuesta: ${response.body}');
      }
    } catch (e) {
      _mostrarSnackbar('Error de conexión', Colors.red);
      print('Error de conexión al cambiar estado del usuario: $e');
    }
  }

  Future<void> _eliminarUsuario(dynamic id) async {
    try {
      final response = await http.delete(
        Uri.parse('https://modelo-server.vercel.app/api/v1/trabajadores/$id/eliminar'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _mostrarSnackbar('Usuario eliminado permanentemente', _inactiveColor);
        _cargarUsuarios();
      } else {
        _mostrarSnackbar('Error al eliminar usuario: ${response.statusCode}', Colors.red);
        print('Error al eliminar usuario: ${response.statusCode}');
        print('Respuesta: ${response.body}');
      }
    } catch (e) {
      _mostrarSnackbar('Error de conexión', Colors.red);
      print('Error de conexión al eliminar usuario: $e');
    }
  }

  void _mostrarSnackbar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(color == _activeColor ? Icons.check_circle : Icons.info_outline, color: Colors.white),
            const SizedBox(width: 10),
            Text(mensaje, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _mostrarDialogoCambiarEstado(Map<String, dynamic> usuario, String nuevoEstado) {
    final bool activar = nuevoEstado == 'activo';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Icon(
              activar ? Icons.person_add : Icons.person_off,
              size: 60,
              color: activar ? _activeColor : _inactiveColor,
            ),
            const SizedBox(height: 20),
            Text(
              activar ? 'Activar Usuario' : 'Desactivar Usuario',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '¿Estás seguro de que deseas ${activar ? 'activar' : 'desactivar'} a ${usuario['nombre']}?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: _secondaryTextColor,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: _primaryColor),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.poppins(
                        color: _primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      var id = usuario['id'];
                      if (id == null) {
                        _mostrarSnackbar('Error: ID del usuario no encontrado', Colors.red);
                        return;
                      }
                      _cambiarEstadoUsuario(id, nuevoEstado);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activar ? _activeColor : _inactiveColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      activar ? 'Activar' : 'Desactivar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoEliminarPermanente(Map<String, dynamic> usuario) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Icon(
              Icons.delete_forever,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              'Eliminar Permanentemente',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '¿Estás seguro de que deseas eliminar permanentemente a ${usuario['nombre']}?\n\nEsta acción no se puede deshacer.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: _secondaryTextColor,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: _primaryColor),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.poppins(
                        color: _primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      var id = usuario['id'];
                      if (id == null) {
                        _mostrarSnackbar('Error: ID del usuario no encontrado', Colors.red);
                        return;
                      }
                      _eliminarUsuario(id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Eliminar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoAgregarUsuario() async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final correoController = TextEditingController();
    final passwordController = TextEditingController();
    String rolSeleccionado = 'empleado';
    bool obscurePassword = true;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'Agregar Nuevo Usuario',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildInputField(
                    controller: nombreController,
                    label: 'Nombre Completo',
                    icon: Icons.person,
                    validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 15),
                  _buildInputField(
                    controller: correoController,
                    label: 'Correo Electrónico',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Campo requerido';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                        return 'Correo inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      labelStyle: GoogleFonts.poppins(color: _secondaryTextColor),
                      hintText: 'Ingrese la contraseña',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      prefixIcon: Icon(Icons.lock, color: _primaryColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: _secondaryTextColor,
                        ),
                        onPressed: () => setState(() => obscurePassword = !obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _primaryColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    style: GoogleFonts.poppins(color: _textColor),
                    validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Rol del Usuario',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.grey.shade50,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonFormField<String>(
                      value: rolSeleccionado,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.assignment_ind),
                      ),
                      style: GoogleFonts.poppins(
                        color: _textColor,
                        fontSize: 16,
                      ),
                      dropdownColor: _backgroundColor,
                      items: [
                        _buildDropdownItem('propietario', 'Propietario', Colors.blue.shade700),
                        _buildDropdownItem('supervisor', 'Supervisor', Colors.green.shade700),
                        _buildDropdownItem('empleado', 'Empleado', _primaryColor),
                      ],
                      onChanged: (value) {
                        rolSeleccionado = value!;
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            Navigator.pop(context); // Cerrar el diálogo
                            // Mostrar indicador de carga
                            _mostrarIndicadorProcesando();

                            final response = await http.post(
                              Uri.parse('https://modelo-server.vercel.app/api/v1/registrar'),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'nombre': nombreController.text,
                                'correo': correoController.text,
                                'password': passwordController.text,
                                'rol': rolSeleccionado,
                              }),
                            );

                            // Ocultar indicador de carga
                            Navigator.of(context, rootNavigator: true).pop();

                            if (response.statusCode == 201) {
                              _mostrarSnackbar('Usuario agregado con éxito', _activeColor);
                              _cargarUsuarios();
                            } else {
                              _mostrarSnackbar('Error al agregar usuario: ${response.statusCode}', Colors.red);
                              print('Error al agregar usuario: ${response.statusCode}');
                              print('Respuesta: ${response.body}');
                            }
                          } catch (e) {
                            // Ocultar indicador de carga si hay error
                            Navigator.of(context, rootNavigator: true).pop();
                            _mostrarSnackbar('Error de conexión', Colors.red);
                            print('Error de conexión al agregar usuario: $e');
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Agregar Usuario',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
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
    );
  }

  void _mostrarIndicadorProcesando() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Procesando...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: _secondaryTextColor),
        hintText: 'Ingrese $label',
        hintStyle: GoogleFonts.poppins(color: Colors.grey),
        prefixIcon: Icon(icon, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      style: GoogleFonts.poppins(color: _textColor),
      validator: validator,
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(String value, String text, Color color) {
    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            value == 'propietario'
                ? Icons.admin_panel_settings
                : value == 'supervisor'
                ? Icons.supervised_user_circle
                : Icons.person,
            color: color,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: _textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsuarioCard(Map<String, dynamic> usuario, String estado, {bool esActivo = false}) {
    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      final nombre = usuario['nombre'].toString().toLowerCase();
      final correo = usuario['correo'].toString().toLowerCase();
      final rol = usuario['rol'].toString().toLowerCase();

      if (!nombre.contains(_searchQuery) &&
          !correo.contains(_searchQuery) &&
          !rol.contains(_searchQuery)) {
        return const SizedBox.shrink();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: OpenContainer(
        closedElevation: 0,
        openElevation: 0,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        openShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        closedColor: _cardColor,
        openColor: _backgroundColor,
        transitionDuration: const Duration(milliseconds: 500),
        closedBuilder: (context, openContainer) => Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: esActivo ? Colors.blue.shade100 : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Hero(
                  tag: 'avatar_${usuario['id']}',
                  child: _buildAvatarWidget(usuario, esActivo),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usuario['nombre'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        usuario['correo'],
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildRolChip(usuario['rol']),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              esActivo ? 'Activo' : 'Inactivo',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: esActivo ? _activeColor : _inactiveColor,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (esActivo)
                      IconButton(
                        icon: const Icon(Icons.person_off_outlined),
                        color: _inactiveColor,
                        onPressed: () => _mostrarDialogoCambiarEstado(usuario, 'inactivo'),
                        tooltip: 'Desactivar',
                      ),
                    if (!esActivo) ...[
                      IconButton(
                        icon: const Icon(Icons.person_add_outlined),
                        color: _activeColor,
                        onPressed: () => _mostrarDialogoCambiarEstado(usuario, 'activo'),
                        tooltip: 'Activar',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep),
                        color: Colors.red,
                        onPressed: () => _mostrarDialogoEliminarPermanente(usuario),
                        tooltip: 'Eliminar',
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      color: _primaryColor,
                      onPressed: openContainer,
                      tooltip: 'Ver detalles',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        openBuilder: (context, closeContainer) => _detalleUsuario(usuario, closeContainer),
      ),
    );
  }

  Widget _buildAvatarWidget(Map<String, dynamic> usuario, bool esActivo) {
    final rol = usuario['rol'] as String;
    final color = rol == 'propietario'
        ? Colors.blue.shade700
        : rol == 'supervisor'
        ? Colors.green.shade700
        : _primaryColor;

    return CircleAvatar(
      radius: 30,
      backgroundColor: color.withOpacity(0.2),
      child: CircleAvatar(
        radius: 28,
        backgroundColor: _backgroundColor,
        child: Text(
          usuario['nombre'].toString().substring(0, 1).toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildRolChip(String rol) {
    late Color chipColor;
    late IconData chipIcon;
    late String rolText;

    switch (rol) {
      case 'propietario':
        chipColor = Colors.blue.shade700;
        chipIcon = Icons.admin_panel_settings;
        rolText = 'Propietario';
        break;
      case 'supervisor':
        chipColor = Colors.green.shade700;
        chipIcon = Icons.supervised_user_circle;
        rolText = 'Supervisor';
        break;
      default:
        chipColor = _primaryColor;
        chipIcon = Icons.person;
        rolText = 'Empleado';
    }

    return Chip(
      avatar: Icon(chipIcon, size: 16, color: Colors.white),
      label: Text(
        rolText,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: chipColor,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _detalleUsuario(Map<String, dynamic> usuario, VoidCallback closeContainer) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: closeContainer,
        ),
        title: Text(
          'Detalle del Usuario',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Hero(
              tag: 'avatar_${usuario['id']}',
              child: CircleAvatar(
                radius: 50,
                backgroundColor: usuario['rol'] == 'propietario'
                    ? Colors.blue.shade100
                    : usuario['rol'] == 'supervisor'
                    ? Colors.green.shade100
                    : _primaryColor.withOpacity(0.2),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white,
                  child: Text(
                    usuario['nombre'].toString().substring(0, 1).toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: usuario['rol'] == 'propietario'
                          ? Colors.blue.shade700
                          : usuario['rol'] == 'supervisor'
                          ? Colors.green.shade700
                          : _primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              usuario['nombre'],
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRolChip(usuario['rol']),
                const SizedBox(width: 10),
                Chip(
                  label: Text(
                    usuario['estado'] == 'activo' ? 'Activo' : 'Inactivo',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: usuario['estado'] == 'activo' ? _activeColor : _inactiveColor,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 40),
            _buildInfoCard(
              title: 'Información del Usuario',
              children: [
                _buildInfoItem(
                  icon: Icons.email,
                  title: 'Correo Electrónico',
                  value: usuario['correo'],
                ),
                _buildInfoItem(
                  icon: Icons.assignment_ind,
                  title: 'Rol',
                  value: usuario['rol'] == 'propietario'
                      ? 'Propietario'
                      : usuario['rol'] == 'supervisor'
                      ? 'Supervisor'
                      : 'Empleado',
                ),
                _buildInfoItem(
                  icon: Icons.calendar_today,
                  title: 'Fecha de Creación',
                  value: usuario['createdAt'] != null
                      ? _formatDate(usuario['createdAt'])
                      : 'No disponible',
                ),
                _buildInfoItem(
                  icon: Icons.update,
                  title: 'Última Actualización',
                  value: usuario['updatedAt'] != null
                      ? _formatDate(usuario['updatedAt'])
                      : 'No disponible',
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (usuario['estado'] == 'activo')
              ElevatedButton.icon(
                onPressed: () => _mostrarDialogoCambiarEstado(usuario, 'inactivo'),
                icon: const Icon(Icons.person_off),
                label: const Text('Desactivar Usuario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _inactiveColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )
            else
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _mostrarDialogoCambiarEstado(usuario, 'activo'),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Activar Usuario'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _activeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _mostrarDialogoEliminarPermanente(usuario),
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: Text(
                      'Eliminar Permanentemente',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filtrarUsuarios(List<Map<String, dynamic>> usuarios) {
    if (_searchQuery.isEmpty) return usuarios;

    return usuarios.where((user) {
      final nombre = user['nombre'].toString().toLowerCase();
      final correo = user['correo'].toString().toLowerCase();
      final rol = user['rol'].toString().toLowerCase();

      return nombre.contains(_searchQuery) ||
          correo.contains(_searchQuery) ||
          rol.contains(_searchQuery);
    }).toList();
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/no_results.svg',
            height: 150,
            width: 150,
          ),
          const SizedBox(height: 20),
          Text(
            'No se encontraron resultados',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otra búsqueda',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: _secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const CircleAvatar(radius: 30),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 250,
                          height: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 60,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Gestión de Usuarios',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _backgroundColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar usuarios',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: _secondaryTextColor),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  indicatorColor: _primaryColor,
                  indicatorWeight: 3,
                  labelColor: _primaryColor,
                  unselectedLabelColor: _secondaryTextColor,
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(
                      icon: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline),
                          const SizedBox(width: 8),
                          const Text('Activos'),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _activeColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _usuariosActivos.length.toString(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      icon: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cancel_outlined),
                          const SizedBox(width: 8),
                          const Text('Inactivos'),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _inactiveColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _usuariosInactivos.length.toString(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingShimmer()
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error de conexión',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: _secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _cargarUsuarios,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Reintentar',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          // Pestaña de usuarios activos
          _filtrarUsuarios(_usuariosActivos).isEmpty
              ? _buildNoResultsWidget()
              : RefreshIndicator(
            onRefresh: _cargarUsuarios,
            color: _primaryColor,
            child: ListView.builder(
              itemCount: _filtrarUsuarios(_usuariosActivos).length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final usuario = _filtrarUsuarios(_usuariosActivos)[index];
                return _buildUsuarioCard(usuario, 'activo', esActivo: true);
              },
            ),
          ),

          // Pestaña de usuarios inactivos
          _filtrarUsuarios(_usuariosInactivos).isEmpty
              ? _buildNoResultsWidget()
              : RefreshIndicator(
            onRefresh: _cargarUsuarios,
            color: _primaryColor,
            child: ListView.builder(
              itemCount: _filtrarUsuarios(_usuariosInactivos).length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final usuario = _filtrarUsuarios(_usuariosInactivos)[index];
                return _buildUsuarioCard(usuario, 'inactivo', esActivo: false);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoAgregarUsuario,
        backgroundColor: _primaryColor,
        icon: const Icon(Icons.person_add),
        label: Text(
          'Agregar Usuario',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}