import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_app/pages/usuarios_page.dart';
import 'package:universal_html/html.dart';
import 'cobro_page.dart';
import 'catalogo_page.dart';
import 'inventario_page.dart';
import 'reportes_page.dart';
import 'login_page.dart';
import 'rebastecimiento_page.dart';
import 'caja_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  String? userRole;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('userRole') ?? '';
    });
  }

  List<Map<String, dynamic>> _getMenuItemsByRole() {
    final List<Map<String, dynamic>> allItems = [
      {
        'title': 'Cobrar',
        'icon': Icons.attach_money,
        'page': CobroPage(),
        'color': Colors.green.shade400,
        'description': 'Gestionar ventas y pagos'
      },
      {
        'title': 'Catálogo',
        'icon': Icons.inventory_2,
        'page': CatalogoPage(),
        'color': Colors.blue.shade400,
        'description': 'Ver productos disponibles'
      },
      {
        'title': 'Inventario',
        'icon': Icons.storage,
        'page': InventarioPage(),
        'color': Colors.orange.shade400,
        'description': 'Control de existencias'
      },
      {
        'title': 'Reabastecimientos',
        'icon': Icons.local_shipping,
        'page': ReabastecimientosPage(),
        'color': Colors.purple.shade400,
        'description': 'Gestionar pedidos'
      },
      {
        'title': 'Reportes',
        'icon': Icons.analytics,
        'page': ReportesPage(),
        'color': Colors.red.shade400,
        'description': 'Análisis y estadísticas'
      },
      {
        'title': 'Usuarios',
        'icon': Icons.group,
        'page': UsuariosPage(),
        'color': Colors.teal.shade400,
        'description': 'Administrar personal'
      },
      {
        'title': 'Caja',
        'icon': Icons.shopping_bag,
        'page': CajaPage(),
        'color': Colors.deepPurple.shade400,
        'description': 'Control de ingresos y egresos'
      },
    ];
    if (userRole == 'propietario') {
      return allItems;
    } else if (userRole == 'supervisor') {
      return allItems.where((item) =>
      item['title'] != 'Catálogo' &&
          item['title'] != 'Usuarios' &&
          item['title'] != 'Caja'
      ).toList();
    } else if (userRole == 'empleado') {
      return allItems.take(2).toList();
    }
    return [];
  }
//
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;
    final smallScreen = screenSize.width < 400;

    // Cálculo dinámico de columnas basado en el tamaño de la pantalla y orientación
    int crossAxisCount;
    if (screenSize.width > 1200) {
      crossAxisCount = 3;
    } else if (screenSize.width > 800) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = isPortrait ? 1 : 2;
    }

    // Ajuste dinámico del aspect ratio basado en el tamaño de pantalla
    double childAspectRatio;
    if (smallScreen) {
      childAspectRatio = isPortrait ? 1.2 : 1.5;
    } else if (screenSize.width < 600) {
      childAspectRatio = isPortrait ? 1.3 : 1.6;
    } else {
      childAspectRatio = 1.4;
    }

    final menuItems = _getMenuItemsByRole();
    final padding = smallScreen ? 8.0 : 16.0;

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
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: smallScreen ? 120.0 : 200.0,
                floating: false,
                pinned: true,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Bienvenido, ${_capitalizeRole(userRole ?? "")}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: smallScreen ? 16.0 : 20.0,
                    ),
                  ),
                  titlePadding: EdgeInsets.only(
                    left: padding * 2,
                    bottom: padding,
                    right: padding * 2,
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      final shouldLogout = await _showLogoutConfirmationDialog(context);
                      if (shouldLogout) {
                        await _logout(context);
                      }
                    },
                  ),
                ],
              ),
              SliverPadding(
                padding: EdgeInsets.all(padding),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: padding,
                    crossAxisSpacing: padding,
                    childAspectRatio: childAspectRatio,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      return FadeTransition(
                        opacity: _animation,
                        child: _buildMenuCard(
                          context,
                          menuItems[index]['title'],
                          menuItems[index]['icon'],
                          menuItems[index]['page'],
                          menuItems[index]['color'],
                          menuItems[index]['description'],
                          smallScreen,
                        ),
                      );
                    },
                    childCount: menuItems.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
      BuildContext context,
      String title,
      IconData icon,
      Widget page,
      Color color,
      String description,
      bool smallScreen,
      ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(smallScreen ? 12.0 : 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: smallScreen ? 36 : 48,
                  color: Colors.white,
                ),
                SizedBox(height: smallScreen ? 8 : 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: smallScreen ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: smallScreen ? 4 : 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: smallScreen ? 12 : 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _capitalizeRole(String role) {
    if (role.isEmpty) return '';
    return role[0].toUpperCase() + role.substring(1);
  }

  Future<bool> _showLogoutConfirmationDialog(BuildContext context) async {
    final smallScreen = MediaQuery.of(context).size.width < 400;

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.all(smallScreen ? 16.0 : 24.0),
        title: Text(
          '¿Cerrar sesión?',
          style: TextStyle(fontSize: smallScreen ? 18 : 20),
        ),
        content: Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(fontSize: smallScreen ? 14 : 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: smallScreen ? 14 : 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: smallScreen ? 16.0 : 24.0,
                vertical: smallScreen ? 8.0 : 12.0,
              ),
            ),
            child: Text(
              'Cerrar sesión',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: smallScreen ? 14 : 16),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}