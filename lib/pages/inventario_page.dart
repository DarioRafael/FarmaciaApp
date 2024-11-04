import 'package:flutter/material.dart';

class InventarioPage extends StatefulWidget {
  const InventarioPage({Key? key}) : super(key: key);

  @override
  _InventarioPageState createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Todos';
  final List<String> _filterOptions = ['Todos', 'Útiles escolares', 'Papelería', 'Oficina', 'Arte'];

  // Lista completa de productos
  final List<Map<String, dynamic>> _allProducts = [
    {'producto': 'Lapiceros', 'categoria': 'Útiles escolares', 'stock': 239, 'precio': 3.09},
    {'producto': 'Regla', 'categoria': 'Útiles escolares', 'stock': 109, 'precio': 10.90},
    {'producto': 'Cuaderno profesional', 'categoria': 'Papelería', 'stock': 150, 'precio': 45.00},
    {'producto': 'Marcadores', 'categoria': 'Arte', 'stock': 85, 'precio': 85.50},
    {'producto': 'Pegamento', 'categoria': 'Útiles escolares', 'stock': 200, 'precio': 15.00},
    {'producto': 'Tijeras', 'categoria': 'Oficina', 'stock': 75, 'precio': 25.30},
    {'producto': 'Papel bond', 'categoria': 'Papelería', 'stock': 500, 'precio': 95.00},
    {'producto': 'Goma de borrar', 'categoria': 'Útiles escolares', 'stock': 300, 'precio': 5.50},
    {'producto': 'Lápiz 2B', 'categoria': 'Arte', 'stock': 120, 'precio': 12.00},
    {'producto': 'Clips', 'categoria': 'Oficina', 'stock': 1000, 'precio': 1.50},
  ];

  List<Map<String, dynamic>> _filteredProducts = [];

  void _sortProducts() {
    _filteredProducts.sort((a, b) {
      int nameComparison = a['producto'].compareTo(b['producto']);
      if (nameComparison != 0) {
        return nameComparison;
      }
      return a['categoria'].compareTo(b['categoria']);
    });
  }

  @override
  void initState() {
    super.initState();
    _filteredProducts = _allProducts;
    _searchController.addListener(_filterProducts);
    _sortProducts();
  }


  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final matchesQuery = product['producto'].toString().toLowerCase().contains(query) ||
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

  Widget _buildProductTable(List<Map<String, dynamic>> products, bool isSmallScreen) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: DataTable(
          columnSpacing: isSmallScreen ? 20 : 56.0,
          dataRowHeight: null, // Permite que la altura se ajuste al contenido
          headingRowHeight: isSmallScreen ? 48 : 56.0,
          horizontalMargin: isSmallScreen ? 12 : 24.0,
          columns: [
            DataColumn(
              label: Text(
                'Producto',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              tooltip: 'Nombre del producto',
              // Asigna un tercio del espacio disponible
              onSort: null,
            ),
            DataColumn(
              label: Text(
                'Stock',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              tooltip: 'Cantidad disponible',
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Precio',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              tooltip: 'Precio unitario',
              numeric: true,
            ),
            const DataColumn(
              label: Text(''),
            ),
          ],
          rows: products.map((producto) {
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.3,
                    ),
                    child: Text(
                      producto['producto'],
                      style: TextStyle(fontSize: isSmallScreen ? 13 : 15),
                      overflow: TextOverflow.visible,
                      softWrap: true,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.15,
                    ),
                    child: Text(
                      producto['stock'].toString(),
                      style: TextStyle(fontSize: isSmallScreen ? 13 : 15),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.15,
                    ),
                    child: Text(
                      '\$${producto['precio'].toStringAsFixed(2)}',
                      style: TextStyle(fontSize: isSmallScreen ? 13 : 15),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: Colors.blue,
                          size: isSmallScreen ? 20 : 24,
                        ),
                        onPressed: () => _mostrarFormularioEditarProducto(producto),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: isSmallScreen ? 20 : 24,
                        ),
                        onPressed: () => _eliminarProducto(producto),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final groupedProducts = _groupProductsByCategory();

    // Ordena las claves del mapa alfabéticamente
    final sortedCategories = groupedProducts.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            if (isSmallScreen) ...[
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar producto',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedFilter,
                          items: _filterOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
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
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _mostrarFormularioAgregarProducto,
                    icon: Icon(Icons.add, size: isSmallScreen ? 20 : 24),
                    label: const Text('Añadir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 8 : 12,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar producto',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        items: _filterOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
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
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _mostrarFormularioAgregarProducto,
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir producto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: sortedCategories.length,
                itemBuilder: (context, index) {
                  String category = sortedCategories[index];
                  List<Map<String, dynamic>> products = groupedProducts[category]!;

                  return Card(
                    margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildProductTable(products, isSmallScreen),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFormularioAgregarProducto() {
    final formKey = GlobalKey<FormState>();
    String nombre = '';
    String categoria = _selectedFilter == 'Todos' ? '' : _selectedFilter;
    String precio = '';
    String stock = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Añadir Producto'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Nombre del producto',
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) => nombre = value ?? '',
                    validator: (value) =>
                    value?.isEmpty ?? true ? 'Este campo es requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: categoria.isEmpty ? null : categoria,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                    ),
                    items: _filterOptions
                        .where((option) => option != 'Todos')
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) => categoria = value ?? '',
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Este campo es requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) => precio = value ?? '',
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Este campo es requerido';
                      }
                      if (double.tryParse(value!) == null) {
                        return 'Ingrese un número válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) => stock = value ?? '',
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Este campo es requerido';
                      }
                      if (int.tryParse(value!) == null) {
                        return 'Ingrese un número válido';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  setState(() {
                    _allProducts.add({
                      'producto': nombre,
                      'categoria': categoria,
                      'stock': int.parse(stock),
                      'precio': double.parse(precio),
                    });
                    _filterProducts();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
  void _eliminarProducto(Map<String, dynamic> producto) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar este producto?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _allProducts.remove(producto);
                  _filterProducts();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarFormularioEditarProducto(Map<String, dynamic> producto) {
    final formKey = GlobalKey<FormState>();
    String nombre = producto['producto'];
    String categoria = producto['categoria'];
    String precio = producto['precio'].toString();
    String stock = producto['stock'].toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Producto'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: nombre,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del producto',
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) => nombre = value ?? '',
                    validator: (value) =>
                    value?.isEmpty ?? true ? 'Este campo es requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: categoria,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                    ),
                    items: _filterOptions
                        .where((option) => option != 'Todos')
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) => categoria = value ?? '',
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Este campo es requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: precio,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) => precio = value ?? '',
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Este campo es requerido';
                      }
                      if (double.tryParse(value!) == null) {
                        return 'Ingrese un número válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) => stock = value ?? '',
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Este campo es requerido';
                      }
                      if (int.tryParse(value!) == null) {
                        return 'Ingrese un número válido';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  setState(() {
                    producto['producto'] = nombre;
                    producto['categoria'] = categoria;
                    producto['stock'] = int.parse(stock);
                    producto['precio'] = double.parse(precio);
                    _filterProducts();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}