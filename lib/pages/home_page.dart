import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_app/pages/usuarios_page.dart';
import 'cobro_page.dart';
import 'catalogo_page.dart';
import 'inventario_page.dart';
import 'reportes_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('userRole') ?? '';
    });
  }

  List<Map<String, dynamic>> _getMenuItemsByRole() {
    final List<Map<String, dynamic>> allItems = [
      {'title': 'Cobrar', 'icon': Icons.attach_money, 'page': CobroPage()},
      {'title': 'Catálogo', 'icon': Icons.inventory, 'page': CatalogoPage()},
      {'title': 'Inventario', 'icon': Icons.storage, 'page': InventarioPage()},
      {'title': 'Reportes', 'icon': Icons.analytics, 'page': ReportesPage()},
      {'title': 'Usuarios', 'icon': Icons.verified_user, 'page': UsuariosPage()},
    ];

    if (userRole == 'propietario') {
      return allItems;}
    else if (userRole == 'empleado') {
      return allItems.take(3).toList();
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;

    if (screenWidth > 1200) {
      crossAxisCount = 4;
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
    }

    final menuItems = _getMenuItemsByRole();

    return WillPopScope(
      onWillPop: () async {
        final shouldLogout = await _showLogoutConfirmationDialog(context);
        if (shouldLogout) {
          await _logout(context);
          return true;
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Bienvenido ${userRole ?? ""}'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                final shouldLogout = await _showLogoutConfirmationDialog(context);
                if (shouldLogout) {
                  await _logout(context);
                }
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            children: menuItems
                .map((item) => _buildGridTile(
              context,
              item['title'],
              item['icon'],
              item['page'],
            ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildGridTile(BuildContext context, String title, IconData icon, Widget page) {
    final screenWidth = MediaQuery.of(context).size.width;
    double iconSize = screenWidth > 800 ? 64.0 : 48.0;

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

  Future<bool> _showLogoutConfirmationDialog(BuildContext context) async {
    return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí'),
          ),
        ],
      ),
    )) ?? false;
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Limpia todas las preferencias al cerrar sesión
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}