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
  final List<bool> _selectedInventories = List.generate(11, (_) => true);


  List<Map<String, dynamic>> _filteredProducts = [];
  List<List<Map<String, dynamic>>> _allInventories = [];
  List<List<Map<String, dynamic>>> _filteredInventories = [];

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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProducts);
    _loadProductsFromApi();
  }//Probar de nuevo

  Future<void> _loadProductsFromApi() async {
    setState(() {});

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
              'stock': item['UnidadesPorCaja'],
              'color': itemColor,
            };
          }).toList();

          _loadCategorias();
          _filterProducts();
          _initializeAllInventories();
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      setState(() {});
      _showErrorDialog('Error al cargar datos: $e');
    }
  }

  void _initializeAllInventories() {
    final random = Random();
    _allInventories = List.generate(10, (_) {
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
          'unidadesPorCaja': newStock,
        };
      }).toList();
    });
    _filteredInventories = List.from(_allInventories);
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
    });
  }


  void _sortProducts() {
    _filteredProducts.sort((a, b) {
      int nameComparison = a['nombre'].compareTo(b['nombre']);
      if (nameComparison != 0) {
        return nameComparison;
      }
      return a['categoria'].compareTo(b['categoria']);
    });
  }

  void _sortAllInventories() {
    for (var inventory in _filteredInventories) {
      inventory.sort((a, b) {
        int nameComparison = a['nombre'].compareTo(b['nombre']);
        if (nameComparison != 0) {
          return nameComparison;
        }
        return a['categoria'].compareTo(b['categoria']);
      });
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
      nombreGenericoWidth = 120.0;
      nombreMedicoWidth = 120.0;
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
          IconButton(
            icon: Icon(Icons.refresh, color: white),
            onPressed: () {
              _loadProductsFromApi();
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
                  const PopupMenuItem<String>(
                    value: 'restock',
                    child: ListTile(
                      leading: Icon(Icons.add_shopping_cart, color: primaryBlue),
                      title: Text('Reabastecer'),
                    ),
                  ),
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