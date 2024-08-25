import 'package:flutter/material.dart';

class CobroPage extends StatefulWidget {
  const CobroPage({super.key});

  @override
  _CobroPageState createState() => _CobroPageState();
}

class _CobroPageState extends State<CobroPage> {
  final List<Map<String, dynamic>> _productos = [
    {'nombre': 'Sabritas', 'precio': 10.0},
    {'nombre': 'Papas', 'precio': 20.0},
    {'nombre': 'Coca', 'precio': 30.0},
    {'nombre': 'Sprite', 'precio': 30.0},
    {'nombre': 'Fanta', 'precio': 30.0},
    {'nombre': 'Coca Light', 'precio': 30.0},
    {'nombre': 'Coca Zero', 'precio': 30.0},
  ];

  final Map<String, int> _carrito = {};
  List<Map<String, dynamic>> _productosFiltrados = [];

  void _mostrarNotificacion(String mensaje) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50, // Ajusta esta posición según lo necesario
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              mensaje,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  void _agregarAlCarrito(String nombreProducto) {
    setState(() {
      if (_carrito.containsKey(nombreProducto)) {
        _carrito[nombreProducto] = _carrito[nombreProducto]! + 1;
        _mostrarNotificacion('Actualizada la cantidad de $nombreProducto.');
      } else {
        _carrito[nombreProducto] = 1;
        _mostrarNotificacion('Agregado $nombreProducto al carrito.');
      }
    });
  }

  void _eliminarDelCarrito(String nombreProducto) {
    setState(() {
      _carrito.remove(nombreProducto);
      _mostrarNotificacion('Eliminado $nombreProducto del carrito.');
    });
  }

  void _vaciarCarrito() {
    setState(() {
      _carrito.clear();
      _mostrarNotificacion('Carrito vacío.');
    });
  }

  void _actualizarCantidad(String nombreProducto, int nuevaCantidad) {
    setState(() {
      if (nuevaCantidad > 0) {
        _carrito[nombreProducto] = nuevaCantidad;
        _mostrarNotificacion('Cantidad de $nombreProducto actualizada.');
      } else {
        _eliminarDelCarrito(nombreProducto);
      }
    });
  }

  double _calcularTotal() {
    double total = 0.0;
    _carrito.forEach((nombre, cantidad) {
      final precio = _productos.firstWhere((producto) => producto['nombre'] == nombre)['precio'] as double;
      total += precio * cantidad;
    });
    return total;
  }

  int _contarUnidades() {
    return _carrito.values.fold(0, (sum, cantidad) => sum + cantidad);
  }

  void _filtrarProductos(String query) {
    setState(() {
      if (query.isEmpty) {
        _productosFiltrados = [];
      } else {
        _productosFiltrados = _productos.where((producto) {
          final nombreProducto = producto['nombre'] as String;
          return nombreProducto.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _mostrarCarrito() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Carrito de Compras',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: _carrito.entries.map((entry) {
                        final producto = _productos.firstWhere((producto) => producto['nombre'] == entry.key);
                        return ListTile(
                          title: Text('${entry.key}'),
                          subtitle: Row(
                            children: [
                              Expanded(
                                child: DropdownButton<int>(
                                  value: entry.value,
                                  items: List.generate(10, (index) => index + 1).map((cantidad) {
                                    return DropdownMenuItem<int>(
                                      value: cantidad,
                                      child: Text('$cantidad'),
                                    );
                                  }).toList(),
                                  onChanged: (nuevaCantidad) {
                                    if (nuevaCantidad != null) {
                                      setState(() {
                                        _actualizarCantidad(entry.key, nuevaCantidad);
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text('Precio total: \$${producto['precio'] * entry.value}'),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    _eliminarDelCarrito(entry.key);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Unidades totales: ${_contarUnidades()}'),
                  Text('Total a pagar: \$${_calcularTotal()}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _vaciarCarrito();
                      });
                    },
                    child: Text('Vaciar carrito'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobro de Productos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Buscar productos:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Escribe el nombre del producto',
              ),
              onChanged: _filtrarProductos,
            ),
            const SizedBox(height: 20),
            if (_productosFiltrados.isNotEmpty)
              ..._productosFiltrados.map((producto) => ElevatedButton(
                onPressed: () => _agregarAlCarrito(producto['nombre'] as String),
                child: Text('Agregar ${producto['nombre']} - \$${producto['precio']}'),
              )),
            const SizedBox(height: 20),
            if (_carrito.isNotEmpty)
              ElevatedButton(
                onPressed: _mostrarCarrito,
                child: const Text('Ver carrito'),
              ),
          ],
        ),
      ),
    );
  }
}
