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

  // Paleta de colores refinada para una farmacia elegante
  static const primaryBlue = Color(0xFF1A237E);    // Azul oscuro elegante
  static const secondaryBlue = Color(0xFF283593);  // Azul medio
  static const accentBlue = Color(0xFF3949AB);     // Azul acento
  static const lightBlue = Color(0xFFE8EAF6);      // Azul muy claro para fondos
  static const white = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
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
        'description': 'Gestionar ventas y pagos',
        'gradient': [accentBlue, primaryBlue]
      },
      {
        'title': 'Inventario',
        'icon': Icons.medication_liquid,
        'page': InventarioPage(),
        'color': secondaryBlue,
        'description': 'Control de medicamentos',
        'gradient': [secondaryBlue, primaryBlue]
      },
      {
        'title': 'Personal',
        'icon': Icons.people_alt_rounded,
        'page': UsuariosPage(),
        'color': primaryBlue,
        'description': 'Administrar empleados',
        'gradient': [accentBlue, secondaryBlue]
      },
      {
        'title': 'Caja',
        'icon': Icons.account_balance_rounded,
        'page': CajaPage(),
        'color': secondaryBlue,
        'description': 'Control financiero',
        'gradient': [secondaryBlue, primaryBlue]
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
    final padding = smallScreen ? 12.0 : 20.0;

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
        backgroundColor: lightBlue,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: smallScreen ? 140.0 : 220.0,
                floating: false,
                pinned: true,
                stretch: true,
                elevation: 0,
                backgroundColor: primaryBlue,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Farmacia ${_capitalizeRole(userRole ?? "")}',
                    style: TextStyle(
                      color: white,
                      fontWeight: FontWeight.w600,
                      fontSize: smallScreen ? 18.0 : 22.0,
                      letterSpacing: 0.5,
                    ),
                  ),
                  titlePadding: EdgeInsets.only(
                    left: padding * 2,
                    bottom: padding * 1.5,
                    right: padding * 2,
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          primaryBlue,
                          secondaryBlue,
                          accentBlue,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -50,
                          top: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: white.withOpacity(0.1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: white),
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
                          menuItems[index]['gradient'],
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
      List<Color> gradient,
      String description,
      bool smallScreen,
      ) {
    return Card(
      elevation: 4,
      shadowColor: primaryBlue.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                white,
                lightBlue.withOpacity(0.5),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  icon,
                  size: smallScreen ? 80 : 100,
                  color: gradient[0].withOpacity(0.1),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(smallScreen ? 16.0 : 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(smallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: gradient[0].withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: smallScreen ? 32 : 40,
                        color: white,
                      ),
                    ),
                    SizedBox(height: smallScreen ? 12 : 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: smallScreen ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: smallScreen ? 6 : 8),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: smallScreen ? 13 : 15,
                        color: Colors.grey[700],
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
        backgroundColor: white,
        contentPadding: EdgeInsets.all(smallScreen ? 20.0 : 28.0),
        title: Text(
          '¿Cerrar sesión?',
          style: TextStyle(
            fontSize: smallScreen ? 20 : 22,
            color: primaryBlue,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(
            fontSize: smallScreen ? 15 : 17,
            color: Colors.grey[800],
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: smallScreen ? 16.0 : 24.0,
                vertical: smallScreen ? 8.0 : 12.0,
              ),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: smallScreen ? 15 : 17,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              elevation: 2,
              shadowColor: primaryBlue.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: smallScreen ? 20.0 : 28.0,
                vertical: smallScreen ? 12.0 : 16.0,
              ),
            ),
            child: Text(
              'Cerrar sesión',
              style: TextStyle(
                color: white,
                fontSize: smallScreen ? 15 : 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }//

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}