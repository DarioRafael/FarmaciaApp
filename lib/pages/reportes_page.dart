import 'dart:math';
import 'dart:ui_web' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;
import 'dart:convert';


Future<Uint8List> loadImageBytes(String path) async {
  final ByteData data = await rootBundle.load(path);
  return data.buffer.asUint8List();
}


class Category {
  final String id;
  final String name;
  final List<Product> products;

  Category({required this.id, required this.name, required this.products});
}

class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String categoryId;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
  });
}

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  _ReportesPageState createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _reportType;
  List<Category> categories = [];
  Map<String, String> categoryNameToId = {};

  Set<String> selectedCategoryIds = {};
  Set<String> selectedProductIds = {};
  bool selectAllProducts = false;
  TextEditingController searchController = TextEditingController();
  TextEditingController categorySearchController = TextEditingController();

  // API URLs
  final String medicamentosUrl = 'https://farmaciaserver-ashen.vercel.app/api/v1/medicamentos';
  final String transaccionesUrl = 'https://farmaciaserver-ashen.vercel.app/api/v1/transacciones';

  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> transacciones = [];
  List<Map<String, dynamic>> categorias = [];
  bool isLoading = false;


  bool get isSmallScreen =>
      MediaQuery
          .of(context)
          .size
          .width < 600;

  bool get isMediumScreen =>
      MediaQuery
          .of(context)
          .size
          .width < 1024;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    _loadDataFromAPI();  // Add this line to load API data

  }



  Future<void> _loadDataFromAPI() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load products
      final productosResponse = await http.get(Uri.parse(medicamentosUrl));
      if (productosResponse.statusCode == 200) {
        final List<dynamic> productosData = json.decode(productosResponse.body);

        // Extract unique categories
        final Set<String> categoriasSet = {};

        // Transform products data
        productos = productosData.map((producto) {
          String categoria = _determinarCategoria(producto['FormaFarmaceutica'] ?? '');
          categoriasSet.add(categoria);

          return {
            'id': producto['ID'].toString(),
            'nombreMedico': producto['NombreMedico'] ?? 'Sin nombre',
            'nombreGenerico': producto['NombreGenerico'] ?? '',
            'categoria': categoria,
            'precio': double.parse((producto['Precio'] ?? 0.0).toString()),
            'stock': int.parse((producto['Stock'] ?? 0).toString()),
            'fabricante': producto['Fabricante'] ?? '',
            'contenido': producto['Contenido'] ?? '',
            'fechaCaducidad': producto['FechaCaducidad'] ?? '',
          };
        }).toList();

        // Create categories list with explicit type declaration
        int categoryId = 1;
        categorias = categoriasSet.map<Map<String, dynamic>>((nombreCategoria) {
          final categoriaMedicamentos = productos
              .where((producto) => producto['categoria'] == nombreCategoria)
              .toList();

          return <String, dynamic>{
            'id': categoryId++,
            'nombreGenerico': nombreCategoria,
            'productos': categoriaMedicamentos,
          };
        }).toList();
      }

      // Load transactions with the updated URL
      final transaccionesResponse = await http.get(Uri.parse('https://farmaciaserver-ashen.vercel.app/api/v1/transaccionesGet'));
      if (transaccionesResponse.statusCode == 200) {
        final data = json.decode(transaccionesResponse.body);

        if (data is Map<String, dynamic> && data.containsKey('transacciones')) {
          final List<dynamic> transaccionesData = data['transacciones'];

          transacciones = transaccionesData.map((transaccion) {
            return {
              'id': transaccion['id'].toString(),
              'descripcion': transaccion['descripcion'] ?? '',
              'monto': double.parse((transaccion['monto'] ?? 0.0).toString()),
              'tipo': transaccion['tipo'] ?? '',
              'fecha': transaccion['fecha'] ?? '',
            };
          }).toList();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
// Helper method to determine category based on product form
  String _determinarCategoria(String formaFarmaceutica) {
    final formaLower = formaFarmaceutica.toLowerCase();
    if (formaLower.contains('pastilla') || formaLower.contains('tableta')) {
      return 'Tabletas';
    } else if (formaLower.contains('cápsula') || formaLower.contains('capsula')) {
      return 'Capsulas';
    } else if (formaLower.contains('inyectable') || formaLower.contains('inyeccion')) {
      return 'Inyectables';
    } else if (formaLower.contains('bebibles') || formaLower.contains('suspensión') ||
        formaLower.contains('líquido')) {
      return 'Bebibles';
    } else {
      return 'Otros';
    }
  }

  // Get sales data filtered by date and products
  List<Map<String, dynamic>> _getFilteredSales() {
    if (_startDate == null || _endDate == null) return [];

    // Create end date with time at 23:59:59 to include the full day
    final endDateWithTime = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);

    return transacciones.where((transaccion) {
      // Filter by type (only income/sales)
      if (transaccion['tipo'] != 'ingreso') return false;

      // Filter by date
      final fechaStr = transaccion['fecha'];
      if (fechaStr == null) return false;

      final fecha = DateTime.tryParse(fechaStr);
      if (fecha == null) return false;

      // Check if date is within range
      if (fecha.isBefore(_startDate!) || fecha.isAfter(endDateWithTime)) return false;

      // If no products are selected, include all sales in the date range
      if (selectedProductIds.isEmpty && selectedCategoryIds.isEmpty) return true;

      // Filter by selected products if any
      if (selectedProductIds.isNotEmpty) {
        // Parse the description to check if it contains any of the selected products
        final descripcion = transaccion['descripcion'].toString().toLowerCase();

        for (final productId in selectedProductIds) {
          final producto = productos.firstWhere(
                (p) => p['id'].toString() == productId,
            orElse: () => {'nombreGenerico': ''},
          );

          if (producto['nombreGenerico'] != '' &&
              descripcion.contains(producto['nombreMedico'].toString().toLowerCase())) {
            return true;
          }
        }

        return false;
      }

      // Filter by selected categories if any
      else if (selectedCategoryIds.isNotEmpty) {
        final descripcion = transaccion['descripcion'].toString().toLowerCase();

        for (final categoriaId in selectedCategoryIds) {
          final categoria = categorias.firstWhere(
                (c) => c['id'].toString() == categoriaId,
            orElse: () => {'productos': []},
          );

          // Check if any product from this category is in the description
          final productosCategoria = categoria['productos'] as List?;
          if (productosCategoria != null) {
            for (final producto in productosCategoria) {
              if (descripcion.contains(producto['nombreGenerico'].toString().toLowerCase())) {
                return true;
              }
            }
          }
        }

        return false;
      }

      return true;
    }).toList();
  }

  // Get inventory data filtered by selected categories and products
  List<Map<String, dynamic>> _getFilteredInventory() {
    if (selectedProductIds.isNotEmpty) {
      return productos.where((producto) => selectedProductIds.contains(producto['id'])).toList();
    } else if (selectedCategoryIds.isNotEmpty) {
      return productos.where((producto) {
        final categoria = categorias.firstWhere(
              (cat) => cat['nombreMedico'] == producto['categoria'],
          orElse: () => {'id': -1},
        );
        return selectedCategoryIds.contains(categoria['id']);
      }).toList();
    }

    return productos;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1976D2),
              const Color(0xFF0D47A1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 8,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                      child: SingleChildScrollView(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: 800,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(),
                              if (isLoading)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else ...[
                                _buildReportTypeSelector(),
                                SizedBox(height: isSmallScreen ? 16 : 24),
                                _buildFilterSection(),
                                SizedBox(height: isSmallScreen ? 16 : 24),
                                _buildDateSelector(),
                                SizedBox(height: isSmallScreen ? 16 : 24),
                                _buildGenerateButton(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8.0 : 16.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF3E92CC),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insert_chart_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generación de Reportes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configura y genera reportes',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona el tipo de reporte',
            style: GoogleFonts.poppins(
              color: const Color(0xFF0A2463),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: isSmallScreen ? 1 : 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 3,
            children: [
              _buildReportTypeCard(
                'Inventario',
                Icons.inventory_2_outlined,
                const Color(0xFF3E92CC),
                const Color(0xFF0A2463),
              ),
              _buildReportTypeCard(
                'Ventas',
                Icons.analytics_outlined,
                const Color(0xFF3E92CC),
                const Color(0xFF0A2463),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeCard(String title, IconData icon, Color gradientStart,
      Color gradientEnd) {
    final isSelected = _reportType == title;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: isSelected
              ? [gradientStart, gradientEnd]
              : [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: gradientEnd.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () =>
              setState(() {
                _reportType = title;
                selectedCategoryIds.clear();
                selectedProductIds.clear();
              }),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 28,
                    color: isSelected ? Colors.white : const Color(0xFF0A2463)),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: isSelected ? Colors.white : const Color(0xFF0A2463),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildCategorySelector(),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildProductSelector(),
        ],
      ),
    );
  }


  Widget _buildCategorySelector() {
    // Use API-loaded categories instead of dummy data
    List<Map<String, dynamic>> filteredCategories = categorias
        .where((category) =>
        category['nombreGenerico'].toString().toLowerCase()
            .contains(categorySearchController.text.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Categorías',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              icon: Icon(
                selectedCategoryIds.length == categorias.length
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                size: 20,
              ),
              label: const Text('Seleccionar todas'),
              onPressed: () {
                setState(() {
                  if (selectedCategoryIds.length == categorias.length) {
                    selectedCategoryIds.clear();
                  } else {
                    selectedCategoryIds = categorias.map((c) => c['id'].toString()).toSet();
                  }
                  selectedProductIds.clear();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: categorySearchController,
          decoration: InputDecoration(
            hintText: 'Buscar categorías...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: categorySearchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  categorySearchController.clear();
                });
              },
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 16),
        if (filteredCategories.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'No se encontraron categorías',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredCategories.map((category) {
              return FilterChip(
                label: Text(category['nombreGenerico']),
                selected: selectedCategoryIds.contains(category['id'].toString()),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      selectedCategoryIds.add(category['id'].toString());
                    } else {
                      selectedCategoryIds.remove(category['id'].toString());
                    }
                    selectedProductIds.clear();
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildProductSelector() {
    // Filter products based on selected categories
    List<Map<String, dynamic>> filteredProducts = [];

    if (selectedCategoryIds.isNotEmpty) {
      filteredProducts = productos.where((producto) {
        // Find the category object for this product
        final categoria = categorias.firstWhere(
              (cat) => cat['nombreGenerico'] == producto['categoria'],
          orElse: () => {'id': -1},
        );
        // Check if the product's category is in selectedCategoryIds
        return selectedCategoryIds.contains(categoria['id'].toString());
      }).toList();
    }

    // Further filter by search term if provided
    if (searchController.text.isNotEmpty) {
      final searchTerm = searchController.text.toLowerCase();
      filteredProducts = filteredProducts.where((producto) =>
      producto['nombreMedico'].toString().toLowerCase().contains(searchTerm) ||
          producto['nombreGenerico'].toString().toLowerCase().contains(searchTerm)
      ).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Productos',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              icon: Icon(
                selectAllProducts ? Icons.check_box : Icons.check_box_outline_blank,
                size: 20,
              ),
              label: const Text('Seleccionar todos'),
              onPressed: filteredProducts.isEmpty ? null : () {
                setState(() {
                  if (selectAllProducts) {
                    selectedProductIds.clear();
                  } else {
                    selectedProductIds = filteredProducts
                        .map((p) => p['id'].toString())
                        .toSet();
                  }
                  selectAllProducts = !selectAllProducts;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Buscar productos...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  searchController.clear();
                });
              },
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 16),
        if (selectedCategoryIds.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Selecciona una categoría primero',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else if (filteredProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'No se encontraron productos',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredProducts.map((producto) {
              return FilterChip(
                label: Text(
                  //NOMBRE
                  producto['nombreGenerico'],
                  overflow: TextOverflow.ellipsis,
                ),
                selected: selectedProductIds.contains(producto['id'].toString()),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      selectedProductIds.add(producto['id'].toString());
                    } else {
                      selectedProductIds.remove(producto['id'].toString());
                    }
                    selectAllProducts = selectedProductIds.length == filteredProducts.length;
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rango de Fechas',
            style: Theme
                .of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 500) {
                return Column(
                  children: [
                    _buildDateButton(true),
                    const SizedBox(height: 12),
                    _buildDateButton(false),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: _buildDateButton(true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDateButton(false)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(bool isStartDate) {
    final date = isStartDate ? _startDate : _endDate;
    final formattedDate = date != null
        ? DateFormat('dd/MM/yyyy').format(date)
        : 'Seleccionar';

    return InkWell(
      onTap: () => _selectDate(context, isStartDate),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isStartDate ? 'Fecha inicial' : 'Fecha final',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    bool canGenerate = _startDate != null && _endDate != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          if (canGenerate)
            BoxShadow(
              color: const Color(0xFF0A2463).withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: ElevatedButton(
        onPressed: canGenerate ? () => _generateAndPreviewPDF(context) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canGenerate ? const Color(0xFF3E92CC) : Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: canGenerate
                  ? const Icon(Icons.file_download, color: Colors.white)
                  : const Icon(Icons.block, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              'GENERAR REPORTE',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate ?? DateTime.now() : _endDate ??
          DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _generateAndPreviewPDF(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Create PDF
      final pdf = pw.Document();

      // Determine which products to include in the report
      List<Map<String, dynamic>> productsForReport = [];

      if (selectedProductIds.isNotEmpty) {
        // If specific products are selected, use those
        productsForReport = productos.where((producto) =>
            selectedProductIds.contains(producto['id'].toString())).toList();
      } else if (selectedCategoryIds.isNotEmpty) {
        // If only categories are selected, include all products in those categories
        productsForReport = productos.where((producto) {
          // Find the category for this product
          final categoria = categorias.firstWhere(
                (cat) => cat['nombre'] == producto['categoria'],
            orElse: () => {'id': -1},
          );
          return selectedCategoryIds.contains(categoria['id'].toString());
        }).toList();
      } else {
        // If nothing selected, include all products
        productsForReport = List.from(productos);
      }

      // Try to load image (temporarily disabled for testing)
      Uint8List? imageBytes;
      try {
        // Uncomment when image is available
        // imageBytes = await loadImageBytes('assets/logo.png');
      } catch (e) {
        print("Error loading image: $e");
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildPDFHeader(),
              pw.SizedBox(height: 20),
              pw.Text(
                '${_reportType == "Inventario" ? "Reporte de Inventario" : "Reporte de Ventas"}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Período: ${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              _buildPDFContent(productsForReport),
            ];
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      print("PDF generated with ${pdfBytes.length} bytes");

      Navigator.of(context, rootNavigator: true).pop();
      _showPDFPreviewFromBytes(context, pdfBytes);
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar PDF: $e')),
      );
    }
  }

  pw.Widget _buildPDFContent(List<Map<String, dynamic>> products) {
    if (_reportType == 'Inventario') {
      return _buildInventoryTable(products);
    } else {
      return _buildSalesTable(products);
    }
  }

  pw.Widget _buildSalesTable(List<Map<String, dynamic>> products) {
    // Get filtered sales transactions
    final salesTransactions = _getFilteredSales();

    // Create table headers
    final headers = ['Fecha', 'Descripción', 'Monto'];

    // Convert transactions to table data with explicit String casting and proper date formatting
    final List<List<String>> data = salesTransactions.map<List<String>>((transaction) {
      // Format date to show only year, month, day
      String formattedDate = "";
      try {
        final dateStr = transaction['fecha'].toString();
        final date = DateTime.parse(dateStr);
        formattedDate = DateFormat('yyyy-MM-dd').format(date);
      } catch (e) {
        formattedDate = transaction['fecha'].toString().split('T')[0];
      }

      return [
        formattedDate,
        transaction['descripcion'].toString(),
        '\$${transaction['monto'].toStringAsFixed(2)}',
      ];
    }).toList();

    // Add a summary row with total
    final double totalSales = salesTransactions.fold(
        0.0,
            (sum, item) => sum + (item['monto'] as double)
    );

    // Return the table with adjusted column widths and right-aligned amount column
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.TableHelper.fromTextArray(
          headerDecoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFF3E92CC),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          headerStyle: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
          ),
          rowDecoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                color: PdfColors.grey300,
                width: 0.5,
              ),
            ),
          ),
          headers: headers,
          data: data,
          // Define specific column widths to prevent wrapping
          columnWidths: {
            0: const pw.FlexColumnWidth(3), // Fecha - narrower
            1: const pw.FlexColumnWidth(8), // Descripción - wider
            2: const pw.FlexColumnWidth(3), // Monto - wider to avoid wrapping
          },
          headerAlignment: pw.Alignment.center,
          cellAlignments: {
            2: pw.Alignment.centerRight, // Align the amount column (index 2) to the right
          },
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Total: \$${totalSales.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInventoryTable(List<Map<String, dynamic>> products) {
    // Create the data for the table with explicit String casting
    List<List<String>> data = products.map<List<String>>((product) {
      return [
        product['nombreGenerico'].toString(),
        product['categoria'].toString(),
        product['stock'].toString(),
        '\$${product['precio'].toStringAsFixed(2)}',
      ];
    }).toList();

    // Return the table
    return pw.TableHelper.fromTextArray(
      headerDecoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFF3E92CC),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
      ),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.grey300,
            width: 0.5,
          ),
        ),
      ),
      headers: ['Producto', 'Categoría', 'Stock', 'Precio'],
      data: data,
      cellAlignments: {
        3: pw.Alignment.centerRight, // Align the price column (index 3) to the right
      },
      cellStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold), // Apply to all cells
    );
  }

  void _showPDFPreviewFromBytes(BuildContext context,
      Uint8List pdfBytes) async {
    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
            insetPadding: EdgeInsets.all(15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            child: Container(
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.8,
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.9,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          'Previsualización del Reporte',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0A2463),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  Divider(),
                  Expanded(
                    child: PdfPreview(
                      build: (format) async => pdfBytes,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }


  void _showPDFInWeb(Uint8List pdfBytes) {
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, "_blank");
  }

  Future<void> _downloadPDFBytes(BuildContext context,
      Uint8List pdfBytes) async {
    final fileName = '${_reportType?.toLowerCase()}_report_${DateFormat(
        'yyyyMMdd').format(DateTime.now())}.pdf';

    if (kIsWeb) {
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF descargado correctamente")),
      );
    } else {
      try {
        final output = await getApplicationDocumentsDirectory();
        final newPath = '${output.path}/$fileName';
        await File(newPath).writeAsBytes(pdfBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PDF guardado en: $newPath")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar el PDF: $e")),
        );
      }
    }
  }

  pw.Widget _buildPDFHeader() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFF0A2463),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: const pw.EdgeInsets.all(20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Reporte de $_reportType',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Periodo: ${DateFormat('dd/MM/yyyy').format(
                _startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
            style: const pw.TextStyle(
              color: PdfColors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, textAlign: pw.TextAlign.center),
    );
  }

  void _showSuccessDialog(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Reporte Generado',
                style: TextStyle(color: Colors.blue.shade900)),
            content: Text('El reporte ha sido guardado en:\n$filePath'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Error', style: TextStyle(color: Colors.red.shade900)),
            content: Text('No se pudo generar el reporte:\n$error'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }
}