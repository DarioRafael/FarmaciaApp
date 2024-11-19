import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _usuariosActivos = [];
  List<Map<String, dynamic>> _usuariosInactivos = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarUsuarios();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión';
        _isLoading = false;
      });
    }
  }

  Widget _buildUsuarioCard(Map<String, dynamic> usuario, String estado, {bool esActivo = false}) {
    bool esActivoUsuario = estado == 'activo';
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: CircleAvatar(
          child: Text(
            usuario['nombre'][0].toUpperCase(),
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          backgroundColor: esActivoUsuario ? Colors.green : Colors.grey,
        ),
        title: Text(usuario['nombre'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(usuario['correo'], style: TextStyle(fontSize: 14, color: Colors.grey)),
            Text(
              'Rol: ${usuario['rol']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: usuario['rol'] == 'propietario' ? Colors.blue : Colors.green,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                esActivoUsuario ? Icons.person_off : Icons.person,
                color: esActivoUsuario ? Colors.red : Colors.green,
                size: 28,
              ),
              onPressed: () => _mostrarDialogoCambiarEstado(usuario, esActivoUsuario ? 'inactivo' : 'activo'),
            ),
            if (!esActivo) // Solo mostrar el botón de eliminar si el usuario no está activo
              IconButton(
                icon: Icon(Icons.delete_forever, color: Colors.red, size: 28),
                onPressed: () => _mostrarDialogoEliminarPermanente(usuario),
              ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoCambiarEstado(Map<String, dynamic> usuario, String nuevoEstado) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(nuevoEstado == 'activo' ? 'Activar Usuario' : 'Desactivar Usuario'),
        content: Text(
            '¿Estás seguro de que deseas ${nuevoEstado == 'activo' ? 'activar' : 'desactivar'} a ${usuario['nombre']}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              var id = usuario['id'];
              if (id == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ID del usuario no encontrado')));
                return;
              }
              _cambiarEstadoUsuario(id, nuevoEstado);
            },
            child: Text(
              nuevoEstado == 'activo' ? 'Activar' : 'Desactivar',
              style: TextStyle(color: nuevoEstado == 'activo' ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEliminarPermanente(Map<String, dynamic> usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Eliminar Permanentemente'),
        content: Text(
            '¿Estás seguro de que deseas eliminar permanentemente a ${usuario['nombre']}?\n\nEsta acción no se puede deshacer.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              var id = usuario['id'];
              if (id == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ID del usuario no encontrado')));
                return;
              }
              _eliminarUsuario(id);
            },
            child: Text(
              'Eliminar Permanentemente',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cambiarEstadoUsuario(dynamic id, String nuevoEstado) async {
    try {
      final response = await http.patch(
        Uri.parse('https://modelo-server.vercel.app/api/v1/trabajadores/$id/estado'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': nuevoEstado}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(nuevoEstado == 'activo' ? 'Usuario activado' : 'Usuario desactivado')));
        _cargarUsuarios();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cambiar estado del usuario: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de conexión')));
    }
  }

  Future<void> _eliminarUsuario(dynamic id) async {
    try {
      final response = await http.delete(
        Uri.parse('https://modelo-server.vercel.app/api/v1/trabajadores/$id/eliminar'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Usuario eliminado permanentemente')));
        _cargarUsuarios();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar usuario: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de conexión')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Usuarios'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Activos'),
            Tab(text: 'Inactivos'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : TabBarView(
        controller: _tabController,
        children: [
          ListView(
            children: _usuariosActivos.map((usuario) => _buildUsuarioCard(usuario, 'activo')).toList(),
          ),
          ListView(
            children: _usuariosInactivos.map((usuario) => _buildUsuarioCard(usuario, 'inactivo')).toList(),
          ),
        ],
      ),
    );
  }
}
