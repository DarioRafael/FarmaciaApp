import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CobroPage extends StatefulWidget {
  const CobroPage({super.key});

  @override
  _CobroPageState createState() => _CobroPageState();
}

class ResponsiveScalingWidget extends StatelessWidget {
  final Widget child;

  const ResponsiveScalingWidget({super.key, required this.child});

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
  List<Map<String, dynamic>> _productos = [];
  final List<Map<String, dynamic>> _carritos = [];
  int _carritoActivo = -1;
  List<Map<String, dynamic>> _productosFiltrados = [];
  String _query = '';
  List<String> _categorias = ['Todos'];
  String _categoriaSeleccionada = 'Todos';
  final TextEditingController _searchController = TextEditingController();
  double availableMoney = 0.0;
  double ingresos = 0.0;
  double egresos = 0.0;
  bool _isLoading = true;
  bool _showCartFab = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  // API URL
  final String apiUrl = 'https://farmaciaserver-ashen.vercel.app/api/v1/medicamentos';



  // Esquema de colores refinado para blanco con azul elegante
  final ColorScheme _colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2196F3),
    brightness: Brightness.light,
    primary: const Color(0xFF1976D2),
    primaryContainer: const Color(0xFFBBDEFB),
    secondary: const Color(0xFF42A5F5),
    secondaryContainer: const Color(0xFFE3F2FD),
    surface: Colors.white,
    background: const Color(0xFFF5F9FF),
    error: const Color(0xFFB00020),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: const Color(0xFF263238),
    onBackground: const Color(0xFF263238),
    onError: Colors.white,
  );


  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrarProductos);
    _loadProductos();
    _loadCategorias();

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

  Future<void> _fetchProductosFromAPI() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        // Transform API data and sort alphabetically
        _productos = jsonData.map((medicamento) {
          return {
            'id': medicamento['ID'], // Add this line to include the ID
            'nombre': medicamento['NombreMedico'],
            'nombreGenerico': medicamento['NombreGenerico'],
            'categoria': _determinarCategoria(medicamento['FormaFarmaceutica']),
            'precio': medicamento['Precio'],
            'stock': medicamento['UnidadesPorCaja'],
            'color': _obtenerColorPorCategoria(medicamento['FormaFarmaceutica']),
            'fabricante': medicamento['Fabricante'],
            'contenido': medicamento['Contenido'],
            'fechaCaducidad': medicamento['FechaCaducidad'],
          };
        }).toList()
          ..sort((a, b) => a['nombre'].toString().compareTo(b['nombre'].toString()));

        // Update filtered products
        _productosFiltrados = List.from(_productos);
        _extraerCategorias();
      } else {
        _mostrarNotificacion('Error al cargar productos: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      _mostrarNotificacion('Error de conexión: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// Helper methods
  String _determinarCategoria(String formaFarmaceutica) {
    final formaLower = formaFarmaceutica.toLowerCase();
    if (formaLower.contains('pastilla') || formaLower.contains('tableta') || formaLower.contains('cápsula')) {
      return 'Tabletas';
    } else if (formaLower.contains('bebibles') || formaLower.contains('suspensión') || formaLower.contains('líquido')) {
      return 'Bebibles';
    } else {
      return 'Otros';
    }
  }

  Color _obtenerColorPorCategoria(String formaFarmaceutica) {
    final categoria = _determinarCategoria(formaFarmaceutica);
    if (categoria == 'Tabletas') {
      return const Color(0xFFE3F2FD); // Light blue
    } else if (categoria == 'Bebibles') {
      return const Color(0xFFE8F5E9); // Light green
    } else {
      return const Color(0xFFFFF3E0); // Light orange
    }
  }

  void _extraerCategorias() {
    final categoriasSet = _productos.map((p) => p['categoria'] as String).toSet();
    _categorias = ['Todos', ...categoriasSet];
  }


// Replace the existing _loadProductos and _loadCategorias methods
  void _loadProductos() {
    _fetchProductosFromAPI();
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
          final nombreGenerico = producto['nombreGenerico'].toString().toLowerCase();
          final categoriaProducto = producto['categoria'] as String;
          final matchNombre = nombreProducto.contains(_query.toLowerCase()) ||
              nombreGenerico.contains(_query.toLowerCase());
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
          duration: const Duration(seconds: 2),
          backgroundColor: isError ? _colorScheme.error : _colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
                    margin: const EdgeInsets.only(top: 12),
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Encabezado del carrito
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            color: _colorScheme.primary,
                            size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Carrito de Compras',
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: _colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

                  const Divider(height: 32, thickness: 1, indent: 24, endIndent: 24),

                  // Lista de productos en el carrito
                  Expanded(
                    child: hayProductos
                        ? ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                          margin: const EdgeInsets.only(bottom: 16),
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
                                const SizedBox(width: 16),

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
                                      const SizedBox(height: 4),
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
                                          const Spacer(),
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
                                  margin: const EdgeInsets.only(left: 8),
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
                                        constraints: const BoxConstraints(
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
                                        constraints: const BoxConstraints(
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
                          const SizedBox(height: 16),
                          Text(
                            'El carrito está vacío',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
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
                        const SizedBox(height: 20),

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
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                            const SizedBox(width: 16),

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
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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

  void _confirmarVenta() {
    if (_carritoActivo == -1 || _carritos[_carritoActivo].isEmpty) {
      _mostrarNotificacion('No hay productos en el carrito', isError: true);
      return;
    }

    final double total = _calcularTotal();

    // Cerrar el modal de carrito y mostrar el procesamiento de pago
    Navigator.of(context).pop();
    _mostrarDialogoPago(total);
  }

  void _mostrarDialogoPago(double total) {
    final TextEditingController montoEntregadoController = TextEditingController();
    double cambio = 0.0;
    bool mostrarCambio = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                backgroundColor: Colors.white,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Título
                      Text(
                        'Procesar pago',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Resumen de la compra
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Lista de productos reducida
                            ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _carritos[_carritoActivo].length > 3 ? 3 : _carritos[_carritoActivo].length,
                                itemBuilder: (context, index) {
                                  final entry = _carritos[_carritoActivo].entries.elementAt(index);
                                  final producto = _productos.firstWhere((p) => p['nombre'] == entry.key);
                                  final precio = producto['precio'] as double;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${entry.value} x ${entry.key}',
                                            style: GoogleFonts.montserrat(fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '\$${(precio * entry.value).toStringAsFixed(2)}',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                            ),

                            // Si hay más productos
                            if (_carritos[_carritoActivo].length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '... y ${_carritos[_carritoActivo].length - 3} productos más',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),

                            const Divider(height: 24),

                            // Total
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '\$${total.toStringAsFixed(2)}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Campo para monto entregado
                      TextField(
                        controller: montoEntregadoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Monto entregado por el cliente',
                          prefixIcon: Icon(Icons.paid, color: _colorScheme.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _colorScheme.primary, width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            if (value.isNotEmpty) {
                              try {
                                final montoEntregado = double.parse(value);
                                cambio = montoEntregado - total;
                                mostrarCambio = true;
                              } catch (e) {
                                mostrarCambio = false;
                              }
                            } else {
                              mostrarCambio = false;
                            }
                          });
                        },
                      ),

                      // Mostrar cambio si aplica
                      if (mostrarCambio)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cambio >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cambio >= 0 ? Colors.green.shade300 : Colors.red.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  cambio >= 0 ? 'Cambio a devolver:' : 'Falta por pagar:',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: cambio >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                                Text(
                                  '\$${cambio.abs().toStringAsFixed(2)}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: cambio >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Botones
                      Row(
                        children: [
                          // Botón cancelar
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                side: BorderSide(color: _colorScheme.primary),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                'Cancelar',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Botón confirmar
                          Expanded(
                            child: ElevatedButton(
                              onPressed: mostrarCambio && cambio >= 0
                                  ? () => _procesarVentaFinal(total, double.parse(montoEntregadoController.text), cambio)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
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
              );
            }
        );
      },
    );
  }

  void _procesarVentaFinal(double total, double montoEntregado, double cambio) async {
    Navigator.of(context).pop(); // Close payment dialog

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Procesando venta...',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final idVenta = DateTime.now().millisecondsSinceEpoch % 1000000; // Reduced to 6 digits
      final fechaVenta = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
      bool hasError = false;

      // First, update the stock in the database for each product
      for (var entry in _carritos[_carritoActivo].entries) {
        final producto = _productos.firstWhere((p) => p['nombre'] == entry.key);
        final cantidad = entry.value;
        final idProducto = producto['id'] ?? 1; // Make sure your products have IDs

        // Update the stock in the database
        final updateStockResponse = await http.put(
          Uri.parse('https://farmaciaserver-ashen.vercel.app/api/v1/medicamentos/$idProducto/stock'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'cantidad': cantidad, // The amount to reduce
          }),
        );

        if (updateStockResponse.statusCode != 200) {
          hasError = true;
          throw Exception('Error al actualizar el stock del producto: ${producto['nombre']}');
        }
      }

      // Then, register the sales
      for (var entry in _carritos[_carritoActivo].entries) {
        final producto = _productos.firstWhere((p) => p['nombre'] == entry.key);
        final cantidad = entry.value;
        final precioUnitario = producto['precio'] as double;
        final precioSubtotal = precioUnitario * cantidad;
        final idProducto = producto['id'] ?? 1;

        final response = await http.post(
          Uri.parse('https://farmaciaserver-ashen.vercel.app/api/v1/ventas'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'IDVenta': idVenta,
            'IDProducto': idProducto,
            'Stock': cantidad,
            'PrecioUnitario': precioUnitario,
            'PrecioSubtotal': precioSubtotal,
            'FechaVenta': fechaVenta
          }),
        );

        if (response.statusCode != 201) {
          hasError = true;
          break;
        }
      }

      // Create a detailed description with product names and quantities
      final List<String> detalles = _carritos[_carritoActivo].entries.map((entry) {
        return "${entry.key} (${entry.value} uds)";
      }).toList();

      final String detalleProductos = detalles.join(", ");
      final descripcionVenta = "Venta #$idVenta - $detalleProductos";

      // Register the transaction as an income with detailed description
      final transaccionResponse = await http.post(
        Uri.parse('https://farmaciaserver-ashen.vercel.app/api/v1/transacciones'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'descripcion': descripcionVenta,
          'monto': total,
          'tipo': 'ingreso',
          'fecha': fechaVenta
        }),
      );

      if (transaccionResponse.statusCode != 201) {
        print('Error registrando transacción: ${transaccionResponse.body}');
        // Continue with the process even if transaction record fails
      }
//
      if (!hasError) {
        // Instead of manually updating stock, reload products from the API
        _vaciarCarrito();
        _carritos.removeAt(_carritoActivo);

        if (_carritos.isEmpty) {
          _carritoActivo = -1;
          _showCartFab = false;
          _fabAnimationController.reverse();
        } else if (_carritoActivo >= _carritos.length) {
          _carritoActivo = _carritos.length - 1;
        }

        // Reload the products from the API
        _loadProductos();

        Navigator.of(context).pop(); // Close loading dialog
        _mostrarDialogoExitoConCambio(total, montoEntregado, cambio);
      } else {
        throw Exception('Error al registrar las ventas en el servidor');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _mostrarNotificacion('Error al procesar la venta: ${e.toString()}', isError: true);
      print('Error en venta: $e');
    }
  }
// Método auxiliar para mostrar el diálogo de éxito
  void _mostrarDialogoExito() {
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0.0, 10.0),
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
                  const SizedBox(height: 16),
                  Text(
                    '¡Venta Exitosa!',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La transacción se ha completado correctamente',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
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
        }
    );
  }
  void _mostrarDialogoExitoConCambio(double total, double montoEntregado, double cambio) {
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0.0, 10.0),
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
                  const SizedBox(height: 16),
                  Text(
                    '¡Venta Exitosa!',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La transacción se ha completado correctamente',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Información del pago
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildPaymentInfoRow('Total', '\$${total.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _buildPaymentInfoRow('Monto entregado', '\$${montoEntregado.toStringAsFixed(2)}'),
                        const Divider(height: 16),
                        _buildPaymentInfoRow('Cambio', '\$${cambio.toStringAsFixed(2)}',
                            isHighlighted: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
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
        }
    );
  }

  Widget _buildPaymentInfoRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: isHighlighted ? 16 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
            color: isHighlighted ? _colorScheme.primary : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: isHighlighted ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isHighlighted ? _colorScheme.primary : Colors.grey[800],
          ),
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.montserratTextTheme(Theme.of(context).textTheme);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Venta de Productos',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        backgroundColor: const Color(0xFFBBDEFB), // Light blue color
      ),



      backgroundColor: _colorScheme.surface,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // Barra superior con búsqueda y filtro
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
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
                            fillColor: _colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Dropdown para filtrar por categoría
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _categoriaSeleccionada,
                            icon: Icon(Icons.filter_list, color: _colorScheme.primary),
                            style: textTheme.titleMedium,
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
                    const SizedBox(height: 16),
                    Text(
                      'No se encontraron productos',
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Intenta con otra búsqueda',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              )
                  : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveWrapper.of(context).isMobile ? 1 :
                  ResponsiveWrapper.of(context).isTablet ? 2 : 5, // 5 columns for desktop
                  childAspectRatio: ResponsiveWrapper.of(context).isMobile ? 2.5 :
                  ResponsiveWrapper.of(context).isTablet ? 0.8 : 1.0, // 1.0 ratio for desktop
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
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
                      borderRadius: BorderRadius.circular(12),
                      splashColor: _colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagen más pequeña
                            Expanded(
                              flex: 3,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: producto['color'],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    producto['categoria'] == 'Tabletas'
                                        ? Icons.medication_outlined
                                        : Icons.liquor_outlined,
                                    color: _colorScheme.primary,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Información más compacta
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    producto['nombre'],
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: sinStock ? Colors.grey : null,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    producto['nombreGenerico'],
                                    style: textTheme.bodySmall?.copyWith(
                                      color: sinStock ? Colors.grey : Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Contenido: ${producto['contenido']}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: sinStock ? Colors.grey : Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '\$${producto['precio'].toStringAsFixed(2)}',
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: sinStock ? Colors.grey : _colorScheme.primary,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: sinStock ? Colors.red[50] : _colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          sinStock ? 'Agotado' : 'Stock: ${producto["stock"]}',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: sinStock ? Colors.red[400] : _colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 10,
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
          icon: const Icon(Icons.shopping_cart_outlined),
          label: Text(
            '${_contarUnidades()} items - \$${_calcularTotal().toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}