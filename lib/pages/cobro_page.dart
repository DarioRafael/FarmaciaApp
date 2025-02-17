import 'package:flutter/material.dart';
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
  final List<Map<String, dynamic>> _productos = [
    {'id': 1, 'nombre': 'Paracetamol 500mg', 'stock': 100, 'precio': 15.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD)},
    {'id': 2, 'nombre': 'Ibuprofeno 400mg', 'stock': 85, 'precio': 18.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD)},
    {'id': 3, 'nombre': 'Omeprazol 20mg', 'stock': 70, 'precio': 25.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD)},
    {'id': 4, 'nombre': 'Loratadina 10mg', 'stock': 90, 'precio': 12.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD)},
    {'id': 5, 'nombre': 'Aspirina 500mg', 'stock': 120, 'precio': 10.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD)},
    {'id': 6, 'nombre': 'Amoxicilina 500mg', 'stock': 60, 'precio': 35.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD)},
    {'id': 7, 'nombre': 'Cetirizina 10mg', 'stock': 75, 'precio': 15.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD)},
    {'id': 8, 'nombre': 'Naproxeno 250mg', 'stock': 80, 'precio': 20.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD)},
    {'id': 9, 'nombre': 'Ranitidina 150mg', 'stock': 65, 'precio': 22.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD)},
    {'id': 10, 'nombre': 'Metformina 850mg', 'stock': 55, 'precio': 28.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD)},
    {'id': 11, 'nombre': 'Jarabe para la Tos', 'stock': 45, 'precio': 45.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5)},
    {'id': 12, 'nombre': 'Suspensión Pediátrica', 'stock': 40, 'precio': 38.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5)},
    {'id': 13, 'nombre': 'Antiacido Oral', 'stock': 50, 'precio': 30.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5)},
    {'id': 14, 'nombre': 'Vitamina C Líquida', 'stock': 60, 'precio': 42.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5)},
    {'id': 15, 'nombre': 'Hierro Líquido', 'stock': 35, 'precio': 48.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5)},
    {'id': 16, 'nombre': 'Multivitamínico Líquido', 'stock': 40, 'precio': 55.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5)},
    {'id': 17, 'nombre': 'Zinc Líquido', 'stock': 30, 'precio': 40.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5)},
    {'id': 18, 'nombre': 'Calcio Líquido', 'stock': 45, 'precio': 52.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5)},
    {'id': 19, 'nombre': 'Probiótico Líquido', 'stock': 25, 'precio': 65.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5)},
    {'id': 20, 'nombre': 'Magnesio Líquido', 'stock': 35, 'precio': 58.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5)},
  ];

  final List<Map<String, dynamic>> _carritos = [];
  int _carritoActivo = -1;
  List<Map<String, dynamic>> _productosFiltrados = [];
  String _query = '';
  List<String> _categorias = ['Todos', 'Categoría 1', 'Categoría 2'];
  String _categoriaSeleccionada = 'Todos';
  final TextEditingController _searchController = TextEditingController();
  double availableMoney = 0.0;
  double ingresos = 0.0;
  double egresos = 0.0;
  bool _isLoading = true;
  final ColorScheme _colorScheme = ColorScheme.fromSeed(
    seedColor: Color(0xFF039BE5),
    primary: Color(0xFF039BE5),
    secondary: Color(0xFF81D4FA),
    background: Colors.white,
    surface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Color(0xFF01579B),
  );

  late TextTheme _textTheme;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrarProductos);
    _loadProductos();
    _loadCategorias();
  }

  void _loadProductos() {
    setState(() {
      _productosFiltrados = _productos;
      _isLoading = false;
    });
  }

  void _loadCategorias() {
    setState(() {
      _categorias = ['Todos', 'Tabletas', 'Bebibles'];
    });
  }

  void _filtrarProductos() {
    setState(() {
      _query = _searchController.text;
      if (_query.isEmpty && _categoriaSeleccionada == 'Todos') {
        _productosFiltrados = _productos;
      } else {
        _productosFiltrados = _productos.where((producto) {
          final nombreProducto = producto['nombre'].toString().toLowerCase();
          final categoriaProducto = producto['categoria'] as String;
          final matchNombre = nombreProducto.contains(_query.toLowerCase());
          final matchCategoria = _categoriaSeleccionada == 'Todos' ||
              categoriaProducto == _categoriaSeleccionada;
          return matchNombre && matchCategoria;
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
        } else {
          _mostrarNotificacion('No se puede agregar más de $stockDisponible unidades de $nombreProducto.');
        }
      } else {
        carritoActual[nombreProducto] = 1;
      }

      _productosFiltrados = _productos
          .where((producto) =>
      producto['nombre'].toLowerCase().contains(_query.toLowerCase()) &&
          (_categoriaSeleccionada == 'Todos' ||
              producto['categoria'] == _categoriaSeleccionada))
          .toList();

      if (_carritos.isNotEmpty && carritoActual.isNotEmpty) {
        _mostrarBotonFlotante();
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
                                  min: 0,
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
                                    _actualizarCantidad(entry.key, 0);
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
                        Navigator.pop(context);
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

  void _confirmarVenta() async {
    if (_carritoActivo == -1 || _carritos[_carritoActivo].isEmpty) {
      _mostrarNotificacion('No hay productos en el carrito');
      return;
    }

    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_colorScheme.primary),
                  ),
                  SizedBox(height: 16),
                  Text('Procesando venta...'),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Simular proceso de venta
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      // Actualizar stock
      _carritos[_carritoActivo].forEach((nombreProducto, cantidad) {
        final productoIndex = _productos.indexWhere((p) => p['nombre'] == nombreProducto);
        if (productoIndex != -1) {
          _productos[productoIndex]['stock'] -= cantidad;
        }
      });

      _vaciarCarrito();
      _carritos.removeAt(_carritoActivo);
      if (_carritos.isEmpty) {
        _carritoActivo = -1;
        _ocultarBotonFlotante();
      } else if (_carritoActivo >= _carritos.length) {
        _carritoActivo = _carritos.length - 1;
      }
    });

    // Cerrar diálogo de carga y mostrar mensaje de éxito
    Navigator.of(context).pop(); // Cerrar diálogo de carga
    Navigator.of(context).pop(); // Cerrar modal del carrito
    _mostrarNotificacion('Venta realizada exitosamente');
  }

  void _mostrarBotonFlotante() {
    setState(() {});
  }

  void _ocultarBotonFlotante() {
    setState(() {});
  }
//
  @override
  Widget build(BuildContext context) {
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
    );
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
        color: producto['color'] ?? Colors.white60,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
    );
  }
}