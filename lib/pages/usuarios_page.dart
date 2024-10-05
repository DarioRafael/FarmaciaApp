import 'package:flutter/material.dart';

class UsuariosPage extends StatelessWidget {
  const UsuariosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Inventario'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Gestión de Usuarios',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20), // Espacio entre el texto y el botón
            ElevatedButton(
              onPressed: () {
                // Implementar funcionalidad para gestionar inventario aquí
              },
              child: const Text('Gestionar Usuarios'),
            ),
          ],
        ),
      ),
    );
  }
}
