import 'package:flutter/material.dart';
import 'cobro_page.dart';
import 'catalogo_page.dart';
import 'inventario_page.dart';
import 'reportes_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // Número de columnas
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
            Icon(icon, size: 48.0),
            const SizedBox(height: 10.0),
            Text(title, style: const TextStyle(fontSize: 18.0)),
          ],
        ),
      ),
    );
  }
}
