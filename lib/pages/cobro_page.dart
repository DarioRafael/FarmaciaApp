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

  final List<Map<String, int>> _carritos = [];
  int _carritoActivo = -1; // Índice del carrito activo
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
      if (_carritoActivo == -1) {
        _carritos.add({});
        _carritoActivo = 0;
      }
      final carritoActual = _carritos[_carritoActivo];

      if (carritoActual.containsKey(nombreProducto)) {
        carritoActual[nombreProducto] = carritoActual[nombreProducto]! + 1;
        _mostrarNotificacion('Actualizada la cantidad de $nombreProducto.');
      } else {
        carritoActual[nombreProducto] = 1;
        _mostrarNotificacion('Agregado $nombreProducto al carrito.');
      }

      _productosFiltrados = _productos
          .where((producto) =>
              producto['nombre'].toLowerCase().contains(_query.toLowerCase()))
          .toList(); // Actualiza la lista filtrada

      if (_carritos.isNotEmpty) {
        _mostrarBotonFlotante();
      }
    });
  }

  void _eliminarDelCarrito(String nombreProducto) {
    setState(() {
      if (_carritoActivo != -1) {
        final carritoActual = _carritos[_carritoActivo];
        carritoActual.remove(nombreProducto);
        _mostrarNotificacion('Eliminado $nombreProducto del carrito.');

        if (carritoActual.isEmpty) {
          _ocultarBotonFlotante();
        }
      }
    });
  }

  void _vaciarCarrito() {
    setState(() {
      if (_carritoActivo != -1) {
        _carritos[_carritoActivo].clear();
        _mostrarNotificacion('Carrito vacío.');

        if (_carritos[_carritoActivo].isEmpty) {
          _ocultarBotonFlotante();
        }
      }
    });
  }

  void _actualizarCantidad(String nombreProducto, int nuevaCantidad) {
    setState(() {
      if (_carritoActivo != -1) {
        final carritoActual = _carritos[_carritoActivo];

        if (nuevaCantidad > 0) {
          carritoActual[nombreProducto] = nuevaCantidad;
          _mostrarNotificacion('Cantidad de $nombreProducto actualizada.');
        } else {
          _eliminarDelCarrito(nombreProducto);
        }
      }
    });
  }

  double _calcularTotal() {
    double total = 0.0;
    if (_carritoActivo != -1) {
      final carritoActual = _carritos[_carritoActivo];
      carritoActual.forEach((nombre, cantidad) {
        final precio = _productos.firstWhere(
            (producto) => producto['nombre'] == nombre)['precio'] as double;
        total += precio * cantidad;
      });
    }
    return total;
  }

  int _contarUnidades() {
    if (_carritoActivo != -1) {
      final carritoActual = _carritos[_carritoActivo];
      return carritoActual.values.fold(0, (sum, cantidad) => sum + cantidad);
    }
    return 0;
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
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final hayProductos =
                _carritoActivo != -1 && _carritos[_carritoActivo].isNotEmpty;

            return Container(
              height: MediaQuery.of(context).size.height,
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              child: Column(
                children: [
                  Text(
                    'Carrito de Compras ${_carritoActivo + 1}',
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
                      children: _carritos[_carritoActivo].entries.map((entry) {
                        final producto = _productos.firstWhere(
                            (producto) => producto['nombre'] == entry.key);
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
                                        _actualizarCantidad(
                                            entry.key, nuevaCantidad);
                                      });
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.02),
                              Text(
                                  'Precio total: \$${producto['precio'] * entry.value}'),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    color: Color(0xFF004D40)),
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
                        Navigator.pop(
                            context); // Cierra el carrito cuando se vacía
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF004D40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.02),
                      minimumSize: Size(double.infinity,
                          MediaQuery.of(context).size.height * 0.05),
                    ),
                    child: Text('Vaciar carrito',
                        style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ElevatedButton(
                    onPressed: () {
                      _confirmarVenta();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF004D40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.02),
                      minimumSize: Size(double.infinity,
                          MediaQuery.of(context).size.height * 0.05),
                    ),
                    child: Text('Confirmar venta',
                        style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmarVenta() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Venta'),
          content: Text('¿Está seguro que desea confirmar la venta?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  // Procesa la venta aquí
                  _vaciarCarrito();
                  _carritos.removeAt(_carritoActivo); // Elimina el carrito
                  if (_carritoActivo >= _carritos.length) {
                    _carritoActivo = _carritos.length - 1;
                  }
                  if (_carritos.isEmpty) {
                    _carritoActivo = -1;
                    _ocultarBotonFlotante();
                  }
                  _mostrarNotificacion('Venta confirmada.');
                  Navigator.of(context).pop(); // Cierra el diálogo
                  Navigator.of(context)
                      .pop(); // Cierra el carrito si está abierto
                });
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _agregarNuevoCarrito() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Agregar Nuevo Carrito'),
          content: Text('¿Estás seguro que deseas agregar un nuevo carrito?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _carritos.add({});
                  _carritoActivo = _carritos.length -
                      1; // Selecciona el nuevo carrito como activo
                });
                Navigator.of(context).pop(); // Cierra el diálogo
              },
              child: Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _cambiarCarrito(int nuevoIndex) {
    setState(() {
      _carritoActivo = nuevoIndex;
    });
    _mostrarCarrito(); // Luego muestra el carrito actualizado
  }

  bool _mostrarSegundoBoton = false;

  void _mostrarBotonFlotante() {
    setState(() {
      _mostrarSegundoBoton = true;
    });
  }

  void _ocultarBotonFlotante() {
    setState(() {
      _mostrarSegundoBoton = false;
    });
  }

  void _mostrarCarritoConIndice(int index) {
    if (index == -1 || index >= _carritos.length) {
      return; // No hay carrito válido para mostrar
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final hayProductos = _carritos[index].isNotEmpty;

            return Container(
              height: MediaQuery.of(context).size.height,
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              child: Column(
                children: [
                  Text(
                    'Carrito de Compras ${index + 1}',
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
                      children: _carritos[index].entries.map((entry) {
                        final producto = _productos.firstWhere(
                            (producto) => producto['nombre'] == entry.key);
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
                                        _actualizarCantidad(
                                            entry.key, nuevaCantidad);
                                      });
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.02),
                              Text(
                                  'Precio total: \$${producto['precio'] * entry.value}'),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    color: Color(0xFF004D40)),
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
                        Navigator.pop(
                            context); // Cierra el carrito cuando se vacía
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF004D40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.02),
                      minimumSize: Size(double.infinity,
                          MediaQuery.of(context).size.height * 0.05),
                    ),
                    child: Text('Vaciar carrito',
                        style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ElevatedButton(
                    onPressed: () {
                      _confirmarVenta();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF004D40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.02),
                      minimumSize: Size(double.infinity,
                          MediaQuery.of(context).size.height * 0.05),
                    ),
                    child: Text('Confirmar venta',
                        style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoCambiarCarrito() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.8),
          contentPadding: EdgeInsets.all(16.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecciona un carrito:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              Column(
                children: List.generate(_carritos.length, (index) {
                  return ListTile(
                    title: Text('Carrito ${index + 1}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.visibility, color: Colors.blue),
                          onPressed: () {
                            // Aquí puedes añadir la lógica para mostrar el carrito
                            _mostrarCarritoConIndice(index);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _carritos.removeAt(index);
                              if (_carritoActivo >= _carritos.length) {
                                _carritoActivo = _carritos.length - 1;
                              }
                              if (_carritos.isEmpty) {
                                _carritoActivo = -1;
                                _ocultarBotonFlotante();
                              }
                              Navigator.pop(context); // Cierra el diálogo
                            });
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _carritoActivo = index;
                        Navigator.pop(
                            context); // Cierra el diálogo después de seleccionar
                      });
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cobro',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF004D40),
        actions: [
          if (_carritos.isNotEmpty) ...[
            TextButton.icon(
              onPressed: _agregarNuevoCarrito,
              icon: Icon(Icons.add_shopping_cart, color: Colors.white),
              label: Row(
                children: [
                  Text('+',
                      style: TextStyle(color: Colors.white, fontSize: 28)),
                  SizedBox(width: 4),
                  Text('Nuevo', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _mostrarDialogoCambiarCarrito,
              icon: Icon(Icons.swap_horiz, color: Colors.white),
              label: Row(
                children: [
                  Text('⇄',
                      style: TextStyle(color: Colors.white, fontSize: 24)),
                  SizedBox(width: 4),
                  Text('Cambiar', style: TextStyle(color: Colors.white)),
                ],
              ),
            )
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar producto',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filtrarProductos,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _productosFiltrados.length,
              itemBuilder: (context, index) {
                final producto = _productosFiltrados[index];
                return ListTile(
                  title: Text(producto['nombre']),
                  subtitle: Text('Precio: \$${producto['precio']}'),
                  trailing: ElevatedButton(
                    onPressed: () => _agregarAlCarrito(producto['nombre']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF004D40),
                    ),
                    child: Text(
                      'Agregar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _carritos.isNotEmpty
          ? FloatingActionButton(
              onPressed: _mostrarCarrito,
              backgroundColor: Color(0xFF004D40),
              child: Icon(Icons.shopping_cart, color: Colors.white),
            )
          : null,
    );
  }
}
