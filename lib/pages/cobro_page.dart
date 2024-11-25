import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';

class CobroPage extends StatefulWidget {
  const CobroPage({super.key});

  @override
  _CobroPageState createState() => _CobroPageState();
}

class ResponsiveScalingWidget extends StatelessWidget {
  final Widget child;

  const ResponsiveScalingWidget({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return child;
      },
    );
  }
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
  double availableMoney = 0.0;
  double ingresos = 0.0;
  double egresos = 0.0;
  bool _isLoading = true;
  final String baseUrl = 'https://modelo-server.vercel.app/api/v1';


  final ColorScheme _colorScheme = ColorScheme.fromSeed(
    seedColor: Color(0xFF2E7D32),
    primary: Color(0xFF2E7D32),
    secondary: Color(0xFF81C784),
    background: Color(0xFFF0F4F0),
    surface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
  );

  // Responsive typography
  late TextTheme _textTheme;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrarProductos);
    _loadProductos();
    _loadCategorias();
    _fetchSaldo();

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
              'id': p['IDProductos'],
              'nombre': p['Nombre'],
              'stock': p['Stock'],
              'precio': p['Precio'].toDouble(),
              'categoria': p['Categoria'],
            };
          }
        }

        setState(() {
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
  Future<void> _fetchSaldo() async {
    final String baseUrl = 'https://modelo-server.vercel.app/api/v1';
    final String saldoEndpoint = '/saldo';

    try {
      final response = await http.get(Uri.parse('$baseUrl$saldoEndpoint'));

      if (response.statusCode == 200) {
        // Verifica la respuesta antes de intentar decodificarla
        final dynamic data = json.decode(response.body);

        // Agrega un log para ver qué tipo de datos estás recibiendo
        print('Respuesta recibida: $data');

        // Cambia la verificación para aceptar un objeto en lugar de una lista
        if (data is Map<String, dynamic> && data.containsKey('baseSaldo')) {
          setState(() {
            availableMoney = data['baseSaldo'].toDouble();
            ingresos = data['totalIngresos'].toDouble();
            egresos = data['totalEgresos'].toDouble();
            _isLoading = false;
          });
        } else {
          throw Exception('Formato inesperado o campo "saldo" no encontrado');
        }
      } else {
        throw Exception('Failed to load saldo');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el saldo: $e')),
      );
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(mensaje),
          duration: Duration(seconds: 2),
        ),
      );
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
          //_mostrarNotificacion('Actualizada la cantidad de $nombreProducto.');
        } else {
          _mostrarNotificacion('No se puede agregar más de $stockDisponible unidades de $nombreProducto.');
        }
      } else {
        carritoActual[nombreProducto] = 1;
        //_mostrarNotificacion('Agregado $nombreProducto al carrito.');
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
    if (_carritoActivo != -1) {
      if (_carritos[_carritoActivo].containsKey(nombreProducto)) {
        _carritos[_carritoActivo][nombreProducto] = nuevaCantidad;
      }
    }
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
                                child: SpinBox(
                                  min: 0, // Permitir llegar a 0
                                  max: stockDisponible.toDouble(),
                                  value: entry.value.toDouble(),
                                  onChanged: (nuevaCantidad) {
                                    setState(() {
                                      _actualizarCantidad(entry.key, nuevaCantidad.toInt());
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                              Text('Precio total: \$${producto['precio'] * entry.value}'),
                              IconButton(
                                icon: Icon(Icons.delete, color: Color(0xFF004D40)),
                                onPressed: () {
                                  setState(() {
                                    _actualizarCantidad(entry.key, 0); // En lugar de eliminar, establecer en 0
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

  double _calcularPrecioTotal() {
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

// Helper method to log response details
  void _logServerResponse(http.Response response) {
    print('Status code: ${response.statusCode}');
    print('Response headers: ${response.headers}');
    print('Response body: ${response.body}');
  }

  Future<void> _registrarVenta(List<Map<String, dynamic>> productosVendidos, double precioTotal) async {
    try {
      // Format products according to the backend expectations
      final productosFormateados = productosVendidos.map((producto) {
        // Find the original product to get its price
        final productoOriginal = _productos.firstWhere(
                (p) => p['id'] == producto['id'],
            orElse: () => throw Exception('Producto no encontrado: ${producto['nombre']}')
        );

        final precioUnitario = productoOriginal['precio'].toDouble();
        final cantidad = producto['cantidadVendida'];

        return {
          'IDProducto': producto['id'],
          'Stock': cantidad,
          'PrecioUnitario': precioUnitario,
          'PrecioSubtotal': precioUnitario * cantidad
        };
      }).toList();

      final ventaData = {
        'productos': productosFormateados,
      };

      print('Enviando datos de venta: ${jsonEncode(ventaData)}');

      final response = await http.post(
        Uri.parse('$baseUrl/ventas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(ventaData),
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        print('Venta registrada correctamente: ${response.body}');
      } else {
        throw Exception('Error al registrar la venta: ${response.body}');
      }
    } catch (e) {
      print('Error al registrar la venta: $e');
      throw e;
    }
  }

  Future<void> _confirmarVenta() async {
    if (_carritoActivo == -1 || _carritos[_carritoActivo].isEmpty) {
      _mostrarNotificacion('No hay productos en el carrito');
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Procesando venta...'),
                ],
              ),
            ),
          );
        },
      );

      // Prepare products for sale
      final productosVendidos = _carritos[_carritoActivo].entries.map((entry) {
        final producto = _productos.firstWhere(
                (p) => p['nombre'] == entry.key,
            orElse: () => throw Exception('Producto no encontrado: ${entry.key}')
        );

        return {
          'id': producto['id'],
          'nombre': entry.key,
          'cantidadVendida': entry.value,
          'stockActual': producto['stock']
        };
      }).toList();

      // Register the sale
      await _registrarVenta(productosVendidos, _calcularPrecioTotal());

      // Update local state
      if (mounted) {
        setState(() {
          _vaciarCarrito();
          _carritos.removeAt(_carritoActivo);
          if (_carritos.isEmpty) {
            _carritoActivo = -1;
            _ocultarBotonFlotante();
          } else if (_carritoActivo >= _carritos.length) {
            _carritoActivo = _carritos.length - 1;
          }
        });

        Navigator.of(context).pop(); // Close loading dialog
        _mostrarNotificacion('Venta confirmada exitosamente');
      }

    } catch (e) {
      print('Error en confirmación de venta: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _mostrarNotificacion('Error al confirmar la venta: ${e.toString()}');
      }
    }
  }

  Future<void> _actualizarStockProducto(int idProducto, int cantidadVendida) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final productoActual = _productos.firstWhere(
            (p) => p['id'] == idProducto,
        orElse: () => {},
      );

      if (productoActual.isEmpty) {
        throw Exception('Producto no encontrado');
      }
      final nuevoStock = productoActual['stock'] - cantidadVendida;

      final response = await http.put(
        Uri.parse('$baseUrl/productos/${idProducto.toString()}'), // Convert idProducto to String
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre': productoActual['nombre'],
          'categoria': productoActual['categoria'],
          'stock': nuevoStock,
          'precio': productoActual['precio'],
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          productoActual['stock'] = nuevoStock;
        });
        _mostrarNotificacion('Stock actualizado correctamente');
      } else {
        _mostrarNotificacion('Error al actualizar el stock');
      }
    } catch (e) {
      _mostrarNotificacion('Error de conexión al actualizar el stock');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _realizarTransaccionIngreso(double monto) async {
    if (monto == null) {
      _mostrarNotificacion('Error: Monto inválido');
      return;
    }

    try {
      final url = Uri.parse('$baseUrl/transaccionesinsert');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'descripcion': 'Venta de productos',
          'monto': monto,
          'tipo': 'ingreso',
          'fecha': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        await _fetchSaldo();
      } else {
        _mostrarNotificacion('Error al confirmar la venta.');
      }
    } catch (e) {
      print('Error en transacción: $e');
      _mostrarNotificacion('Error al procesar la transacción');
    }
  }

  void _mostrarDialogoCarga() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Controlador para la animación de la palomita
            final controller = AnimationController(
              duration: const Duration(milliseconds: 800),
              vsync: Navigator.of(context),
            );

            // Estado inicial
            bool mostrarCheck = false;
            bool mostrarTextoExito = false;

            // Secuencia de animaciones
            Future.delayed(Duration(seconds: 2), () {
              setState(() {
                mostrarCheck = true;
              });

              Future.delayed(Duration(milliseconds: 500), () {
                setState(() {
                  mostrarTextoExito = true;
                });

                // Cerrar el diálogo después de mostrar el éxito
                Future.delayed(Duration(seconds: 1), () {
                  Navigator.of(context).pop();
                });
              });
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              content: Container(
                height: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: mostrarCheck
                          ? Container(
                        key: ValueKey('check'),
                        child: Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 50,
                        ),
                      )
                          : Container(
                        key: ValueKey('spinner'),
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                            strokeWidth: 4,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: mostrarTextoExito
                          ? Text(
                        'Venta Exitosa',
                        key: ValueKey('exito'),
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : Text(
                        'Procesando venta...',
                        key: ValueKey('procesando'),
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
    // Responsive text theming
    _textTheme = Theme.of(context).textTheme.apply(
      bodyColor: _colorScheme.onSurface,
      displayColor: _colorScheme.onSurface,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return ResponsiveScalingWidget(
          child: Scaffold(
            backgroundColor: _colorScheme.background,
            appBar: _buildResponsiveAppBar(constraints),
            body: _buildResponsiveBody(constraints),
            floatingActionButton: _buildResponsiveFloatingButton(constraints),
          ),
        );
      },
    );
  }

  // Responsive AppBar
  PreferredSizeWidget _buildResponsiveAppBar(BoxConstraints constraints) {
    return AppBar(
      title: Text(
        'Punto de Venta',
        style: _textTheme.titleLarge?.copyWith(
          color: _colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: _colorScheme.primary,
      actions: _buildContextualActions(constraints),
    );
  }

  // Context-aware actions
  List<Widget> _buildContextualActions(BoxConstraints constraints) {
    final isCompact = constraints.maxWidth < 600;
    return isCompact
        ? [
      IconButton(
        icon: Icon(Icons.add_shopping_cart, color: _colorScheme.onPrimary),
        onPressed: _agregarNuevoCarrito,
      ),
      IconButton(
        icon: Icon(Icons.swap_horiz, color: _colorScheme.onPrimary),
        onPressed: _mostrarDialogoCambiarCarrito,
      )
    ]
        : [
      TextButton.icon(
        icon: Icon(Icons.add_shopping_cart, color: _colorScheme.onPrimary),
        label: Text('Nuevo Carrito', style: TextStyle(color: _colorScheme.onPrimary)),
        onPressed: _agregarNuevoCarrito,
      ),
      TextButton.icon(
        icon: Icon(Icons.swap_horiz, color: _colorScheme.onPrimary),
        label: Text('Cambiar Carrito', style: TextStyle(color: _colorScheme.onPrimary)),
        onPressed: _mostrarDialogoCambiarCarrito,
      )
    ];
  }

  Widget _buildResponsiveBody(BoxConstraints constraints) {
    final isCompact = constraints.maxWidth < 600;
    final crossAxisCount = isCompact
        ? (constraints.maxWidth < 400 ? 2 : 3)
        : (constraints.maxWidth < 1200 ? 4 : 6);

    return Padding(
      padding: EdgeInsets.all(isCompact ? 4.0 : 8.0),
      child: Column(
        children: [
          _buildAdaptiveSearchSection(isCompact),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: isCompact ? 0.5 : 0.65,
                crossAxisSpacing: isCompact ? 4 : 8,
                mainAxisSpacing: isCompact ? 4 : 8,
              ),
              itemCount: _productosFiltrados.length,
              itemBuilder: (context, index) {
                final producto = _productosFiltrados[index];
                return _buildResponsiveProductCard(producto, isCompact);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Adaptive Search Section
  Widget _buildAdaptiveSearchSection(bool isCompact) {
    return isCompact
        ? Column(
      children: [
        _buildSearchField(),
        SizedBox(height: 8),
        _buildCategoryDropdown(),
      ],
    )
        : Row(
      children: [
        Expanded(child: _buildSearchField()),
        SizedBox(width: 16),
        _buildCategoryDropdown(),
      ],
    );
  }

  // Enhanced Product Card with Responsive Design
  Widget _buildResponsiveProductCard(Map<String, dynamic> producto, bool isCompact) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProductImage(producto),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isCompact ? 8.0 : 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producto['nombre'],
                            style: _textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '\$${producto['precio']}',
                            style: _textTheme.titleMedium?.copyWith(
                              color: _colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Stock: ${producto['stock']}',
                            style: _textTheme.bodySmall?.copyWith(
                              color: _colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _agregarAlCarrito(producto),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: Size(double.infinity, 40),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_shopping_cart, size: 18, color: _colorScheme.onPrimary),
                            SizedBox(width: 8),
                            Text(
                              'Agregar',
                              style: TextStyle(color: _colorScheme.onPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Stock indicator
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: producto['stock'] > 10
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                producto['stock'] > 10 ? 'Disponible' : 'Bajo Stock',
                style: TextStyle(
                  fontSize: 10,
                  color: producto['stock'] > 10 ? Colors.green : Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Responsive Floating Button
  Widget _buildResponsiveFloatingButton(BoxConstraints constraints) {
    final isCompact = constraints.maxWidth < 600;

    return _carritos.isNotEmpty
        ? FloatingActionButton.extended(
      onPressed: _mostrarCarrito,
      backgroundColor: _colorScheme.primary,
      icon: Icon(Icons.shopping_cart, color: _colorScheme.onPrimary),
      label: Text(
        isCompact
            ? '${_contarUnidades()}'
            : 'Cobrar (${_contarUnidades()})',
        style: TextStyle(
          color: _colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    )
        : Container();
  }
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar productos...',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButton<String>(
      value: _categoriaSeleccionada,
      items: _categorias.map((String categoria) {
        return DropdownMenuItem<String>(
          value: categoria,
          child: Text(categoria),
        );
      }).toList(),
      onChanged: (String? nuevaCategoria) {
        setState(() {
          _categoriaSeleccionada = nuevaCategoria!;
          _filtrarProductos();
        });
      },
    );
  }

  Widget _buildProductImage(Map<String, dynamic> producto) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: producto['color'] ?? Colors.white60, // Use the color from the product or default to grey
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
    );
  }


}
