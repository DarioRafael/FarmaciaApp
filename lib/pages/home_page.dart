import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importa shared_preferences para manejar el cierre de sesión
import 'cobro_page.dart';
import 'catalogo_page.dart';
import 'inventario_page.dart';
import 'reportes_page.dart';
import 'login_page.dart'; // Asegúrate de importar la página de inicio de sesión

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener el ancho de la pantalla para hacer ajustes responsivos
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2; // Valor predeterminado para pantallas pequeñas

    // Ajustar número de columnas según el ancho de la pantalla
    if (screenWidth > 1200) {
      crossAxisCount = 4;
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
    }

    return WillPopScope(
      onWillPop: () async {
        // Mostrar el cuadro de diálogo cuando se presiona el botón "Atrás"
        final shouldLogout = await _showLogoutConfirmationDialog(context);
        if (shouldLogout) {
          await _logout(context);
          return true; // Permite salir después de hacer logout
        }
        return false; // Cancela la acción de retroceso si se elige "No"
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bienvenido'),
          automaticallyImplyLeading: false, // Oculta el botón de regresar en la HomePage
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: crossAxisCount, // Número dinámico de columnas
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            children: [
              _buildGridTile(context, 'Cobrar', Icons.attach_money, CobroPage()),
              _buildGridTile(context, 'Catálogo', Icons.inventory, CatalogoPage()),
              _buildGridTile(context, 'Inventario', Icons.storage, InventarioPage()),
              _buildGridTile(context, 'Reportes', Icons.analytics, ReportesPage()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridTile(BuildContext context, String title, IconData icon, Widget page) {
    // Ajustar el tamaño del icono basado en el ancho de la pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    double iconSize = screenWidth > 800 ? 64.0 : 48.0; // Iconos más grandes en pantallas grandes

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Card(
        elevation: 4.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize),
            const SizedBox(height: 10.0),
            Text(title, style: const TextStyle(fontSize: 18.0)),
          ],
        ),
      ),
    );
  }

  // Función para mostrar el cuadro de confirmación de cierre de sesión
  Future<bool> _showLogoutConfirmationDialog(BuildContext context) async {
    return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Opción "No"
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Opción "Sí"
            child: const Text('Sí'),
          ),
        ],
      ),
    )) ?? false; // Devuelve false si el diálogo se cierra sin seleccionar una opción
  }

  // Función para cerrar sesión y redirigir al login
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn'); // Elimina el estado de sesión
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()), // Redirige al login
    );
  }
}
