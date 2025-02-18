import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:google_fonts/google_fonts.dart';

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

class _CobroPageState extends State<CobroPage> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _productos = [
    {'id': 1, 'nombre': 'Paracetamol 500mg', 'stock': 100, 'precio': 15.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD), 'image': 'assets/images/tablets.png'},
    {'id': 2, 'nombre': 'Ibuprofeno 400mg', 'stock': 85, 'precio': 18.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD), 'image': 'assets/images/tablets.png'},
    {'id': 3, 'nombre': 'Omeprazol 20mg', 'stock': 70, 'precio': 25.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD), 'image': 'assets/images/tablets.png'},
    {'id': 4, 'nombre': 'Loratadina 10mg', 'stock': 90, 'precio': 12.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD), 'image': 'assets/images/tablets.png'},
    {'id': 5, 'nombre': 'Aspirina 500mg', 'stock': 120, 'precio': 10.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD), 'image': 'assets/images/tablets.png'},
    {'id': 6, 'nombre': 'Amoxicilina 500mg', 'stock': 60, 'precio': 35.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD), 'image': 'assets/images/tablets.png'},
    {'id': 7, 'nombre': 'Cetirizina 10mg', 'stock': 75, 'precio': 15.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD), 'image': 'assets/images/tablets.png'},
    {'id': 8, 'nombre': 'Naproxeno 250mg', 'stock': 80, 'precio': 20.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD), 'image': 'assets/images/tablets.png'},
    {'id': 9, 'nombre': 'Ranitidina 150mg', 'stock': 65, 'precio': 22.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD), 'image': 'assets/images/tablets.png'},
    {'id': 10, 'nombre': 'Metformina 850mg', 'stock': 55, 'precio': 28.0, 'categoria': 'Tabletas', 'color': Color(0xFFE3F2FD), 'image': 'assets/images/tablets.png'},
    {'id': 11, 'nombre': 'Jarabe para la Tos', 'stock': 45, 'precio': 45.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5), 'image': 'assets/images/syrup.png'},
    {'id': 12, 'nombre': 'Suspensión Pediátrica', 'stock': 40, 'precio': 38.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5), 'image': 'assets/images/syrup.png'},
    {'id': 13, 'nombre': 'Antiacido Oral', 'stock': 50, 'precio': 30.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5), 'image': 'assets/images/syrup.png'},
    {'id': 14, 'nombre': 'Vitamina C Líquida', 'stock': 60, 'precio': 42.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5), 'image': 'assets/images/syrup.png'},
    {'id': 15, 'nombre': 'Hierro Líquido', 'stock': 35, 'precio': 48.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5), 'image': 'assets/images/syrup.png'},
    {'id': 16, 'nombre': 'Multivitamínico Líquido', 'stock': 40, 'precio': 55.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5), 'image': 'assets/images/syrup.png'},
    {'id': 17, 'nombre': 'Zinc Líquido', 'stock': 30, 'precio': 40.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5), 'image': 'assets/images/syrup.png'},
    {'id': 18, 'nombre': 'Calcio Líquido', 'stock': 45, 'precio': 52.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5), 'image': 'assets/images/syrup.png'},
    {'id': 19, 'nombre': 'Probiótico Líquido', 'stock': 25, 'precio': 65.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5), 'image': 'assets/images/syrup.png'},
    {'id': 20, 'nombre': 'Magnesio Líquido', 'stock': 35, 'precio': 58.0, 'categoria': 'Bebibles', 'color': Color(0xFFF3E5F5), 'image': 'assets/images/syrup.png'},
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
  bool _showCartFab = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;



  // Esquema de colores refinado para blanco con azul elegante
  final ColorScheme _colorScheme = ColorScheme.fromSeed(
    seedColor: Color(0xFF2196F3),
    brightness: Brightness.light,
    primary: Color(0xFF1976D2),
    primaryContainer: Color(0xFFBBDEFB),
    secondary: Color(0xFF42A5F5),
    secondaryContainer: Color(0xFFE3F2FD),
    surface: Colors.white,
    background: Color(0xFFF5F9FF),
    error: Color(0xFFB00020),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Color(0xFF263238),
    onBackground: Color(0xFF263238),
    onError: Colors.white,
  );


  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrarProductos);
    _loadProductos();
    _loadCategorias();

    // Configuración de la animación para el botón flotante
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
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

  void _mostrarNotificacion(String mensaje, {bool isError = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(mensaje),
          duration: Duration(seconds: 2),
          backgroundColor: isError ? _colorScheme.error : _colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    });
  }

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    setState(() {
      final nombreProducto = producto['nombre'];
      final stockDisponible = producto['stock'];

      if (stockDisponible == 0) {
        _mostrarNotificacion('No hay stock disponible para $nombreProducto.', isError: true);
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
          _mostrarNotificacion('No se puede agregar más de $stockDisponible unidades de $nombreProducto.', isError: true);
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
        _showCartFab = true;
        _fabAnimationController.forward();
      }
    });
  }

  void _vaciarCarrito() {
    setState(() {
      if (_carritoActivo != -1) {
        _carritos[_carritoActivo].clear();
        _mostrarNotificacion('Carrito vacío.');

        if (_carritos[_carritoActivo].isEmpty) {
          _showCartFab = false;
          _fabAnimationController.reverse();
        }
      }
    });
  }

  void _actualizarCantidad(String nombreProducto, int nuevaCantidad) {
    if (_carritoActivo != -1) {
      setState(() {
        if (_carritos[_carritoActivo].containsKey(nombreProducto)) {
          if (nuevaCantidad <= 0) {
            _carritos[_carritoActivo].remove(nombreProducto);
          } else {
            _carritos[_carritoActivo][nombreProducto] = nuevaCantidad;
          }

          if (_carritos[_carritoActivo].isEmpty) {
            _showCartFab = false;
            _fabAnimationController.reverse();
          }
        }
      });
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
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final hayProductos = _carritoActivo != -1 && _carritos[_carritoActivo].isNotEmpty;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle para arrastrar
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Encabezado del carrito
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            color: _colorScheme.primary,
                            size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Carrito de Compras',
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: _colorScheme.primary,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_contarUnidades()} items',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 32, thickness: 1, indent: 24, endIndent: 24),

                  // Lista de productos en el carrito
                  Expanded(
                    child: hayProductos
                        ? ListView(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      children: _carritos[_carritoActivo].entries.map((entry) {
                        final producto = _productos.firstWhere(
                                (producto) => producto['nombre'] == entry.key);
                        final stockDisponible = producto['stock'];
                        final precio = producto['precio'] as double;

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          margin: EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Imagen/Icono del producto
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: producto['color'] ?? _colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    producto['categoria'] == 'Tabletas'
                                        ? Icons.medication_outlined
                                        : Icons.liquor_outlined,
                                    color: _colorScheme.primary,
                                    size: 30,
                                  ),
                                ),
                                SizedBox(width: 16),

                                // Información del producto
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: _colorScheme.onSurface,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '\$${precio.toStringAsFixed(2)}',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: _colorScheme.primary,
                                            ),
                                          ),
                                          Text(
                                            ' × ${entry.value}',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Spacer(),
                                          Text(
                                            '\$${(precio * entry.value).toStringAsFixed(2)}',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: _colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Controles de cantidad
                                Container(
                                  margin: EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    color: _colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove,
                                            color: entry.value > 1 ? _colorScheme.primary : Colors.grey,
                                            size: 20),
                                        onPressed: entry.value > 1
                                            ? () => setState(() {
                                          _actualizarCantidad(entry.key, entry.value - 1);
                                        })
                                            : null,
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 36,
                                        child: Text(
                                          '${entry.value}',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.add,
                                            color: entry.value < stockDisponible ? _colorScheme.primary : Colors.grey,
                                            size: 20),
                                        onPressed: entry.value < stockDisponible
                                            ? () => setState(() {
                                          _actualizarCantidad(entry.key, entry.value + 1);
                                        })
                                            : null,
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Botón para eliminar
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      color: Colors.grey[400],
                                      size: 20),
                                  onPressed: () => setState(() {
                                    _actualizarCantidad(entry.key, 0);
                                  }),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    )
                        : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 80,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'El carrito está vacío',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Agrega productos para comenzar',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Resumen y botones de acción
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Resumen
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total a pagar',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              '\$${_calcularTotal().toStringAsFixed(2)}',
                              style: GoogleFonts.montserrat(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        // Botones de acción
                        Row(
                          children: [
                            // Botón para vaciar carrito
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                onPressed: hayProductos
                                    ? () {
                                  _vaciarCarrito();
                                  Navigator.pop(context);
                                }
                                    : null,
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  side: BorderSide(color: _colorScheme.primary),
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(
                                  'Vaciar',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),

                            // Botón para confirmar venta
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: hayProductos ? _confirmarVenta : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Confirmar Venta',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
      _mostrarNotificacion('No hay productos en el carrito', isError: true);
      return;
    }

    // Mostrar diálogo de carga con estilo mejorado
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_colorScheme.primary),
                  strokeWidth: 3,
                ),
                SizedBox(height: 24),
                Text(
                  'Procesando venta...',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Por favor espere',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
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
        _showCartFab = false;
        _fabAnimationController.reverse();
      } else if (_carritoActivo >= _carritos.length) {
        _carritoActivo = _carritos.length - 1;
      }
    });

    // Cerrar diálogo de carga y mostrar mensaje de éxito
    Navigator.of(context).pop(); // Cerrar diálogo de carga
    Navigator.of(context).pop(); // Cerrar modal del carrito

    // Mostrar animación de éxito
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: const Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: _colorScheme.primary,
                    size: 80,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '¡Venta Exitosa!',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'La transacción se ha completado correctamente',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                      elevation: 0,
                    ),
                    child: Text(
                      'Aceptar',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final _textTheme = GoogleFonts.montserratTextTheme(Theme.of(context).textTheme);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Venta de Productos',
          style: _textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        backgroundColor: Color(0xFFBBDEFB), // Light blue color
      ),



      backgroundColor: _colorScheme.background,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // Barra superior con búsqueda y filtro
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  Row(
                    children: [
                      // Campo de búsqueda
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar productos...',
                            prefixIcon: Icon(Icons.search, color: _colorScheme.primary),
                            filled: true,
                            fillColor: _colorScheme.surfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Dropdown para filtrar por categoría
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _categoriaSeleccionada,
                            icon: Icon(Icons.filter_list, color: _colorScheme.primary),
                            style: _textTheme.titleMedium,
                            onChanged: (String? newValue) {
                              setState(() {
                                _categoriaSeleccionada = newValue!;
                                _filtrarProductos();
                              });
                            },
                            items: _categorias.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Lista de productos
            Expanded(
              child: _productosFiltrados.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_outlined,
                      size: 80,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No se encontraron productos',
                      style: _textTheme.headlineSmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Intenta con otra búsqueda',
                      style: _textTheme.titleMedium?.copyWith(
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              )
                  : GridView.builder(
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveWrapper.of(context).isMobile ? 2 :
                  ResponsiveWrapper.of(context).isTablet ? 3 : 4,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _productosFiltrados.length,
                itemBuilder: (context, index) {
                  final producto = _productosFiltrados[index];
                  final stockDisponible = producto['stock'];
                  final sinStock = stockDisponible == 0;

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: sinStock ? null : () => _agregarAlCarrito(producto),
                      borderRadius: BorderRadius.circular(15),
                      splashColor: _colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagen o icono del producto
                            Expanded(
                              flex: 4,
                              child: Center(
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: producto['color'],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    producto['categoria'] == 'Tabletas'
                                        ? Icons.medication_outlined
                                        : Icons.liquor_outlined,
                                    color: _colorScheme.primary,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 12),

                            // Información del producto
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    producto['nombre'],
                                    style: _textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: sinStock ? Colors.grey : null,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    producto['categoria'],
                                    style: _textTheme.bodySmall?.copyWith(
                                      color: sinStock ? Colors.grey : Colors.grey[600],
                                    ),
                                  ),
                                  Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '\$${producto['precio'].toStringAsFixed(2)}',
                                        style: _textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: sinStock ? Colors.grey : _colorScheme.primary,
                                        ),
                                      ),
                                      sinStock
                                          ? Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Agotado',
                                          style: _textTheme.bodySmall?.copyWith(
                                            color: Colors.red[400],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                          : Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Stock: ${producto['stock']}',
                                          style: _textTheme.bodySmall?.copyWith(
                                            color: _colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _showCartFab
          ? ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _mostrarCarrito,
          backgroundColor: _colorScheme.primary,
          icon: Icon(Icons.shopping_cart_outlined),
          label: Text(
            '${_contarUnidades()} items - \$${_calcularTotal().toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}