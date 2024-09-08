import 'package:flutter/material.dart';
import 'cobro_page.dart';
import 'catalogo_page.dart';
import 'inventario_page.dart';
import 'reportes_page.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido'),
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
}
