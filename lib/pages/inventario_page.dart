import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  _InventarioPageState createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Todos';
  List<Map<String, dynamic>> _productos = [];
  List<String> _filterOptions = ['Todos'];
  List<bool> _selectedInventories = List.generate(3, (_) => true); // Updated to 3 for local and 2 branches
  bool _isLoading = false;


  List<Map<String, dynamic>> _filteredProducts = [];
  List<List<Map<String, dynamic>>> _allInventories = [];
  List<List<Map<String, dynamic>>> _filteredInventories = [];

  List<Map<String, dynamic>> _almacenProductos = [];
  List<Map<String, dynamic>> _selectedForRestock = [];
  double _totalRestockCost = 0.0;

// Column width definitions
  double idWidth = 60.0;
  double nombreGenericoWidth = 200.0;
  double nombreMedicoWidth = 200.0;
  double fabricanteWidth = 150.0;
  double contenidoWidth = 120.0;
  double formaWidth = 120.0;
  double fechaFabWidth = 120.0;
  double presentacionWidth = 150.0;
  double fechaCadWidth = 120.0;
  double unidadesWidth = 80.0;
  double precioWidth = 80.0;
  double stockWidth = 80.0;
  double actionsWidth = 60.0;


  static const Color primaryBlue = Color(0xFF1A237E); // Dark blue
  static const Color secondaryBlue = Color(0xFF3949AB); // Medium blue
  static const Color lightBlue = Color(0xFFE8EAF6); // Light blue
  final Color white = Colors.white;
  static const Color tableHeaderColor = Color(0xFFE3F2FD); // Very light blue

  final String apiUrl = 'https://farmaciaserver-ashen.vercel.app/api/v1/medicamentos';
  final String apiUrlBranch2 = 'https://farmacia-api.loca.lt/api/medicamentos'; // New API URL

  // @override
  // void initState() {
  //   super.initState();
  //   _searchController.addListener(_filterProducts);
  //   _loadProductsFromApi();
  //   _generateAlmacenProductos();
  // }//Probar de nuevo

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProducts);

    // Primero cargamos la sucursal local
    _loadLocalInventory().then((_) {
      // Luego intentamos cargar las sucursales adicionales
      _loadBranchInventories();
    });

    _generateAlmacenProductos();
  }

  Future<void> _loadProductsFromApi() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _productos = data.map((item) {
            // Assign a color based on forma farmaceutica
            Color itemColor = const Color(0xFFE3F2FD); // Default light blue
            if (item['FormaFarmaceutica'] == 'Tabletas') {
              itemColor = const Color(0xFFE3F2FD);
            } else if (item['FormaFarmaceutica'] == 'Bebibles' ||
                item['FormaFarmaceutica'] == 'Jarabe' ||
                item['FormaFarmaceutica'] == 'Suspensión') {
              itemColor = const Color(0xFFF3E5F5);
            }//Probar de nuevo

            return {
              'id': item['ID'],
              'nombre': item['NombreGenerico'],
              'nombreMedico': item['NombreMedico'],
              'fabricante': item['Fabricante'],
              'contenido': item['Contenido'],
              'categoria': item['FormaFarmaceutica'],
              'fechaFabricacion': DateTime.parse(item['FechaFabricacion']),
              'presentacion': item['Presentacion'],
              'fechaCaducidad': DateTime.parse(item['FechaCaducidad']),
              'unidadesPorCaja': item['UnidadesPorCaja'],
              'precio': item['Precio'].toDouble(),
              'stock': item['Stock'],
              'color': itemColor,
            };
          }).toList();

          _loadCategorias();
          _filterProducts();
          _initializeAllInventories();
          _generateAlmacenProductos();

          _isLoading = false;

        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      setState(() {});
      _showErrorDialog('Error al cargar datos: $e');
    }
  }

  void _generateAlmacenProductos() {
    final random = Random();

    // Ensure productos is not empty
    if (_productos.isEmpty) {
      print("Error: No hay productos disponibles para generar almacén");
      return;
    }

    _almacenProductos = _productos.map((producto) {
      // Generar un stock aleatorio para el almacén (generalmente más alto que el inventario local)
      final almacenStock = random.nextInt(500) + 100; // Entre 100 y 600 unidades

      // Generar un costo de reabastecimiento aleatorio (generalmente menor que el precio de venta)
      final precioVenta = producto['precio'] as double;
      final costoReabastecimiento = (precioVenta * (0.4 + (random.nextDouble() * 0.3))).toStringAsFixed(2);

      return {
        ...producto,
        'almacenStock': almacenStock,
        'costoReabastecimiento': double.parse(costoReabastecimiento),
        'cantidadAReabastecer': 0,
      };
    }).toList();

    // Ordenar productos del almacén por nombre alfabéticamente
    _sortAlmacenProducts();

    setState(() {});
    print("Almacén generado con ${_almacenProductos.length} productos");
  }




  Future<void> _loadLocalInventory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _productos = data.map((item) {
            // Assign a color based on forma farmaceutica
            Color itemColor = const Color(0xFFE3F2FD); // Default light blue
            if (item['FormaFarmaceutica'] == 'Tabletas') {
              itemColor = const Color(0xFFE3F2FD);
            } else if (item['FormaFarmaceutica'] == 'Bebibles' ||
                item['FormaFarmaceutica'] == 'Jarabe' ||
                item['FormaFarmaceutica'] == 'Suspensión') {
              itemColor = const Color(0xFFF3E5F5);
            }

            return {
              'id': item['ID'],
              'nombre': item['NombreGenerico'],
              'nombreMedico': item['NombreMedico'],
              'fabricante': item['Fabricante'],
              'contenido': item['Contenido'],
              'categoria': item['FormaFarmaceutica'],
              'fechaFabricacion': DateTime.parse(item['FechaFabricacion']),
              'presentacion': item['Presentacion'],
              'fechaCaducidad': DateTime.parse(item['FechaCaducidad']),
              'unidadesPorCaja': item['UnidadesPorCaja'],
              'precio': item['Precio'].toDouble(),
              'stock': item['Stock'],
              'color': itemColor,
            };
          }).toList();

          _loadCategorias();
          _filterProducts();
          _generateAlmacenProductos();
        });
      } else {
        throw Exception('Failed to load local inventory');
      }
    } catch (e) {
      _showErrorDialog('Error al cargar inventario local: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _loadBranchInventories() async {
    // Primero asegurarnos que la sucursal local está cargada
    if (_productos.isEmpty) {
      await _loadLocalInventory();
    }

    // Cargar sucursal 2
    try {
      final response = await http.get(Uri.parse(apiUrlBranch2));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Procesar datos de la sucursal 2 con el nuevo formato
        final branchProducts = data.map((item) {
          // Asignar color basado en la forma farmacéutica
          Color itemColor = const Color(0xFFE3F2FD); // Default light blue
          if (item['forma_farmacologica'] == 'Tableta') {
            itemColor = const Color(0xFFE3F2FD);
          } else if (item['forma_farmacologica'] == 'Jarabe' ||
              item['forma_farmacologica'] == 'Suspensión') {
            itemColor = const Color(0xFFF3E5F5);
          }

          return {
            'id': item['id'],
            'nombre': item['nombre_generico'],
            'nombreMedico': item['nombre_medico'],
            'fabricante': item['fabricante'],
            'contenido': item['contenido'],
            'categoria': item['forma_farmacologica'],
            'fechaFabricacion': DateTime.parse(item['fecha_fabricacion']),
            'presentacion': item['presentacion'],
            'fechaCaducidad': DateTime.parse(item['fecha_caducidad']),
            'unidadesPorCaja': item['unidades_por_caja'],
            'precio': double.parse(item['precio'].toString()),
            'stock': item['stock'],
            'color': itemColor,
          };
        }).toList();

        setState(() {
          // Agregar esta sucursal a los inventarios
          if (_allInventories.isEmpty) {
            _allInventories = [_productos, branchProducts];
          } else if (_allInventories.length == 1) {
            _allInventories.add(branchProducts);
          } else {
            _allInventories[1] = branchProducts;
          }

          _filteredInventories = List.from(_allInventories);
          _selectedInventories = List.generate(_allInventories.length + 1, (_) => true);
        });
      } else {
        print('Error al cargar sucursal 2: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al cargar sucursal 2: $e');
      // Puedes mostrar un snackbar menos intrusivo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cargar la sucursal 2'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }




  void _initializeAllInventories() {
    // Solo generar inventarios ficticios si no hay datos reales
    if (_allInventories.isEmpty) {
      final random = Random();
      _allInventories = List.generate(2, (_) {
        return _productos.map((producto) {
          // Random price variation between -20% and +20% of original price
          final originalPrice = producto['precio'] as double;
          final priceVariation = (random.nextDouble() * 0.4) - 0.2; // -0.2 to 0.2
          final newPrice = originalPrice * (1 + priceVariation);

          // Random stock between 0 and 100
          final newStock = random.nextInt(101); // 0 to 100

          return {
            ...producto,
            'precio': double.parse(newPrice.toStringAsFixed(2)),
            'stock': newStock,
          };
        }).toList();
      });
      _filteredInventories = List.from(_allInventories);
    }
  }

//ss
  void _loadCategorias() {
    final Set<String> categoriasUnicas = {
      ..._productos.map((p) => p['categoria'].toString())
    };
    setState(() {
      _filterOptions = categoriasUnicas.toList()
        ..sort();
      _filterOptions.insert(0, 'Todos');
    });
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();

    // Función de filtrado que se puede reutilizar
    bool filterCondition(Map<String, dynamic> product) {
      final matchesQuery =
          product['id'].toString().toLowerCase().contains(query) ||
              product['nombre'].toString().toLowerCase().contains(query) ||
              product['nombreMedico'].toString().toLowerCase().contains(query);

      final matchesCategory = _selectedFilter == 'Todos' ||
          product['categoria'] == _selectedFilter;

      return matchesQuery && matchesCategory;
    }

    setState(() {
      // Filtrar productos locales
      _filteredProducts = _productos.where(filterCondition).toList();

      // Filtrar inventarios de sucursales
      _filteredInventories = _allInventories.map((inventory) {
        return inventory.where(filterCondition).toList();
      }).toList();

      // Aplicar ordenamiento
      _sortProducts();
      _sortAllInventories();

      // También ordenar los productos del almacén
      _sortAlmacenProducts();
    });
  }



// Nueva función para ordenar los productos del almacén
  void _sortAlmacenProducts() {
    _almacenProductos.sort((a, b) =>
        a['nombre'].toString().toLowerCase().compareTo(b['nombre'].toString().toLowerCase())
    );
  }


  void _sortProducts() {
    _filteredProducts.sort((a, b) =>
        a['nombre'].toString().toLowerCase().compareTo(b['nombre'].toString().toLowerCase())
    );
  }

  void _sortAllInventories() {
    for (var inventory in _filteredInventories) {
      inventory.sort((a, b) =>
          a['nombre'].toString().toLowerCase().compareTo(b['nombre'].toString().toLowerCase())
      );
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupProductsByCategory() {
    Map<String, List<Map<String, dynamic>>> groupedProducts = {};

    if (_selectedFilter != 'Todos') {
      groupedProducts[_selectedFilter] = _filteredProducts;
    } else {
      for (var product in _filteredProducts) {
        String category = product['categoria'];
        if (!groupedProducts.containsKey(category)) {
          groupedProducts[category] = [];
        }
        groupedProducts[category]!.add(product);
      }
    }

    return groupedProducts;
  }

  void _mostrarVistaReabastecimiento() {
    // Ensure we have products in the almacen
    if (_almacenProductos.isEmpty) {
      _generateAlmacenProductos();
    }

    // Resetear selecciones previas
    _selectedForRestock = [];
    _totalRestockCost = 0.0;

    // Para cada producto en almacén, resetear la cantidad a reabastecer
    for (var producto in _almacenProductos) {
      producto['cantidadAReabastecer'] = 0;
    }

    showDialog(
      context: context,
      builder: (context) => _buildReabastecimientoDialog(context),
    );
  }

  Widget _buildReabastecimientoDialog(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.85;
    final dialogHeight = screenSize.height * 0.85;

    // Add a controller for the search field and a filteredProducts variable
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> filteredAlmacenProductos = List.from(_almacenProductos);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(16.0),
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // Function to filter products based on search query (en _buildReabastecimientoDialog)
            void filterAlmacenProducts(String query) {
              setState(() {
                if (query.isEmpty) {
                  filteredAlmacenProductos = List.from(_almacenProductos);
                } else {
                  filteredAlmacenProductos = _almacenProductos
                      .where((producto) =>
                  producto['nombre'].toString().toLowerCase().contains(query.toLowerCase()) ||
                      producto['nombreMedico'].toString().toLowerCase().contains(query.toLowerCase()) ||
                      producto['categoria'].toString().toLowerCase().contains(query.toLowerCase()) ||
                      producto['fabricante'].toString().toLowerCase().contains(query.toLowerCase()) ||
                      producto['id'].toString().toLowerCase().contains(query.toLowerCase()))
                      .toList();
                }
//
                // Ordenar los productos filtrados por nombre alfabéticamente
                filteredAlmacenProductos.sort((a, b) =>
                    a['nombre'].toString().toLowerCase().compareTo(b['nombre'].toString().toLowerCase())
                );
              });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Reabastecimiento de Inventario',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Search bar - Updated to use the controller and call filter function
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar productos',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        filterAlmacenProducts('');
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: filterAlmacenProducts,
                ),

                // Rest of the content remains the same
                const SizedBox(height: 16),

                // Local inventory summary
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tu inventario local se muestra a continuación. Los productos con stock bajo aparecen primero.',
                          style: TextStyle(color: Colors.green.shade800),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Local inventory products with low stock
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(7),
                            topRight: Radius.circular(7),
                          ),
                        ),
                        child: const Text(
                          'Tu Inventario Local (Ordenado por Stock Bajo)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildLocalInventoryList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Container with warehouse and selected products
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side: Available products in warehouse - USE FILTERED PRODUCTS HERE
                      Expanded(
                        flex: 3,
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: secondaryBlue,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Productos Disponibles en Almacén',
                                      style: TextStyle(
                                        color: white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${filteredAlmacenProductos.length} productos',
                                      style: TextStyle(
                                        color: white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: _buildAlmacenProductList(setState, filteredAlmacenProductos),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Rest of the dialog remains unchanged
                      const SizedBox(width: 16),

                      // Right side: Selected products
                      Expanded(
                        flex: 2,
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: secondaryBlue,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Productos Seleccionados',
                                  style: TextStyle(
                                    color: white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _buildSelectedProductList(setState),
                              ),

                              // Summary and invoice section
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: lightBlue,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Resumen de Reabastecimiento:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Total Productos:'),
                                        Text(
                                          '${_selectedForRestock.length}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Total Unidades:'),
                                        Text(
                                          '${_calcularTotalUnidades()}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Subtotal:'),
                                        Text(
                                          '\$${_totalRestockCost.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('IVA (16%):'),
                                        Text(
                                          '\$${(_totalRestockCost * 0.16).toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const Divider(thickness: 1),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'TOTAL:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        Text(
                                          '\$${(_totalRestockCost * 1.16).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: primaryBlue,
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
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryBlue),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _selectedForRestock.isEmpty
                          ? null
                          : () {
                        _procesarReabastecimiento();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check),
                          const SizedBox(width: 8),
                          Text(
                            'Confirmar Reabastecimiento \$${(_totalRestockCost * 1.16).toStringAsFixed(2)}',
                            style: TextStyle(color: white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocalInventoryList() {
    // Sort productos first by stock (ascending) to show low stock items first
    // Then by name for items with the same stock level
    final sortedProductos = List<Map<String, dynamic>>.from(_productos)
      ..sort((a, b) {
        int stockComparison = (a['stock'] as int).compareTo(b['stock'] as int);
        if (stockComparison != 0) {
          return stockComparison;
        }
        // If stock is the same, sort by name
        return a['nombre'].toString().toLowerCase().compareTo(b['nombre'].toString().toLowerCase());
      });

    // Show only first 30 products for performance, focusing on low stock
    final displayProducts = sortedProductos.take(30).toList();

    // rest of the function remains the same...


    return ListView.builder(
      itemCount: displayProducts.length,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: (context, index) {
        final producto = displayProducts[index];
        final int stock = producto['stock'] as int;

        // Define color based on stock level
        Color stockColor;
        if (stock <= 5) {
          stockColor = Colors.red;  // Critical stock
        } else if (stock <= 15) {
          stockColor = Colors.orange;  // Low stock
        } else {
          stockColor = Colors.green;  // Good stock
        }

        return Container(
          width: 160,
          height: 80, // Fixed height to prevent overflow
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: stockColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Use min size
              children: [
                Text(
                  producto['nombre'] ?? 'Sin nombre',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2), // Reduced spacing
                Text(
                  '${producto['categoria'] ?? ''} - ${producto['contenido'] ?? ''}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2), // Reduced spacing
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 12, // Smaller icon
                      color: stockColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Stock: $stock',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11, // Smaller text
                        color: stockColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget para mostrar productos en almacén
  Widget _buildAlmacenProductList(StateSetter setState, [List<Map<String, dynamic>>? filteredProducts]) {
    // Use the filtered list if provided, otherwise use the complete almacen list
    final productsList = filteredProducts ?? _almacenProductos;

    return ListView.builder(
      itemCount: productsList.length,
      itemBuilder: (context, index) {
        final producto = productsList[index];
        final bool isSelected = producto['cantidadAReabastecer'] > 0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          elevation: isSelected ? 2 : 1,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              producto['nombre'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${producto['categoria']} - ${producto['contenido']}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Disponible en almacén: ${producto['almacenStock']}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Costo: \$${producto['costoReabastecimiento'].toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Spinbox para cantidad
                SizedBox(
                  width: 120,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: primaryBlue,
                        onPressed: producto['cantidadAReabastecer'] > 0
                            ? () {
                          setState(() {
                            producto['cantidadAReabastecer']--;

                            // Si la cantidad es cero, quitar de seleccionados
                            if (producto['cantidadAReabastecer'] == 0) {
                              _selectedForRestock.removeWhere(
                                      (p) => p['id'] == producto['id']);
                            }

                            _updateTotalCost();
                          });
                        }
                            : null,
                      ),
                      Text(
                        '${producto['cantidadAReabastecer']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: primaryBlue,
                        onPressed: producto['cantidadAReabastecer'] < producto['almacenStock']
                            ? () {
                          setState(() {
                            producto['cantidadAReabastecer']++;

                            // Si no está en seleccionados, agregarlo
                            if (!_selectedForRestock
                                .any((p) => p['id'] == producto['id'])) {
                              _selectedForRestock.add(producto);
                            }

                            _updateTotalCost();
                          });
                        }
                            : null,
                      ),
                    ],
                  ),
                ),

                // Botón para transferir al carrito
                IconButton(
                  icon: Icon(
                    isSelected ? Icons.shopping_cart : Icons.add_shopping_cart_outlined,
                    color: isSelected ? Colors.green : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isSelected) {
                        // Si ya está seleccionado, quitar de la selección
                        producto['cantidadAReabastecer'] = 0;
                        _selectedForRestock.removeWhere((p) => p['id'] == producto['id']);
                      } else {
                        // Si no está seleccionado, agregar con cantidad 1
                        producto['cantidadAReabastecer'] = 1;
                        _selectedForRestock.add(producto);
                      }

                      _updateTotalCost();
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget para mostrar productos seleccionados
  Widget _buildSelectedProductList(StateSetter setState) {
    if (_selectedForRestock.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No hay productos seleccionados',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona productos del almacén',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _selectedForRestock.length,
      itemBuilder: (context, index) {
        final producto = _selectedForRestock[index];
        final subtotal = producto['cantidadAReabastecer'] *
            producto['costoReabastecimiento'];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(
              producto['nombre'],
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${producto['cantidadAReabastecer']} x \$${producto['costoReabastecimiento'].toStringAsFixed(2)}'),
                Text(
                  '\$${subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                setState(() {
                  producto['cantidadAReabastecer'] = 0;
                  _selectedForRestock.removeAt(index);
                  _updateTotalCost();
                });
              },
            ),
          ),
        );
      },
    );
  }

  // Calcular total de unidades
  int _calcularTotalUnidades() {
    int total = 0;
    for (var producto in _selectedForRestock) {
      total += producto['cantidadAReabastecer'] as int;
    }
    return total;
  }

  // Actualizar costo total
  void _updateTotalCost() {
    double total = 0;
    for (var producto in _selectedForRestock) {
      total += (producto['cantidadAReabastecer'] as int) *
          (producto['costoReabastecimiento'] as double);
    }
    _totalRestockCost = total;
  }

  void _procesarReabastecimiento() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Process each selected product
      for (var producto in _selectedForRestock) {
        // Call the reabastecimiento API
        final response = await http.put(
          Uri.parse('https://farmaciaserver-ashen.vercel.app/api/v1/medicamentos/${producto['id']}/reabastecer'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'cantidad': producto['cantidadAReabastecer']
          }),
        );

        if (response.statusCode != 200) {
          throw Exception('Error al reabastecer el producto ${producto['nombre']}');
        }

// Update local inventory - ADD to stock (only once)
        final int index = _productos.indexWhere((p) => p['id'] == producto['id']);
        if (index != -1) {
          _productos[index]['stock'] = (_productos[index]['stock'] as int) +
              (producto['cantidadAReabastecer'] as int);
        }

        // Update almacen stock - SUBTRACT from almacen
        final int almacenIndex = _almacenProductos.indexWhere((p) => p['id'] == producto['id']);
        if (almacenIndex != -1) {
          _almacenProductos[almacenIndex]['almacenStock'] =
              (_almacenProductos[almacenIndex]['almacenStock'] as int) -
                  (producto['cantidadAReabastecer'] as int);
        }
      }


      // Register the expense transaction for the restock
      final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final totalUnits = _calcularTotalUnidades();

      // Create a detailed description with product names and their quantities
      final List<String> detalles = _selectedForRestock.map((producto) {
        return "${producto['nombre']} (${producto['cantidadAReabastecer']} uds)";
      }).toList();

      final String detalleProductos = detalles.join(", ");
      final descripcion = 'Reabastecimiento: $totalUnits uds - $detalleProductos';

      // Make API call to create expense transaction
      final transactionResponse = await http.post(
        Uri.parse('https://farmaciaserver-ashen.vercel.app/api/v1/transacciones'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'descripcion': descripcion,
          'monto': _totalRestockCost,
          'tipo': 'egreso',
          'fecha': todayDate
        }),
      );

      if (transactionResponse.statusCode != 201) {
        print('Advertencia: La transacción financiera no se registró correctamente');
      }

      // Close loading dialog
      Navigator.of(context).pop();

      // Apply changes to filtered products
      _filterProducts();

      // Update the UI with new data
      setState(() {
        // Reset the selection
        _selectedForRestock = [];
        _totalRestockCost = 0.0;

        // Reset quantities to restock for all products
        for (var producto in _almacenProductos) {
          producto['cantidadAReabastecer'] = 0;
        }

        // Make sure filtered products are updated with current stock values
        _filteredProducts = List.from(_filteredProducts);

        // Make sure inventory displays are also updated
        _initializeAllInventories();
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reabastecimiento completado con éxito'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Close the reabastecimiento dialog
      Navigator.of(context).pop();
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar el reabastecimiento: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }



  void _eliminarProducto(Map<String, dynamic> producto) {
    setState(() {
      _productos.removeWhere((p) => p['id'] == producto['id']);
      _filterProducts();
    });
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }



  Future<void> _actualizarProducto(int id, String nombre, double precio) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'NombreGenerico': nombre,
          'Precio': precio,
        }),
      );

      if (response.statusCode == 200) {
        // Actualizar el producto localmente
        setState(() {
          final index = _productos.indexWhere((p) => p['id'] == id);
          if (index != -1) {
            _productos[index]['nombre'] = nombre;
            _productos[index]['precio'] = precio;
            _filterProducts();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto actualizado correctamente'))
        );
      } else {
        throw Exception('Error al actualizar el producto');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No se pudo actualizar el producto'))
      );
    }
  }

  void _mostrarDialogoEliminar(Map<String, dynamic> producto) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Eliminar Producto'),
            content: Text(
                '¿Estás seguro de que deseas eliminar ${producto['nombre']}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  _eliminarProducto(producto);
                  Navigator.pop(context);
                },
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  void _mostrarFormularioReabastecerProducto(Map<String, dynamic> producto) {
    final TextEditingController stockController = TextEditingController();
    final random = Random();
    final restockCost = random.nextDouble() * 100;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reabastecer Producto'),
        content: StatefulBuilder(
          builder: (context, setState) {
            double totalCost = 0;
            if (stockController.text.isNotEmpty) {
              // Cálculo del costo total
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Solo permite números
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Cantidad a reabastecer',
                    hintText: 'Ingrese la cantidad',
                    border: OutlineInputBorder(),
                  ),
                ),
                // Resto del contenido...
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (stockController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor ingrese una cantidad válida'))
                );
                return;
              }
              _reabastecerProducto(producto, stockController.text);
              Navigator.pop(context);
            },
            child: const Text('Reabastecer'),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioEditarProducto(Map<String, dynamic> producto) {
    final TextEditingController nombreController = TextEditingController(text: producto['nombre']);
    final TextEditingController precioController = TextEditingController(text: producto['precio'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del producto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: precioController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')), // Solo números y hasta 2 decimales
              ],
              decoration: const InputDecoration(
                labelText: 'Precio',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (precioController.text.isEmpty || nombreController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor complete todos los campos'))
                );
                return;
              }
              _actualizarProducto(
                producto['id'],
                nombreController.text,
                double.parse(precioController.text),
              );
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _reabastecerProducto(Map<String, dynamic> producto, String cantidad) async {
    try {
      final response = await http.put(
        Uri.parse('https://farmaciaserver-ashen.vercel.app/api/v1/medicamentos/${producto['id']}/reabastecer'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'cantidad': int.parse(cantidad)
        }),
      );

      if (response.statusCode == 200) {
        // Reload all products from API
        await _loadProductsFromApi();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto reabastecido correctamente'),
              backgroundColor: Colors.green,
            )
        );
      } else {
        throw Exception('Error al reabastecer el producto: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          )
      );
    }
  }

  List<Tab> _buildTabs() {
    List<Tab> tabs = [];
    for (int i = 0; i < _selectedInventories.length; i++) {
      if (_selectedInventories[i]) {
        tabs.add(
          Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                i == 0 ? 'Local' : 'Sucursal $i',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }
    }
    return tabs;
  }

  List<Widget> _buildTabViews(bool isSmallScreen) {
    List<Widget> views = [];
    int selectedCount = 0;

    for (int i = 0; i < _selectedInventories.length; i++) {
      if (_selectedInventories[i]) {
        final int currentTab = selectedCount; // Store the current tab index
        List<Map<String, dynamic>> inventoryData;
        if (i == 0) {
          inventoryData = _filteredProducts;
        } else {
          if (i - 1 < _filteredInventories.length) {
            inventoryData = _filteredInventories[i - 1];
          } else {
            inventoryData = [];
          }
        }

        views.add(
          SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildProductTablesByCategory(inventoryData, isSmallScreen, currentTab),
            ),
          ),
        );
        selectedCount++;
      }
    }

    if (views.isEmpty) {
      views.add(
        const Center(
          child: Text(
            'No hay inventarios seleccionados',
            style: TextStyle(
              color: primaryBlue,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return views;
  }

  Widget _buildProductTablesByCategory(List<Map<String, dynamic>> products, bool isSmallScreen, int currentTab) {
    Map<String, List<Map<String, dynamic>>> groupedProducts = {};

    // Group products by category
    for (var product in products) {
      String category = product['categoria'] as String;
      if (!groupedProducts.containsKey(category)) {
        groupedProducts[category] = [];
      }
      groupedProducts[category]!.add(product);
    }

    // Sort products within each category alphabetically by name
    groupedProducts.forEach((category, productsList) {
      productsList.sort((a, b) =>
          a['nombre'].toString().toLowerCase().compareTo(b['nombre'].toString().toLowerCase())
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedProducts.entries.map((entry) {
        ScrollController scrollController = ScrollController();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ),
            Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 8,
              radius: const Radius.circular(4),
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                child: _buildProductTable(entry.value, isSmallScreen, currentTab),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final isSmallScreen = screenWidth < 600;

    // Adjust column widths for small screens
    if (isSmallScreen) {
      idWidth = 40.0;
      nombreGenericoWidth = 80.0;
      nombreMedicoWidth = 80.0;
      fabricanteWidth = 100.0;
      contenidoWidth = 80.0;
      formaWidth = 80.0;
      fechaFabWidth = 80.0;
      presentacionWidth = 100.0;
      fechaCadWidth = 80.0;
      unidadesWidth = 60.0;
      precioWidth = 60.0;
      stockWidth = 60.0;
      actionsWidth = 40.0;
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        title: Text('Inventario',
            style: TextStyle(
              color: white,
              fontWeight: FontWeight.w600,
              fontSize: 24,
            )
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Nuevo botón de Reabastecimiento
          TextButton.icon(
            onPressed: _mostrarVistaReabastecimiento,
            icon: Icon(Icons.inventory, color: white),
            label: Text(
              'Reabastecer',
              style: TextStyle(color: white, fontSize: 16),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const VerticalDivider(
            color: Colors.white54,
            width: 1,
            thickness: 1,
            indent: 12,
            endIndent: 12,
          ),
          PopupMenuButton<void>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.store, color: white),
                const SizedBox(width: 8),
                Text('Sucursales',
                    style: TextStyle(
                      color: white,
                      fontSize: 16,
                    )
                ),
              ],
            ),
            itemBuilder: (BuildContext context) =>
                List.generate(
                  _selectedInventories.length,
                      (index) =>
                      PopupMenuItem<void>(
                        child: StatefulBuilder(
                          builder: (BuildContext context,
                              StateSetter setState) {
                            return CheckboxListTile(
                              title: Text(
                                index == 0
                                    ? 'Inventario Local'
                                    : 'Sucursal $index',
                                style: const TextStyle(color: primaryBlue),
                              ),
                              value: _selectedInventories[index],
                              activeColor: secondaryBlue,
                              onChanged: (bool? value) {
                                setState(() {
                                  _selectedInventories[index] = value!;
                                  if (!_selectedInventories.contains(true)) {
                                    _selectedInventories[0] = true;
                                  }
                                });
                                this.setState(() {
                                  _filterProducts();
                                });
                              },
                            );
                          },
                        ),
                      ),
                ),
          ),


          _isLoading
              ? Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(12),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(white),
              strokeWidth: 2,
            ),
          )
              : IconButton(
            icon: Icon(Icons.refresh, color: white),
            onPressed: () {
              _loadProductsFromApi();
              // Show a feedback message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Actualizando inventario...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),


      body: Container(
        color: lightBlue,
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              if (isSmallScreen) ...[
                _buildSearchField(),
                const SizedBox(height: 8),
                _buildFilterDropdown(),
              ] else
                ...[
                  Row(
                    children: [
                      Expanded(child: _buildSearchField()),
                      const SizedBox(width: 16),
                      _buildFilterDropdown(),
                    ],
                  ),
                ],
              const SizedBox(height: 20),
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DefaultTabController(
                    length: _selectedInventories
                        .where((selected) => selected)
                        .length,
                    child: Column(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: secondaryBlue,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: TabBar(
                            isScrollable: true,
                            indicatorColor: white,
                            labelColor: white,
                            unselectedLabelColor: lightBlue,
                            tabs: _buildTabs(),
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: _buildTabViews(isSmallScreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar producto',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: secondaryBlue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: white,
        ),
        onChanged: (_) => _filterProducts(),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          icon: const Icon(Icons.arrow_drop_down, color: secondaryBlue),
          items: _filterOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(color: primaryBlue),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedFilter = newValue!;
              _filterProducts();
            });
          },
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';

    if (date is String) {
      try {
        return DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
      } catch (e) {
        return date;
      }
    }

    if (date is DateTime) {
      return DateFormat('dd/MM/yyyy').format(date);
    }

    return '';
  }

  DataTable _buildProductTable(List<Map<String, dynamic>> products, bool isSmallScreen, int currentTab) {
    // Create columns list
    List<DataColumn> columns = [
      DataColumn(
        label: SizedBox(
          width: idWidth,
          child: const Text('ID', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: nombreGenericoWidth,
          child: const Text('Nombre Genérico', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: nombreMedicoWidth,
          child: const Text('Nombre Médico', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: fabricanteWidth,
          child: const Text('Fabricante', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: contenidoWidth,
          child: const Text('Contenido', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: formaWidth,
          child: const Text('Forma', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: fechaFabWidth,
          child: const Text('Fabricación', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: presentacionWidth,
          child: const Text('Presentación', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: fechaCadWidth,
          child: const Text('Caducidad', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: unidadesWidth,
          child: const Text('Unid/Caja',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
        numeric: true,
      ),
      DataColumn(
        label: SizedBox(
          width: stockWidth,
          child: const Text('Stock',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
        numeric: true,
      ),
      DataColumn(
        label: SizedBox(
          width: precioWidth,
          child: const Text('Precio',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
        numeric: true,
      ),
    ];

    // Add actions column only for local inventory (tab 0)
    if (currentTab == 0) {
      columns.add(
        DataColumn(
          label: SizedBox(
            width: actionsWidth,
            child: const Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }

    return DataTable(
      headingRowColor: WidgetStateProperty.all(tableHeaderColor),
      dataRowColor: WidgetStateProperty.all(white),
      columnSpacing: isSmallScreen ? 12 : 24.0,
      horizontalMargin: isSmallScreen ? 8 : 16.0,
      columns: columns,
      rows: _buildDataRows(products, isSmallScreen, currentTab),
    );
  }

  List<DataRow> _buildDataRows(List<Map<String, dynamic>> products, bool isSmallScreen, int currentTab) {
    return products.map((producto) {
      final DateTime now = DateTime.now();
      final DateTime fechaCaducidad = producto['fechaCaducidad'] != null
          ? (producto['fechaCaducidad'] is String
          ? DateTime.parse(producto['fechaCaducidad'])
          : producto['fechaCaducidad'])
          : now;

      final bool isCaducado = fechaCaducidad.isBefore(now);
      final bool isNearCaducidad = fechaCaducidad.difference(now).inDays < 90;

      final TextStyle caducidadStyle = TextStyle(
        fontSize: isSmallScreen ? 11 : 13,
        color: isCaducado ? Colors.red : isNearCaducidad ? Colors.orange : Colors.black,
        fontWeight: isCaducado || isNearCaducidad ? FontWeight.bold : FontWeight.normal,
      );

      final TextStyle baseStyle = TextStyle(
        fontSize: isSmallScreen ? 11 : 13,
      );

      List<DataCell> cells = [
        DataCell(SizedBox(width: idWidth, child: Text(producto['id']?.toString() ?? '', style: baseStyle))),
        DataCell(SizedBox(width: nombreGenericoWidth, child: Text(producto['nombre']?.toString() ?? '', style: baseStyle, overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: nombreMedicoWidth, child: Text(producto['nombreMedico']?.toString() ?? '', style: baseStyle, overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: fabricanteWidth, child: Text(producto['fabricante']?.toString() ?? '', style: baseStyle, overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: contenidoWidth, child: Text(producto['contenido']?.toString() ?? '', style: baseStyle, overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: formaWidth, child: Text(producto['categoria']?.toString() ?? '', style: baseStyle, overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: fechaFabWidth, child: Text(_formatDate(producto['fechaFabricacion']), style: baseStyle))),
        DataCell(SizedBox(width: presentacionWidth, child: Text(producto['presentacion']?.toString() ?? '', style: baseStyle, overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: fechaCadWidth, child: Text(_formatDate(fechaCaducidad), style: caducidadStyle))),
        DataCell(SizedBox(width: unidadesWidth, child: Text(producto['unidadesPorCaja']?.toString() ?? '0', style: baseStyle, textAlign: TextAlign.right))),
        DataCell(SizedBox(width: stockWidth, child: Text(producto['stock']?.toString() ?? '0', style: baseStyle, textAlign: TextAlign.right))),
        DataCell(SizedBox(width: precioWidth, child: Text('\$${(producto['precio'] ?? 0).toStringAsFixed(2)}', style: baseStyle, textAlign: TextAlign.right))),
      ];

      // Only add actions cell for local inventory (tab 0)
      if (currentTab == 0) {
        cells.add(
          DataCell(
            SizedBox(
              width: actionsWidth,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: primaryBlue),
                onSelected: (String value) {
                  switch (value) {
                    case 'edit':
                      _mostrarFormularioEditarProducto(producto);
                      break;
                    case 'restock':
                      _mostrarFormularioReabastecerProducto(producto);
                      break;
                    case 'delete':
                      _mostrarDialogoEliminar(producto);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit, color: primaryBlue),
                      title: Text('Editar'),
                    ),
                  ),
                  // const PopupMenuItem<String>(
                  //   value: 'restock',
                  //   child: ListTile(
                  //     leading: Icon(Icons.add_shopping_cart, color: primaryBlue),
                  //     title: Text('Reabastecer'),
                  //   ),
                  // ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Eliminar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return DataRow(cells: cells);
    }).toList();
  }
}