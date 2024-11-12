import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CobroPage extends StatefulWidget {
  const CobroPage({super.key});

  @override
  _CobroPageState createState() => _CobroPageState();
}

class _CobroPageState extends State<CobroPage> {
  final List<Map<String, dynamic>> _productos = [];
  final List<Map<String, dynamic>> _carritos = [];
  int _carritoActivo = -1; // Índice del carrito activo
  List<Map<String, dynamic>> _productosFiltrados = [];
  String _query = '';
  List<String> _categorias = ['Todos'];
  String _categoriaSeleccionada = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  final String baseUrl = 'https://modelo-server.vercel.app/api/v1';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrarProductos);
    _loadProductos();
    _loadCategorias();
  }

  Future<void> _loadProductos() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/productos'));
      if (response.statusCode == 200) {
        final List<dynamic> productos = json.decode(response.body);

        // Usar un Map temporal para detectar y eliminar duplicados por ID
        final Map<int, Map<String, dynamic>> productosUnicos = {};

        for (var p in productos) {
          final id = p['IDProductos'];
          // Solo guarda el producto si no existe uno con ese ID
          if (!productosUnicos.containsKey(id)) {
            productosUnicos[id] = {
              'nombre': p['Nombre'],
              'stock': p['Stock'],
              'precio': p['Precio'].toDouble(),
              'categoria': p['Categoria'],
            };
          }
        }

        setState(() {
          // Convertir el Map de productos únicos a List
          _productos.addAll(productosUnicos.values.toList());
          _productosFiltrados = _productos;
        });
      }
    } catch (e) {
      _mostrarNotificacion('Error al cargar productos');
    }
  }

  Future<void> _loadCategorias() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categorias'));
      if (response.statusCode == 200) {
        final List<dynamic> categorias = json.decode(response.body);
        final Set<String> categoriasUnicas = {
          ...categorias.map((c) => c['Nombre'].toString())
        };
        setState(() {
          _categorias = categoriasUnicas.toList()..sort();
          _categorias.insert(0, 'Todos'); // Insertar "Todos" al inicio
        });
      }
    } catch (e) {
      _mostrarNotificacion('Error al cargar categorias');
    }
  }

  void _filtrarProductos() {
    setState(() {
      _query = _searchController.text;
      if (_query.isEmpty && _categoriaSeleccionada == 'Todos') {
        _productosFiltrados = _productos;
      } else {
        _productosFiltrados = _productos.where((producto) {
          final nombreProducto = producto['nombre'] as String;
          final categoriaProducto = producto['categoria'] as String;
          return nombreProducto.toLowerCase().contains(_query.toLowerCase()) &&
              (_categoriaSeleccionada == 'Todos' ||
                  categoriaProducto == _categoriaSeleccionada);
        }).toList();
      }
    });
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

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    setState(() {
      final nombreProducto = producto['nombre'];
      final stockDisponible = producto['stock'];

      if (stockDisponible == 0) {
        _mostrarNotificacion('No hay stock disponible para $nombreProducto.');
        return;
      }

      if (_carritoActivo == -1) {
        _carritos.add({});
        _carritoActivo = 0;
      }
      final carritoActual = _carritos[_carritoActivo];

      if (carritoActual.containsKey(nombreProducto)) {
        if (carritoActual[nombreProducto]! < stockDisponible) {
          carritoActual[nombreProducto] = carritoActual[nombreProducto]! + 1;
          _mostrarNotificacion('Actualizada la cantidad de $nombreProducto.');
        } else {
          _mostrarNotificacion('No se puede agregar más de $stockDisponible unidades de $nombreProducto.');
        }
      } else {
        carritoActual[nombreProducto] = 1;
        _mostrarNotificacion('Agregado $nombreProducto al carrito.');
      }

      _productosFiltrados = _productos
          .where((producto) =>
      producto['nombre'].toLowerCase().contains(_query.toLowerCase()) &&
          (_categoriaSeleccionada == 'Todos' ||
              producto['categoria'] == _categoriaSeleccionada))
          .toList(); // Actualiza la lista filtrada

      if (_carritos.isNotEmpty && carritoActual.isNotEmpty) {
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
      return carritoActual.values
          .fold(0, (sum, cantidad) => sum + (cantidad as int));
    }
    return 0;
  }

  void _mostrarCarrito() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final hayProductos = _carritoActivo != -1 && _carritos[_carritoActivo].isNotEmpty;

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
                        final stockDisponible = producto['stock'];
                        return ListTile(
                          title: Text('${entry.key}'),
                          subtitle: Row(
                            children: [
                              Expanded(
                                child: DropdownButton<int>(
                                  value: entry.value,
                                  items: List.generate(stockDisponible, (index) => index + 1)
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
                  Text('Unidades totales: ${_contarUnidades()}', style: TextStyle(color: Color(0xFF004D40))),
                  Text('Total a pagar: \$${_calcularTotal()}', style: TextStyle(color: Color(0xFF004D40))),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _vaciarCarrito();
                        Navigator.pop(context); // Cierra el carrito cuando se vacía
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
                    child: Text('Vaciar carrito', style: TextStyle(color: Colors.white)),
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
                      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.02),
                      minimumSize: Size(double.infinity, MediaQuery.of(context).size.height * 0.05),
                    ),
                    child: Text('Confirmar venta', style: TextStyle(color: Colors.white)),
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
                        final stockDisponible = producto['stock'];
                        return ListTile(
                          title: Text('${entry.key}'),
                          subtitle: Row(
                            children: [
                              Expanded(
                                child: DropdownButton<int>(
                                  value: entry.value,
                                  items: List.generate(stockDisponible, (index) => index + 1)
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
                  Text('Unidades totales: ${_contarUnidades()}', style: TextStyle(color: Color(0xFF004D40))),
                  Text('Total a pagar: \$${_calcularTotal()}', style: TextStyle(color: Color(0xFF004D40))),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _vaciarCarrito();
                        Navigator.pop(context); // Cierra el carrito cuando se vacía
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
                    child: Text('Vaciar carrito', style: TextStyle(color: Colors.white)),
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
                      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.02),
                      minimumSize: Size(double.infinity, MediaQuery.of(context).size.height * 0.05),
                    ),
                    child: Text('Confirmar venta', style: TextStyle(color: Colors.white)),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cobro', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF004D40),
        actions: [
          if (_carritos.isNotEmpty) ...[
            TextButton(
              onPressed: _agregarNuevoCarrito,
              child: Row(
                children: [
                  Text('+', style: TextStyle(color: Colors.white, fontSize: 28)),
                  SizedBox(width: 4),
                  Text('Nuevo', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            TextButton(
              onPressed: _mostrarDialogoCambiarCarrito,
              child: Row(
                children: [
                  Text('⇄', style: TextStyle(color: Colors.white, fontSize: 24)),
                  SizedBox(width: 4),
                  Text('Cambiar', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: Column(
          children: [
            if (isSmallScreen) ...[
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar producto',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              SizedBox(height: 16.0),
              Container(
                margin: EdgeInsets.only(bottom: 8.0),
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _categoriaSeleccionada,
                    items: _categorias.map((categoria) {
                      return DropdownMenuItem<String>(
                        value: categoria,
                        child: Text(categoria),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      setState(() {
                        _categoriaSeleccionada = valor!;
                        _filtrarProductos();
                      });
                    },
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar producto',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.0),
                  Container(
                    margin: EdgeInsets.only(bottom: 8.0),
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _categoriaSeleccionada,
                        items: _categorias.map((categoria) {
                          return DropdownMenuItem<String>(
                            value: categoria,
                            child: Text(categoria),
                          );
                        }).toList(),
                        onChanged: (valor) {
                          setState(() {
                            _categoriaSeleccionada = valor!;
                            _filtrarProductos();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isSmallScreen ? 2 : 4, // Más columnas en pantallas grandes
                  childAspectRatio: 0.7, // Ajusta la relación de aspecto
                ),
                itemCount: _productosFiltrados.length,
                itemBuilder: (context, index) {
                  final producto = _productosFiltrados[index];
                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: Colors.lightGreen, // Color piel suave
                            child: Center(
                              child: Text(
                                producto['nombre'][0], // Primera letra del nombre del producto
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                producto['nombre'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                              ),
                              SizedBox(height: 4.0),
                              Text(
                                'Precio: \$${producto['precio']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14.0,
                                ),
                              ),
                              SizedBox(height: 4.0),
                              Text(
                                'Cantidad disponible: ${producto['stock']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14.0,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              ElevatedButton(
                                onPressed: () => _agregarAlCarrito(producto),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF004D40),
                                ),
                                child: Text(
                                  'Agregar',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _carritos.isNotEmpty
          ? Padding(
        padding: EdgeInsets.only(right: 16.0),
        child: ElevatedButton(
          onPressed: _mostrarCarrito,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF004D40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 20.0 : 32.0,
              vertical: isSmallScreen ? 12.0 : 16.0,
            ),
            textStyle: TextStyle(
              fontSize: isSmallScreen ? 16.0 : 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.white),
              SizedBox(width: 8.0),
              Text(
                'Cobrar (${_contarUnidades()})',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      )
          : null,
    );
  }
}
