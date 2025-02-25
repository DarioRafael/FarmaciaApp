import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class InventarioPage extends StatefulWidget {
  const InventarioPage({Key? key}) : super(key: key);

  @override
  _InventarioPageState createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Todos';
  List<Map<String, dynamic>> _productos = [];
  List<String> _filterOptions = ['Todos'];
  List<bool> _selectedInventories = List.generate(11, (_) => true);


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


  final Color primaryBlue = Color(0xFF1A237E); // Dark blue
  final Color secondaryBlue = Color(0xFF3949AB); // Medium blue
  final Color lightBlue = Color(0xFFE8EAF6); // Light blue
  final Color white = Colors.white;
  final Color tableHeaderColor = Color(0xFFE3F2FD); // Very light blue

  final String apiUrl = 'https://farmaciaserver-ashen.vercel.app/api/v1/medicamentos';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProducts);
    _loadProductsFromApi();
  }

  Future<void> _loadProductsFromApi() async {
    setState(() {});

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _productos = data.map((item) {
            // Assign a color based on forma farmaceutica
            Color itemColor = Color(0xFFE3F2FD); // Default light blue
            if (item['FormaFarmaceutica'] == 'Tabletas') {
              itemColor = Color(0xFFE3F2FD);
            } else if (item['FormaFarmaceutica'] == 'Bebibles' ||
                item['FormaFarmaceutica'] == 'Jarabe' ||
                item['FormaFarmaceutica'] == 'Suspensión') {
              itemColor = Color(0xFFF3E5F5);
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
        return {
          ...producto,
          'stock': random.nextInt(100) + 1,
          // Genera un stock aleatorio entre 1 y 100
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

  void _mostrarFormularioEditarProducto(Map<String, dynamic> producto) {
    final TextEditingController nombreController = TextEditingController(
        text: producto['nombre']
    );
    final TextEditingController precioController = TextEditingController(
        text: producto['precio'].toString()
    );

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Editar Producto'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: precioController,
                  decoration: const InputDecoration(labelText: 'Precio'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  await _actualizarProducto(
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
            SnackBar(content: Text('Producto actualizado correctamente'))
        );
      } else {
        throw Exception('Error al actualizar el producto');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No se pudo actualizar el producto'))
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
    final restockCost = random.nextDouble() *
        100; // Generate a random cost between 0 and 100

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Reabastecer Producto'),
            content: StatefulBuilder(
              builder: (context, setState) {
                double totalCost = 0;
                if (stockController.text.isNotEmpty) {
                  totalCost = restockCost * int.parse(stockController.text);
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Stock actual: ${producto['stock']}'),
                    TextField(
                      controller: stockController,
                      decoration: const InputDecoration(
                          labelText: 'Cantidad a reabastecer'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          totalCost = restockCost * (int.tryParse(value) ?? 0);
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text('Costo por unidad: \$${restockCost.toStringAsFixed(
                        2)}'),
                    const SizedBox(height: 8),
                    Text('Costo total: \$${totalCost.toStringAsFixed(2)}'),
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
                  _reabastecerProducto(producto, stockController.text);
                  Navigator.pop(context);
                },
                child: const Text('Reabastecer'),
              ),
            ],
          ),
    );
  }

  void _reabastecerProducto(Map<String, dynamic> producto, String cantidad) {
    setState(() {
      producto['stock'] += int.parse(cantidad);
      _filterProducts();
    });
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
                style: TextStyle(
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
              padding: EdgeInsets.all(16.0),
              child: _buildProductTablesByCategory(inventoryData, isSmallScreen, currentTab),
            ),
          ),
        );
        selectedCount++;
      }
    }

    if (views.isEmpty) {
      views.add(
        Center(
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
              radius: Radius.circular(4),
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
                SizedBox(width: 8),
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
                                style: TextStyle(color: primaryBlue),
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
                          decoration: BoxDecoration(
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar producto',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: secondaryBlue),
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          icon: Icon(Icons.arrow_drop_down, color: secondaryBlue),
          items: _filterOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: TextStyle(color: primaryBlue),
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

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  DataTable _buildProductTable(List<Map<String, dynamic>> products, bool isSmallScreen, int currentTab) {
    // Create columns list
    List<DataColumn> columns = [
      DataColumn(
        label: SizedBox(
          width: idWidth,
          child: Text('ID',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: nombreGenericoWidth,
          child: Text('Nombre Genérico',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: nombreMedicoWidth,
          child: Text('Nombre Médico',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: fabricanteWidth,
          child: Text('Fabricante',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: contenidoWidth,
          child: Text('Contenido',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: formaWidth,
          child: Text('Forma',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: fechaFabWidth,
          child: Text('Fabricación',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: presentacionWidth,
          child: Text('Presentación',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: fechaCadWidth,
          child: Text('Caducidad',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: unidadesWidth,
          child: Text('Unid/Caja',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        numeric: true,
      ),
      DataColumn(
        label: SizedBox(
          width: precioWidth,
          child: Text('Precio',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        numeric: true,
      ),
      DataColumn(
        label: SizedBox(
          width: stockWidth,
          child: Text('Stock',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        numeric: true,
      ),
    ];

    // Only add actions column for local inventory (tab 0)
    if (currentTab == 0) {
      columns.add(
        DataColumn(
          label: SizedBox(
            width: actionsWidth,
            child: Text(''),
          ),
        ),
      );
    }

    return DataTable(
      headingRowColor: MaterialStateProperty.all(tableHeaderColor),
      dataRowColor: MaterialStateProperty.all(white),
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
          ? producto['fechaCaducidad'] is DateTime
          ? producto['fechaCaducidad']
          : DateTime.parse(producto['fechaCaducidad'].toString())
          : DateTime.now();

      final bool isCaducado = fechaCaducidad.isBefore(now);
      final bool isNearCaducidad = fechaCaducidad.difference(now).inDays < 90;

      final TextStyle caducidadStyle = TextStyle(
        fontSize: isSmallScreen ? 11 : 13,
        color: isCaducado ? Colors.red : (isNearCaducidad ? Colors.orange : primaryBlue),
        fontWeight: isCaducado || isNearCaducidad ? FontWeight.bold : FontWeight.normal,
      );

      final TextStyle baseStyle = TextStyle(
        fontSize: isSmallScreen ? 11 : 13,
        color: primaryBlue,
      );

      List<DataCell> cells = [
        DataCell(SizedBox(width: idWidth,
            child: Text(producto['id']?.toString() ?? '', style: baseStyle))),
        DataCell(SizedBox(width: nombreGenericoWidth,
            child: Text(producto['nombre']?.toString() ?? '', style: baseStyle,
                overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: nombreMedicoWidth,
            child: Text(producto['nombreMedico']?.toString() ?? '', style: baseStyle,
                overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: fabricanteWidth,
            child: Text(producto['fabricante']?.toString() ?? '', style: baseStyle,
                overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: contenidoWidth,
            child: Text(producto['contenido']?.toString() ?? '', style: baseStyle,
                overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: formaWidth,
            child: Text(producto['categoria']?.toString() ?? '', style: baseStyle,
                overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: fechaFabWidth,
            child: Text(producto['fechaFabricacion'] != null ?
            _formatDate(producto['fechaFabricacion']) : '', style: baseStyle))),
        DataCell(SizedBox(width: presentacionWidth,
            child: Text(producto['presentacion']?.toString() ?? '', style: baseStyle,
                overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: fechaCadWidth,
            child: Text(_formatDate(fechaCaducidad), style: caducidadStyle))),
        DataCell(SizedBox(width: unidadesWidth,
            child: Text(producto['unidadesPorCaja']?.toString() ?? '0', style: baseStyle,
                textAlign: TextAlign.right))),
        DataCell(SizedBox(width: precioWidth,
            child: Text('\$${(producto['precio'] ?? 0).toStringAsFixed(2)}',
                style: baseStyle, textAlign: TextAlign.right))),
        DataCell(SizedBox(width: stockWidth,
            child: Text(producto['stock']?.toString() ?? '0', style: baseStyle,
                textAlign: TextAlign.right))),
      ];

      // Only add actions cell for local inventory (tab 0)
      if (currentTab == 0) {
        cells.add(
          DataCell(SizedBox(
            width: actionsWidth,
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: secondaryBlue, size: isSmallScreen ? 18 : 24),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit, color: secondaryBlue),
                    title: Text('Editar', style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                  ),
                ),
                PopupMenuItem(
                  value: 'restock',
                  child: ListTile(
                    leading: Icon(Icons.add_shopping_cart, color: secondaryBlue),
                    title: Text('Reabastecer', style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Eliminar', style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                  ),
                ),
              ],
              onSelected: (value) {
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
            ),
          )),
        );
      }

      return DataRow(cells: cells);
    }).toList();
  }
}