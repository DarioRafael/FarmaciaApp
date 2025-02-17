import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_app/pages/usuarios_page.dart';
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

  // Definiendo la paleta de colores para la farmacia
  static const primaryBlue = Color(0xFF1E88E5);  // Azul principal
  static const secondaryBlue = Color(0xFF42A5F5); // Azul secundario
  static const accentBlue = Color(0xFF64B5F6);   // Azul claro para acentos

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
        'title': 'Ventas',
        'icon': Icons.point_of_sale,
        'page': CobroPage(),
        'color': primaryBlue,
        'description': 'Gestionar ventas y pagos'
      },
      {
        'title': 'Inventario',
        'icon': Icons.medication,
        'page': InventarioPage(),
        'color': secondaryBlue,
        'description': 'Control de medicamentos'
      },
      {
        'title': 'Abastecimiento',
        'icon': Icons.local_shipping,
        'page': ReabastecimientosPage(),
        'color': accentBlue,
        'description': 'Gestionar pedidos'
      },
      {
        'title': 'Personal',
        'icon': Icons.people,
        'page': UsuariosPage(),
        'color': primaryBlue,
        'description': 'Administrar empleados'
      },
      {
        'title': 'Caja',
        'icon': Icons.account_balance,
        'page': CajaPage(),
        'color': secondaryBlue,
        'description': 'Control financiero'
      },
    ];

    if (userRole == 'propietario') {
      return allItems;
    } else if (userRole == 'supervisor') {
      return allItems.where((item) =>
      item['title'] != 'Personal' &&
          item['title'] != 'Caja'
      ).toList();
    } else if (userRole == 'empleado') {
      return allItems.where((item) =>
      item['title'] == 'Ventas' ||
          item['title'] == 'Inventario'
      ).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;
    final smallScreen = screenSize.width < 400;

    int crossAxisCount;
    if (screenSize.width > 1200) {
      crossAxisCount = 3;
    } else if (screenSize.width > 800) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = isPortrait ? 1 : 2;
    }

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
        backgroundColor: Colors.grey[50], // Fondo muy claro
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: smallScreen ? 120.0 : 200.0,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: primaryBlue,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Farmacia - ${_capitalizeRole(userRole ?? "")}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
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
                          primaryBlue,
                          secondaryBlue,
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
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
                  color: color,
                ),
                SizedBox(height: smallScreen ? 8 : 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: smallScreen ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                SizedBox(height: smallScreen ? 4 : 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: smallScreen ? 12 : 14,
                    color: Colors.grey[600],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.all(smallScreen ? 16.0 : 24.0),
        title: Text(
          '¿Cerrar sesión?',
          style: TextStyle(
            fontSize: smallScreen ? 18 : 20,
            color: primaryBlue,
          ),
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
                color: Colors.grey[600],
                fontSize: smallScreen ? 14 : 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
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
                  fontSize: smallScreen ? 14 : 16
              ),
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