import 'package:flutter/material.dart';

class ReabastecimientosPage extends StatelessWidget {
  final List<Map<String, dynamic>> reabastecimientos = [
    {
      'IDReabastecimiento': 1,
      'producto': 'Producto A',
      'cantidad': 10,
      'precioPorUnidad': 15.5,
      'precioTotal': 155.0,
      'fecha': '2024-11-18 10:30:00',
    },
    {
      'IDReabastecimiento': 2,
      'producto': 'Producto B',
      'cantidad': 5,
      'precioPorUnidad': 20.0,
      'precioTotal': 100.0,
      'fecha': '2024-11-17 14:00:00',
    },
    // Agrega más ejemplos o datos reales
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reabastecimientos'),
      ),
      body: ListView.builder(
        itemCount: reabastecimientos.length,
        itemBuilder: (context, index) {
          final reabastecimiento = reabastecimientos[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(reabastecimiento['producto']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cantidad: ${reabastecimiento['cantidad']}'),
                  Text(
                      'Precio por unidad: \$${reabastecimiento['precioPorUnidad'].toStringAsFixed(2)}'),
                  Text(
                      'Precio total: \$${reabastecimiento['precioTotal'].toStringAsFixed(2)}'),
                  Text('Fecha: ${reabastecimiento['fecha']}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
