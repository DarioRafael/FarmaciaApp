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
  String _query = '';

  @override
  void initState() {
    super.initState();
    _productosFiltrados = _productos; // Inicializa la lista filtrada
  }

  void _mostrarNotificacion(String mensaje) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.1,
        left: MediaQuery.of(context).size.width * 0.1,
        right: MediaQuery.of(context).size.width * 0.1,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
                vertical: MediaQuery.of(context).size.height * 0.02),
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
      _productosFiltrados = _productos
          .where((producto) => producto['nombre']
          .toLowerCase()
          .contains(_query.toLowerCase()))
          .toList(); // Actualiza la lista filtrada
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
      final precio = _productos
          .firstWhere((producto) => producto['nombre'] == nombre)['precio']
      as double;
      total += precio * cantidad;
    });
    return total;
  }

  int _contarUnidades() {
    return _carrito.values.fold(0, (sum, cantidad) => sum + cantidad);
  }

  void _filtrarProductos(String query) {
    setState(() {
      _query = query;
      if (query.isEmpty) {
        _productosFiltrados = _productos;
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
      isScrollControlled: true, // Permite controlar la altura del modal
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final hayProductos = _carrito.isNotEmpty;

            return Container(
              height: MediaQuery.of(context).size.height, // Ocupa toda la altura de la pantalla
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              child: Column(
                children: [
                  Text(
                    'Carrito de Compras',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.05 < 20
                          ? MediaQuery.of(context).size.width * 0.05
                          : 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
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
                                  items: List.generate(10, (index) => index + 1)
                                      .map((cantidad) {
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
                              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                              Text('Precio total: \$${producto['precio'] * entry.value}'),
                              IconButton(
                                icon: Icon(Icons.delete, color: Color(0xFF004D40)),
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Text('Unidades totales: ${_contarUnidades()}',
                      style: TextStyle(color: Color(0xFF004D40))),
                  Text('Total a pagar: \$${_calcularTotal()}',
                      style: TextStyle(color: Color(0xFF004D40))),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _vaciarCarrito();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF004D40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.02),
                      minimumSize: Size(double.infinity, MediaQuery.of(context).size.height * 0.05),
                    ),
                    child: Text('Vaciar carrito',
                        style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  if (hayProductos)
                    ElevatedButton(
                      onPressed: () {
                        _mostrarConfirmacionCompra();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF004D40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.02),
                        minimumSize: Size(double.infinity, MediaQuery.of(context).size.height * 0.05),
                      ),
                      child: Text('Confirmar venta',
                          style: TextStyle(color: Colors.white)),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarConfirmacionCompra() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Confirmación de venta',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.05 < 24 ? MediaQuery.of(context).size.width * 0.05 : 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  // Resumen de productos
                  Expanded(
                    child: ListView(
                      children: _carrito.entries.map((entry) {
                        final producto = _productos.firstWhere((producto) =>
                        producto['nombre'] == entry.key);
                        final total = producto['precio'] * entry.value;
                        return ListTile(
                          title: Text('${entry.key}'),
                          subtitle: Text(
                              'Cantidad: ${entry.value} x Precio: \$${producto['precio']}'),
                          trailing: Text('Subtotal: \$${total.toStringAsFixed(2)}'),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Text(
                    'Total a pagar: \$${_calcularTotal().toStringAsFixed(2)}',
                    style: TextStyle(color: Color(0xFF004D40)),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Cierra la hoja modal
                      _mostrarAprobado(); // Muestra el mensaje de aprobación
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF004D40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.02),
                      minimumSize: Size(double.infinity, MediaQuery.of(context).size.height * 0.05),
                    ),
                    child: Text('Confirmar venta', style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Cierra la hoja modal
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF004D40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.02),
                      minimumSize: Size(double.infinity, MediaQuery.of(context).size.height * 0.05),
                    ),
                    child: Text('Cancelar', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  void _mostrarAprobado() {
    showDialog(
      context: context,
      barrierDismissible: false, // Evita que el usuario cierre el diálogo tocando fuera de él
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Evita que el diálogo se cierre con el botón de retroceso
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Container(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                        Text(
                          '¡Venta realizada con éxito!',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.05 < 20 ? MediaQuery.of(context).size.width * 0.05 : 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF004D40),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Cierra el diálogo
                        Navigator.of(context).pop(); // Regresa a la pantalla inicial de cobro
                        _vaciarCarrito(); // Vacía el carrito
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF004D40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.02),
                        minimumSize: Size(double.infinity, MediaQuery.of(context).size.height * 0.05),
                      ),
                      child: Text('Aceptar', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cobro', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF004D40),
      ),
      body: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                border: OutlineInputBorder(),
              ),
              onChanged: _filtrarProductos,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Expanded(
              child: ListView.builder(
                itemCount: _productosFiltrados.length,
                itemBuilder: (context, index) {
                  final producto = _productosFiltrados[index];
                  final nombreProducto = producto['nombre'];
                  final precioProducto = producto['precio'];
                  return ListTile(
                    title: Text(nombreProducto),
                    subtitle: Text('Precio: \$${precioProducto}'),
                    trailing: ElevatedButton(
                      onPressed: () => _agregarAlCarrito(nombreProducto),
                      child: Text('Agregar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF004D40),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.02),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _carrito.isNotEmpty
          ? FloatingActionButton(
        onPressed: _mostrarCarrito,
        backgroundColor: Color(0xFF004D40),
        foregroundColor: Colors.white,
        child: Icon(Icons.shopping_cart),
      )
          : null,
    );
  }
}