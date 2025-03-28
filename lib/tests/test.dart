import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  _InventarioPageState createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Todos';
  List<String> _filterOptions = ['Todos'];

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];

  final String baseUrl = 'https://modelo-server.vercel.app/api/v1';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProducts);
    _loadCategorias();
    _loadProductos();
  }

  Future<void> _loadCategorias() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categorias'));
      if (response.statusCode == 200) {
        final List<dynamic> categorias = json.decode(response.body);
        // Usar Set para eliminar duplicados
        final Set<String> categoriasUnicas = {
          'Todos',
          ...categorias.map((c) => c['Nombre'].toString())
        };
        setState(() {
          _filterOptions = categoriasUnicas.toList()..sort();
        });
      }
    } catch (e) {
      _showErrorDialog('Error al cargar categorías');
    }
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
              'id': id,
              'producto': p['Nombre'],
              'categoria': p['Categoria'],
              'stock': p['Stock'],
              'precio': p['Precio'].toDouble(),
            };
          }
        }

        setState(() {
          // Convertir el Map de productos únicos a List
          _allProducts = productosUnicos.values.toList();
          _filterProducts();
        });
      }
    } catch (e) {
      _showErrorDialog('Error al cargar productos');
    }
  }

  void _sortProducts() {
    _filteredProducts.sort((a, b) {
      int nameComparison = a['producto'].compareTo(b['producto']);
      if (nameComparison != 0) {
        return nameComparison;
      }
      return a['categoria'].compareTo(b['categoria']);
    });
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final matchesQuery =
            product['producto'].toString().toLowerCase().contains(query) ||
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

  Future<void> _eliminarProducto(Map<String, dynamic> producto) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/productos/${producto['id']}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _allProducts.removeWhere((p) => p['id'] == producto['id']);
          _filterProducts();
        });
      } else {
        _showErrorDialog('Error al eliminar el producto');
      }
    } catch (e) {
      _showErrorDialog('Error de conexión al eliminar el producto');
    }
  }

  Future<void> _actualizarProducto(Map<String, dynamic> producto, String nombre,
      String categoria, String precio, String stock) async {
    // Verificar si ya existe otro producto con el mismo nombre (excluyendo el producto actual)
    final productoExistente = _allProducts.any((p) =>
    p['producto'].toLowerCase() == nombre.toLowerCase() &&
        p['id'] != producto['id']);

    if (productoExistente) {
      _showErrorDialog('Ya existe otro producto con este nombre');
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/productos/${producto['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre': nombre,
          'categoria': categoria,
          'stock': int.parse(stock),
          'precio': double.parse(precio),
        }),
      );

      if (response.statusCode == 200) {
        await _loadProductos();
      } else {
        _showErrorDialog('Error al actualizar el producto');
      }
    } catch (e) {
      _showErrorDialog('Error de conexión al actualizar el producto');
    }
  }

  Future<void> _agregarProducto(
      String nombre, String categoria, String precio, String stock) async {
    // Verificar si ya existe un producto con el mismo nombre
    final productoExistente = _allProducts.any(
            (p) => p['producto'].toLowerCase() == nombre.toLowerCase());

    if (productoExistente) {
      _showErrorDialog('Ya existe un producto con este nombre');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/productosinsert'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre': nombre,
          'categoria': categoria,
          'stock': int.parse(stock),
          'precio': double.parse(precio),
        }),
      );

      if (response.statusCode == 201) {
        await _loadProductos();
      } else {
        _showErrorDialog('Error al agregar el producto');
      }
    } catch (e) {
      _showErrorDialog('Error de conexión al agregar el producto');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  Widget _buildProductTable(
      List<Map<String, dynamic>> products, bool isSmallScreen) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: DataTable(
          columnSpacing: isSmallScreen ? 20 : 56.0,
          dataRowHeight: null,
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
                        onPressed: () =>
                            _mostrarFormularioEditarProducto(producto),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: isSmallScreen ? 20 : 24,
                        ),
                        onPressed: () => _mostrarDialogoEliminar(producto),
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

  void _mostrarDialogoEliminar(Map<String, dynamic> producto) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content:
          const Text('¿Estás seguro de que deseas eliminar este producto?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _eliminarProducto(producto);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
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
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Este campo es requerido'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // También modifica el DropdownButtonFormField en el formulario de edición
                  DropdownButtonFormField<String>(
                    value: categoria.isNotEmpty ? categoria : null,
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
                    validator: (value) => value == null || value.isEmpty
                        ? 'Este campo es requerido'
                        : null,
                    hint: const Text('Seleccionar categoría'),
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
                  _agregarProducto(nombre, categoria, precio, stock);
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
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Este campo es requerido'
                        : null,
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
                    validator: (value) => value == null || value.isEmpty
                        ? 'Este campo es requerido'
                        : null,
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
                  _actualizarProducto(
                      producto, nombre, categoria, precio, stock);
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
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final groupedProducts = _groupProductsByCategory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _mostrarFormularioAgregarProducto,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar productos...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Modificar el DropdownButton en el build method
                DropdownButton<String>(
                  value: _selectedFilter,
                  items: _filterOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedFilter = newValue;
                        _filterProducts();
                      });
                    }
                  },
                  hint: const Text(
                      'Seleccionar categoría'), // Añadir hint para cuando no hay valor seleccionado
                ),
              ],
            ),
          ),
          Expanded(
            child: groupedProducts.isEmpty
                ? const Center(
              child: Text('No se encontraron productos'),
            )
                : ListView.builder(
              itemCount: groupedProducts.length,
              itemBuilder: (context, index) {
                final category = groupedProducts.keys.elementAt(index);
                final products = groupedProducts[category]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedFilter == 'Todos') ...[
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          category,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                    _buildProductTable(products, isSmallScreen),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
