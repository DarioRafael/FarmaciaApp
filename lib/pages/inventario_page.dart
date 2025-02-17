import 'package:flutter/material.dart';
import 'dart:math';

class InventarioPage extends StatefulWidget {
  const InventarioPage({Key? key}) : super(key: key);

  @override
  _InventarioPageState createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Todos';
  List<String> _filterOptions = ['Todos'];
  List<bool> _selectedInventories = List.generate(11, (_) => true);
  double stockWidth = 50.0; // Define stockWidth with a default value
  final List<Map<String, dynamic>> _productos = [
    {
      'id': 1,
      'nombre': 'Paracetamol 500mg',
      'stock': 100,
      'precio': 15.0,
      'categoria': 'Tabletas',
      'color': Color(0xFFE3F2FD)
    },
    {
      'id': 2,
      'nombre': 'Ibuprofeno 400mg',
      'stock': 85,
      'precio': 18.0,
      'categoria': 'Tabletas',
      'color': Color(0xFFE3F2FD)
    },
    {
      'id': 3,
      'nombre': 'Omeprazol 20mg',
      'stock': 70,
      'precio': 25.0,
      'categoria': 'Tabletas',
      'color': Color(0xFFE3F2FD)
    },
    {
      'id': 4,
      'nombre': 'Loratadina 10mg',
      'stock': 90,
      'precio': 12.0,
      'categoria': 'Tabletas',
      'color': Color(0xFFE3F2FD)
    },
    {
      'id': 5,
      'nombre': 'Aspirina 500mg',
      'stock': 120,
      'precio': 10.0,
      'categoria': 'Tabletas',
      'color': Color(0xFFE3F2FD)
    },
    {
      'id': 6,
      'nombre': 'Amoxicilina 500mg',
      'stock': 60,
      'precio': 35.0,
      'categoria': 'Tabletas',
      'color': Color(0xFFE3F2FD)
    },
    {
      'id': 7,
      'nombre': 'Cetirizina 10mg',
      'stock': 75,
      'precio': 15.0,
      'categoria': 'Tabletas',
      'color': Color(0xFFE3F2FD)
    },
    {
      'id': 8,
      'nombre': 'Naproxeno 250mg',
      'stock': 80,
      'precio': 20.0,
      'categoria': 'Tabletas',
      'color': Color(0xFFE3F2FD)
    },
    {
      'id': 9,
      'nombre': 'Ranitidina 150mg',
      'stock': 65,
      'precio': 22.0,
      'categoria': 'Tabletas',
      'color': Color(0xFFE3F2FD)
    },
    {
      'id': 10,
      'nombre': 'Metformina 850mg',
      'stock': 55,
      'precio': 28.0,
      'categoria': 'Tabletas',
      'color': Color(0xFFE3F2FD)
    },
    {
      'id': 11,
      'nombre': 'Jarabe para la Tos',
      'stock': 45,
      'precio': 45.0,
      'categoria': 'Bebibles',
      'color': Color(0xFFF3E5F5)
    },
    {
      'id': 12,
      'nombre': 'Suspensión Pediátrica',
      'stock': 40,
      'precio': 38.0,
      'categoria': 'Bebibles',
      'color': Color(0xFFF3E5F5)
    },
    {
      'id': 13,
      'nombre': 'Antiacido Oral',
      'stock': 50,
      'precio': 30.0,
      'categoria': 'Bebibles',
      'color': Color(0xFFF3E5F5)
    },
    {
      'id': 14,
      'nombre': 'Vitamina C Líquida',
      'stock': 60,
      'precio': 42.0,
      'categoria': 'Bebibles',
      'color': Color(0xFFF3E5F5)
    },
    {
      'id': 15,
      'nombre': 'Hierro Líquido',
      'stock': 35,
      'precio': 48.0,
      'categoria': 'Bebibles',
      'color': Color(0xFFF3E5F5)
    },
    {
      'id': 16,
      'nombre': 'Multivitamínico Líquido',
      'stock': 40,
      'precio': 55.0,
      'categoria': 'Bebibles',
      'color': Color(0xFFF3E5F5)
    },
    {
      'id': 17,
      'nombre': 'Zinc Líquido',
      'stock': 30,
      'precio': 40.0,
      'categoria': 'Bebibles',
      'color': Color(0xFFF3E5F5)
    },
    {
      'id': 18,
      'nombre': 'Calcio Líquido',
      'stock': 45,
      'precio': 52.0,
      'categoria': 'Bebibles',
      'color': Color(0xFFF3E5F5)
    },
    {
      'id': 19,
      'nombre': 'Probiótico Líquido',
      'stock': 25,
      'precio': 65.0,
      'categoria': 'Bebibles',
      'color': Color(0xFFF3E5F5)
    },
    {
      'id': 20,
      'nombre': 'Magnesio Líquido',
      'stock': 35,
      'precio': 58.0,
      'categoria': 'Bebibles',
      'color': Color(0xFFF3E5F5)
    },
  ];

