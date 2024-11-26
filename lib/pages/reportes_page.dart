import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

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

  final String baseUrl = 'https://modelo-server.vercel.app/api/v1';


  bool get isSmallScreen => MediaQuery.of(context).size.width < 600;
  bool get isMediumScreen => MediaQuery.of(context).size.width < 1024;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    _loadCategorias().then((_) {
      _loadProductos();
    });
  }



  Future<void> _loadCategorias() async {
    try {
      // Solo cargar categorías con ventas si el tipo de reporte es "Ventas"
      if (_reportType == 'Ventas') {
        final ventasResponse = await http.get(Uri.parse('$baseUrl/ventas'));

        if (ventasResponse.statusCode == 200) {
          final Map<String, dynamic> ventasData = json.decode(ventasResponse.body);
          final List<dynamic> ventas = ventasData['ventas'];

          // Obtener categorías con ventas
          final Set<String> categoriasConVentas = ventas
              .map((venta) => venta['IDCategoria'].toString())
              .toSet();

          final categoriaResponse = await http.get(Uri.parse('$baseUrl/categorias'));

          if (categoriaResponse.statusCode == 200) {
            final List<dynamic> categorias = json.decode(categoriaResponse.body);
            final List<Category> loadedCategories = categorias
                .where((c) => categoriasConVentas.contains(c['IDCategoria'].toString()))
                .map((c) {
              final categoryId = c['IDCategoria'].toString();
              categoryNameToId[c['Nombre'].toString()] = categoryId;
              return Category(
                id: categoryId,
                name: c['Nombre'].toString(),
                products: [],
              );
            }).toList();

            setState(() {
              categories = loadedCategories;
            });
          }
        }
      } else {
        // Si no es reporte de ventas, cargar todas las categorías
        final categoriaResponse = await http.get(Uri.parse('$baseUrl/categorias'));

        if (categoriaResponse.statusCode == 200) {
          final List<dynamic> categorias = json.decode(categoriaResponse.body);
          final List<Category> loadedCategories = categorias.map((c) {
            final categoryId = c['IDCategoria'].toString();
            categoryNameToId[c['Nombre'].toString()] = categoryId;
            return Category(
              id: categoryId,
              name: c['Nombre'].toString(),
              products: [],
            );
          }).toList();

          setState(() {
            categories = loadedCategories;
          });
        }
      }
    } catch (e) {
      print('Error al cargar categorías: $e');
    }
  }

  Future<void> _loadProductos() async {
    try {
      // Solo cargar productos con ventas si el tipo de reporte es "Ventas"
      final ventasResponse = await http.get(Uri.parse('$baseUrl/ventas'));

      if (ventasResponse.statusCode == 200) {
        final Map<String, dynamic> ventasData = json.decode(ventasResponse.body);
        final List<dynamic> ventas = ventasData['ventas'];

        // Obtener productos con ventas
        final Map<String, dynamic> productosConVentas = {};
        if (_reportType == 'Ventas') {
          ventas.forEach((venta) {
            final productoId = venta['IDProducto'].toString();
            final categoriaId = venta['IDCategoria'].toString();

            if (!productosConVentas.containsKey(productoId)) {
              productosConVentas[productoId] = {
                'id': productoId,
                'name': venta['Producto'],
                'price': venta['PrecioUnitario'],
                'categoryId': categoriaId,
              };
            }
          });
        }

        final productosResponse = await http.get(Uri.parse('$baseUrl/productos'));

        if (productosResponse.statusCode == 200) {
          final List<dynamic> productos = json.decode(productosResponse.body);

          setState(() {
            for (var category in categories) {
              category.products.clear();
              category.products.addAll(
                  productos
                      .where((p) =>
                  (_reportType == 'Inventario' ||
                      productosConVentas.containsKey(p['IDProductos'].toString())) &&
                      categoryNameToId[p['Categoria'].toString()] == category.id
                  )
                      .map((p) => Product(
                    id: p['IDProductos'].toString(),
                    name: p['Nombre'],
                    price: p['Precio'].toDouble(),
                    stock: p['Stock'],
                    categoryId: category.id,
                  ))
              );
            }
          });
        }
      }
    } catch (e) {
      print('Error al cargar productos: $e');
    }
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
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView( // Envolver en SingleChildScrollView
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  SizedBox(height: isSmallScreen ? 16 : 32),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildReportTypeSelector(),
                          SizedBox(height: isSmallScreen ? 16 : 24),
                          if (_reportType != null) ...[
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8.0 : 16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generación de Reportes',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                    fontSize: isSmallScreen ? 20 : 24,
                  ),
                ),
                Text(
                  'Configura y genera reportes detallados',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: isSmallScreen ? 14 : 16,
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de Reporte',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          // Siempre usar Row para mantener los botones en horizontal
          Row(
            children: [
              Expanded(
                child: _buildReportTypeButton(
                  'Inventario',
                  Icons.inventory_2_outlined,
                  _reportType == 'Inventario',
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 16), // Reducimos el espacio en móvil
              Expanded(
                child: _buildReportTypeButton(
                  'Ventas',
                  Icons.point_of_sale_outlined,
                  _reportType == 'Ventas',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeButton(String type, IconData icon, bool isSelected) {
    return InkWell(
      onTap: () => setState(() {
      if (_reportType != type) {
        _reportType = type;
        categories.clear(); // Limpiar categorías
        categoryNameToId.clear(); // Limpiar mapeo de nombres
        selectedCategoryIds.clear();
        selectedProductIds.clear();
        selectAllProducts = false;

        // Recargar categorías y productos
        _loadCategorias().then((_) {
          _loadProductos();
        });
      }

      }),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 12 : 16,
          horizontal: isSmallScreen ? 8 : 16,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue.shade100 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSmallScreen ? 24 : 32,
              color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
            ),
            SizedBox(height: isSmallScreen ? 4 : 8),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 12 : 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
    // Filtrar categorías basado en el texto de búsqueda
    List<Category> filteredCategories = categories
        .where((category) => category.name
        .toLowerCase()
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
                selectedCategoryIds.length == categories.length
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                size: 20,
              ),
              label: const Text('Seleccionar todas'),
              onPressed: () {
                setState(() {
                  if (selectedCategoryIds.length == categories.length) {
                    // Si todas están seleccionadas, deseleccionar todo
                    selectedCategoryIds.clear();
                  } else {
                    // Seleccionar todas las categorías
                    selectedCategoryIds = categories.map((c) => c.id).toSet();
                  }
                  // Limpiar productos seleccionados cuando cambian las categorías
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
                label: Text(category.name),
                selected: selectedCategoryIds.contains(category.id),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      selectedCategoryIds.add(category.id);
                    } else {
                      selectedCategoryIds.remove(category.id);
                    }
                    // Limpiar productos seleccionados cuando cambian las categorías
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
    // Obtener productos de las categorías seleccionadas o todas si no hay selección
    List<Product> selectedCategoryProducts = [];

    if (selectedCategoryIds.isNotEmpty) {
      selectedCategoryProducts = categories
          .where((category) => selectedCategoryIds.contains(category.id))
          .expand((category) => category.products)
          .toList();
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
              onPressed: () {
                setState(() {
                  if (selectAllProducts) {
                    // Si estaba todo seleccionado, deseleccionar todo
                    selectedProductIds.clear();
                  } else {
                    // Seleccionar solo los productos de las categorías filtradas
                    selectedProductIds = selectedCategoryProducts
                        .map((p) => p.id)
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 16),
        if (selectedCategoryProducts.isEmpty)
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
            children: selectedCategoryProducts
                .where((product) => product.name
                .toLowerCase()
                .contains(searchController.text.toLowerCase()))
                .map((product) {
              return FilterChip(
                label: Text(product.name),
                selected: selectedProductIds.contains(product.id),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      selectedProductIds.add(product.id);
                    } else {
                      selectedProductIds.remove(product.id);
                    }
                    // Actualizar el estado de "Seleccionar todos" basado en si todos los productos filtrados están seleccionados
                    selectAllProducts = selectedProductIds.containsAll(
                        selectedCategoryProducts.map((p) => p.id)
                    );
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
    final formattedDate = date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Seleccionar';

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
    bool canGenerate = _startDate != null &&
        _endDate != null &&
        (selectedCategoryIds.isEmpty || !selectedProductIds.isEmpty);

    return Container(
      width: double.infinity,
      height: isSmallScreen ? 48 : 56,
      child: ElevatedButton(
        onPressed: canGenerate ? _generateAndDownloadPDF : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: isSmallScreen ? 20 : 24, color: Colors.white60,),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Text(
              'Generar Reporte',
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16,
              color: Colors.white,),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
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

  Future<void> _generateAndDownloadPDF() async {
    try {
      final pdf = pw.Document();

      final salesData = await fetchSales();
      final mappedSalesData = _mapSalesToProducts(salesData);

      // Obtener productos seleccionados
      final List<Product> selectedProducts = [];
      if (selectedCategoryIds.isNotEmpty) {
        for (var categoryId in selectedCategoryIds) {
          final category = categories.firstWhere((c) => c.id == categoryId);
          selectedProducts.addAll(
              category.products.where((p) => selectedProductIds.isEmpty || selectedProductIds.contains(p.id)));
        }
      } else {
        for (var category in categories) {
          selectedProducts.addAll(category.products);
        }
      }

      // Calcular número de páginas para la tabla de productos
      final int itemsPerPage = 20;
      final int totalPages = (selectedProducts.length / itemsPerPage).ceil();

      // Primera página con información general y tabla de productos
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            final start = 0;
            final end = min(itemsPerPage, selectedProducts.length);
            final pageProducts = selectedProducts.sublist(start, end);

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        _reportType == 'Ventas' ? 'Reporte de Ventas' : 'Reporte de Inventario',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        DateFormat('dd/MM/yyyy').format(DateTime.now()),
                        style: const pw.TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Productos (Página 1 de $totalPages)',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey400,
                    width: 0.5,
                  ),
                  children: [
                    // Encabezados
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: _reportType == 'Ventas'
                          ? [
                        _buildPDFTableHeader('Producto'),
                        _buildPDFTableHeader('Categoría'),
                        _buildPDFTableHeader('Precio Unitario'),
                        _buildPDFTableHeader('Cantidad Vendida'),
                        _buildPDFTableHeader('Subtotal'),
                      ]
                          : [
                        _buildPDFTableHeader('Producto'),
                        _buildPDFTableHeader('Categoría'),
                        _buildPDFTableHeader('Precio Unitario'),
                        _buildPDFTableHeader('Stock'),
                      ],
                    ),
                    // Datos para esta página
                    ...pageProducts.map((product) {
                      final category = categories.firstWhere(
                            (c) => c.id == product.categoryId,
                      );

                      if (_reportType == 'Ventas') {
                        return pw.TableRow(
                          children: [
                            _buildPDFTableCell(product.name),
                            _buildPDFTableCell(category.name),
                            _buildPDFTableCell('\$${product.price.toStringAsFixed(2)}'),
                            _buildPDFTableCell(mappedSalesData[product.id]?['Stock']?.toString() ?? '0'),
                            _buildPDFTableCell('\$${(mappedSalesData[product.id]?['PrecioSubtotal'] ?? 0.0).toStringAsFixed(2)}'),
                          ],
                        );
                      }
                      else {
                      return pw.TableRow(
                      children: [
                      _buildPDFTableCell(product.name),
                      _buildPDFTableCell(category.name),
                      _buildPDFTableCell('\$${product.price.toStringAsFixed(2)}'),
                      _buildPDFTableCell(product.stock.toString()),
                      ],
                      );
                      }
                    }).toList(),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Guardar o descargar el PDF
      if (kIsWeb) {
        final bytes = await pdf.save();
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', _reportType == 'Ventas' ? 'reporte_ventas.pdf' : 'reporte_inventario.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/${_reportType == 'Ventas' ? 'reporte_ventas.pdf' : 'reporte_inventario.pdf'}');
        await file.writeAsBytes(await pdf.save());
      }
    } catch (e) {
      print('Error al generar el PDF: $e');
    }
  }

// Llamar a la API para obtener los datos de ventas
  Future<List<dynamic>> fetchSales() async {
    final String baseUrl = 'https://modelo-server.vercel.app/api/v1';
    final String salesEndpoint = '/ventas';

    try {
      final response = await http.get(Uri.parse('$baseUrl$salesEndpoint'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['ventas'];
      } else {
        throw Exception('Error al obtener ventas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en fetchSales: $e');
      throw Exception('Error al conectar con la API.');
    }
  }

// Asociar las ventas con los productos
  Map<String, Map<String, dynamic>> _mapSalesToProducts(List<dynamic> salesData) {
    final Map<String, Map<String, dynamic>> productSales = {};

    for (var sale in salesData) {
      // Convertir la fecha de la venta a DateTime
      final saleDate = DateTime.parse(sale['Fecha']);

      // Verificar si la fecha está dentro del rango seleccionado
      if (saleDate.isAfter(_startDate!) && saleDate.isBefore(_endDate!.add(Duration(days: 1)))) {
        final productId = sale['IDProducto'].toString();
        if (productSales.containsKey(productId)) {
          productSales[productId]!['Stock'] += sale['Stock'] ?? 0;
          productSales[productId]!['PrecioSubtotal'] += sale['PrecioSubtotal'] ?? 0.0;
        } else {
          productSales[productId] = {
            'Stock': sale['Stock'] ?? 0,
            'PrecioSubtotal': sale['PrecioSubtotal'] ?? 0.0,
          };
        }
      }
    }
    return productSales;
  }

  pw.Widget _buildPDFTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildPDFTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(text),
    );
  }

  pw.Widget _buildPDFSummary(List<Product> products) {
    double totalValue = products.fold(
      0,
          (sum, product) => sum + (product.price * product.stock),
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Resumen:',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Total de productos: ${products.length}'),
          if (_reportType == 'Inventario') ...[
            pw.Text(
              'Valor total del inventario: \$${totalValue.toStringAsFixed(2)}',
            ),
            pw.Text(
              'Stock total: ${products.fold(0, (sum, product) => sum + product.stock)}',
            ),
          ],
          if (_reportType == 'Ventas') ...[
            pw.Text('Total de ventas: \$0.00'), // Aquí deberías poner el total real
            pw.Text('Cantidad total vendida: 0'), // Aquí deberías poner la cantidad real
          ],
        ],
      ),
    );
  }

}