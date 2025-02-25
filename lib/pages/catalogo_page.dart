import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CatalogoPage extends StatefulWidget {
  const CatalogoPage({super.key});

  @override
  _CatalogoPageState createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Todos';
  List<String> _filterOptions = ['Todos'];

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];

  final String baseUrl = 'https://modelo-server.vercel.app/api/v1';
  bool _isLoading = false;

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
          ...categorias.map((c) => c['Nombre'].toString())
        };
        setState(() {
          _filterOptions = categoriasUnicas.toList()..sort();
          _filterOptions.insert(0, 'Todos'); // Insertar "Todos" al inicio
        });
      }
    } catch (e) {
      _showErrorDialog('Error al cargar categorías');
    }
  }

  Future<void> _loadProductos() async {
    setState(() {
      _isLoading = true;
    });

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
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  Widget _buildProductTable(List<Map<String, dynamic>> products, bool isSmallScreen) {
    double productWidth = isSmallScreen ? 100 : 200;
    double stockWidth = isSmallScreen ? 50 : 100;
    double priceWidth = isSmallScreen ? 50 : 100;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: DataTable(
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
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              tooltip: 'Nombre del producto',
            ),
            DataColumn(
              label: SizedBox(
                width: stockWidth,
                child: Text(
                  'Stock',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              tooltip: 'Cantidad disponible',
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
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              tooltip: 'Precio unitario',
              numeric: true,
            ),
            const DataColumn(
              label: SizedBox(
                width: 100,
                child: Text(''),
              ),
            ),
          ],
          rows: products.map((producto) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: productWidth,
                    child: Text(
                      producto['producto'],
                      style: TextStyle(fontSize: isSmallScreen ? 13 : 15),
                      maxLines: null, // No limitar el número de líneas
                      softWrap: true,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: stockWidth,
                    child: Text(
                      producto['stock'].toString(),
                      style: TextStyle(fontSize: isSmallScreen ? 13 : 15),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: priceWidth,
                    child: Text(
                      '\$${producto['precio'].toStringAsFixed(2)}',
                      style: TextStyle(fontSize: isSmallScreen ? 13 : 15),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: Icon(
                      Icons.notification_important,
                      color: Colors.orange,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    onPressed: () {
                      // Implementar funcionalidad de notificación aquí
                    },
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
    final sortedCategories = groupedProducts.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Productos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadCategorias();
              _loadProductos();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}