  List<Map<String, dynamic>> _filteredProducts = [];
  List<List<Map<String, dynamic>>> _allInventories = [];


  final Color primaryBlue = Color(0xFF1A237E); // Dark blue
  final Color secondaryBlue = Color(0xFF3949AB); // Medium blue
  final Color lightBlue = Color(0xFFE8EAF6); // Light blue
  final Color white = Colors.white;
  final Color tableHeaderColor = Color(0xFFE3F2FD); // Very light blue


  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProducts);
    _loadCategorias();
    _filterProducts();
    _initializeAllInventories();

  }
  void _initializeAllInventories() {
    final random = Random();
    _allInventories = List.generate(10, (_) {
      return _productos.map((producto) {
        return {
          ...producto,
          'stock': random.nextInt(100) + 1, // Genera un stock aleatorio entre 1 y 100
        };
      }).toList();
    });
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
    setState(() {
      _filteredProducts = _productos.where((product) {
        final matchesQuery =
            product['nombre'].toString().toLowerCase().contains(query) ||
                product['categoria'].toString().toLowerCase().contains(query) ||
                product['precio'].toString().contains(query) ||
                product['stock'].toString().contains(query);

        final matchesCategory = _selectedFilter == 'Todos' ||
            product['categoria'] == _selectedFilter;

        return matchesQuery && matchesCategory;
      }).toList();
      _sortProducts();
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

  void _actualizarProducto(Map<String, dynamic> producto, String nombre,
      String categoria, String precio, String stock) {
    setState(() {
      producto['nombre'] = nombre;
      producto['categoria'] = categoria;
      producto['precio'] = double.parse(precio);
      producto['stock'] = int.parse(stock);
      _filterProducts();
    });
  }

  void _agregarProducto(String nombre, String categoria, String precio,
      String stock) {
    final productoExistente = _productos.any(
            (p) => p['nombre'].toLowerCase() == nombre.toLowerCase());

    if (productoExistente) {
      _showErrorDialog('Ya existe un producto con este nombre');
      return;
    }

    setState(() {
      _productos.add({
        'id': _productos.length + 1,
        'nombre': nombre,
        'categoria': categoria,
        'precio': double.parse(precio),
        'stock': int.parse(stock),
        'color': categoria == 'Tabletas' ? Color(0xFFE3F2FD) : Color(
            0xFFF3E5F5),
      });
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
        text: producto['nombre']);
    final TextEditingController categoriaController = TextEditingController(
        text: producto['categoria']);
    final TextEditingController precioController = TextEditingController(
        text: producto['precio'].toString());

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
                  controller: categoriaController,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                ),
                TextField(
                  controller: precioController,
                  decoration: const InputDecoration(labelText: 'Precio'),
                  keyboardType: TextInputType.number,
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
                  _actualizarProducto(
                    producto,
                    nombreController.text,
                    categoriaController.text,
                    precioController.text,
                    producto['stock']
                        .toString(), // Add the missing stock argument
                  );
                  Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
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
    final restockCost = random.nextDouble() * 100; // Generate a random cost between 0 and 100

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                  decoration: const InputDecoration(labelText: 'Cantidad a reabastecer'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      totalCost = restockCost * (int.tryParse(value) ?? 0);
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text('Costo por unidad: \$${restockCost.toStringAsFixed(2)}'),
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
        List<Map<String, dynamic>> inventoryData;
        if (i == 0) {
          inventoryData = _filteredProducts;
        } else {
          // Asegurarse de que haya suficientes inventarios en _allInventories
          if (i - 1 < _allInventories.length) {
            inventoryData = _allInventories[i - 1];
          } else {
            inventoryData = []; // O manejar el caso de error como prefieras
          }
        }

        views.add(
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: _buildProductTablesByCategory(inventoryData, isSmallScreen),
            ),
          ),
        );
        selectedCount++;
      }
    }

    // Asegurarse de que siempre haya al menos una vista
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

  Widget _buildProductTablesByCategory(List<Map<String, dynamic>> products, bool isSmallScreen) {
    Map<String, List<Map<String, dynamic>>> groupedProducts = {};

    // Agrupar productos por categoría
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
            _buildProductTable(entry.value, isSmallScreen),
            const SizedBox(height: 20),
          ],
        );
      }).toList(),
    );
  }
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

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
            itemBuilder: (BuildContext context) => List.generate(
              _selectedInventories.length,
                  (index) => PopupMenuItem<void>(
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return CheckboxListTile(
                      title: Text(
                        index == 0 ? 'Inventario Local' : 'Sucursal $index',
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
              _loadCategorias();
              _filterProducts();
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
              ] else ...[
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
                    length: _selectedInventories.where((selected) => selected).length,
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

  DataTable _buildProductTable(List<Map<String, dynamic>> products, bool isSmallScreen) {
    double productWidth = isSmallScreen ? 100 : 200;
    double priceWidth = isSmallScreen ? 50 : 100;

    return DataTable(
      headingRowColor: MaterialStateProperty.all(tableHeaderColor),
      dataRowColor: MaterialStateProperty.all(white),
      columnSpacing: isSmallScreen ? 20 : 56.0,
      horizontalMargin: isSmallScreen ? 12 : 24.0,
      columns: [
        DataColumn(
          label: SizedBox(
            width: productWidth,
            child: Text(
              'Producto',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),
        ),
        DataColumn(
          label: SizedBox(
            width: stockWidth,
            child: Text(
              'Stock',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
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
            width: priceWidth,
            child: Text(
              'Precio',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          numeric: true,
        ),
        const DataColumn(
          label: SizedBox(
            width: 48,
            child: Text(''),
          ),
        ),
      ],
      rows: _buildDataRows(products, isSmallScreen, productWidth, priceWidth),
    );
  }

  List<DataRow> _buildDataRows(List<Map<String, dynamic>> products, bool isSmallScreen, double productWidth, double priceWidth) {
    return products.map((producto) {
      return DataRow(
        cells: [
          DataCell(
            Container(
              width: productWidth,
              child: Text(
                producto['nombre'],
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 15,
                  color: primaryBlue,
                ),
                maxLines: null,
                softWrap: true,
              ),
            ),
          ),
          DataCell(
            SizedBox(
              width: stockWidth,
              child: Text(
                producto['stock'].toString(),
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 15,
                  color: primaryBlue,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          DataCell(
            SizedBox(
              width: priceWidth,
              child: Text(
                '\$${producto['precio'].toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 15,
                  color: primaryBlue,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          DataCell(
            SizedBox(
              width: 48,
              child: PopupMenuButton<int>(
                icon: Icon(
                  Icons.more_vert,
                  color: secondaryBlue,
                  size: isSmallScreen ? 20 : 24,
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 1,
                    child: ListTile(
                      leading: Icon(Icons.edit, color: secondaryBlue),
                      title: Text('Editar', style: TextStyle(color: primaryBlue)),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        Navigator.pop(context);
                        _mostrarFormularioEditarProducto(producto);
                      },
                    ),
                  ),
                  PopupMenuItem(
                    value: 2,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text('Eliminar', style: TextStyle(color: primaryBlue)),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        Navigator.pop(context);
                        _mostrarDialogoEliminar(producto);
                      },
                    ),
                  ),
                  PopupMenuItem(
                    value: 3,
                    child: ListTile(
                      leading: Icon(Icons.add, color: Colors.green),
                      title: Text('Reabastecer', style: TextStyle(color: primaryBlue)),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        Navigator.pop(context);
                        _mostrarFormularioReabastecerProducto(producto);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }).toList();
  }
}
