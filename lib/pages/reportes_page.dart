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
      final response = await http.get(Uri.parse('$baseUrl/categorias'));
      if (response.statusCode == 200) {
        final List<dynamic> categorias = json.decode(response.body);
        final List<Category> loadedCategories = categorias.map((c) {
          categoryNameToId[c['Nombre'].toString()] = c['IDCategoria'].toString();
          return Category(
            id: c['IDCategoria'].toString(),
            name: c['Nombre'].toString(),
            products: [],
          );
        }).toList();
        setState(() {
          categories = loadedCategories;
        });
      }
    } catch (e) {
      print('Error al cargar categorias: $e');
    }
  }

  Future<void> _loadProductos() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/productos'));
      if (response.statusCode == 200) {
        final List<dynamic> productos = json.decode(response.body);

        final Map<int, Product> productosUnicos = {};

        for (var p in productos) {
          final id = p['IDProductos'];
          final categoryId = categoryNameToId[p['Categoria'].toString()] ?? '';

          if (!productosUnicos.containsKey(id) && categoryId.isNotEmpty) {
            productosUnicos[id] = Product(
              id: p['IDProductos'].toString(),
              name: p['Nombre'],
              price: p['Precio'].toDouble(),
              stock: p['Stock'],
              categoryId: categoryId,
            );
          }
        }

        setState(() {
          for (var category in categories) {
            category.products.clear();
            category.products.addAll(
                productosUnicos.values.where((product) => product.categoryId == category.id)
            );
          }
        });
      }
    } catch (e) {
      print('Error al cargar productos: $e');
    }//
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
        _reportType = type;
        selectedCategoryIds.clear();
        selectedProductIds.clear();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categorías',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Todas'),
              selected: selectedCategoryIds.isEmpty,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    // Si se selecciona "Todas", limpiar las selecciones individuales
                    selectedCategoryIds.clear();
                  }
                  selectedProductIds.clear();
                });
              },
            ),
            ...categories.map((category) {
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
          ],
        ),
      ],
    );
  }

  Widget _buildProductSelector() {
    // Obtener productos de las categorías seleccionadas o todas si no hay selección
    List<Product> selectedCategoryProducts = [];

    if (selectedCategoryIds.isEmpty) {
      selectedCategoryProducts = categories
          .expand((category) => category.products)
          .toList();
    } else {
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

      // Obtener datos filtrados
      final List<Product> selectedProducts = [];
      if (selectedCategoryIds.isNotEmpty) {
        for (var categoryId in selectedCategoryIds) {
          final category = categories.firstWhere((c) => c.id == categoryId);
          selectedProducts.addAll(
              category.products.where((p) => selectedProductIds.contains(p.id))
          );
        }
      } else {
        for (var category in categories) {
          selectedProducts.addAll(category.products);
        }
      }

      // Calcular número de páginas para la tabla de productos
      final int itemsPerPage = 10;
      final int totalPages = (selectedProducts.length / itemsPerPage).ceil();

      // Primera página con información general y primera parte de la tabla de productos
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
                // Encabezado y contenido de la primera página...
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Reporte de ${_reportType}',
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
                // Resto del contenido de la primera página...
                pw.SizedBox(height: 10),
                pw.Text(
                  'Productos (Página 1 de $totalPages)',
                  style: pw.TextStyle(
                    fontSize: 16,
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
                      children: [
                        _buildPDFTableHeader('Producto'),
                        _buildPDFTableHeader('Categoría'),
                        _buildPDFTableHeader('Precio'),
                        if (_reportType == 'Inventario') _buildPDFTableHeader('Stock'),
                        if (_reportType == 'Ventas') ...[
                          _buildPDFTableHeader('Cantidad Vendida'),
                          _buildPDFTableHeader('Total'),
                        ],
                      ],
                    ),
                    // Datos para esta página
                    ...pageProducts.map((product) {
                      final category = categories.firstWhere(
                            (c) => c.id == product.categoryId,
                      );

                      return pw.TableRow(
                        children: [
                          _buildPDFTableCell(product.name),
                          _buildPDFTableCell(category.name),
                          _buildPDFTableCell('\$${product.price.toStringAsFixed(2)}'),
                          if (_reportType == 'Inventario')
                            _buildPDFTableCell(product.stock.toString()),
                          if (_reportType == 'Ventas') ...[
                            _buildPDFTableCell('0'),
                            _buildPDFTableCell('\$0.00'),
                          ],
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Agregar páginas para el resto de la tabla de productos
      for (int i = 1; i < totalPages; i++) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              final start = i * itemsPerPage;
              final end = min(start + itemsPerPage, selectedProducts.length);
              final pageProducts = selectedProducts.sublist(start, end);

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Productos (Página ${i + 1} de $totalPages)',
                    style: pw.TextStyle(
                      fontSize: 16,
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
                        children: [
                          _buildPDFTableHeader('Producto'),
                          _buildPDFTableHeader('Categoría'),
                          _buildPDFTableHeader('Precio'),
                          if (_reportType == 'Inventario') _buildPDFTableHeader('Stock'),
                          if (_reportType == 'Ventas') ...[
                            _buildPDFTableHeader('Cantidad Vendida'),
                            _buildPDFTableHeader('Total'),
                          ],
                        ],
                      ),
                      // Datos para esta página
                      ...pageProducts.map((product) {
                        final category = categories.firstWhere(
                              (c) => c.id == product.categoryId,
                        );

                        return pw.TableRow(
                          children: [
                            _buildPDFTableCell(product.name),
                            _buildPDFTableCell(category.name),
                            _buildPDFTableCell('\$${product.price.toStringAsFixed(2)}'),
                            if (_reportType == 'Inventario')
                              _buildPDFTableCell(product.stock.toString()),
                            if (_reportType == 'Ventas') ...[
                              _buildPDFTableCell('0'),
                              _buildPDFTableCell('\$0.00'),
                            ],
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }

      // Página de resumen final
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return _buildPDFSummary(selectedProducts);
          },
        ),
      );

      // Guardar o descargar el PDF
      if (kIsWeb) {
        final bytes = await pdf.save();
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'reporte.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/reporte.pdf');
        await file.writeAsBytes(await pdf.save());
        // Aquí puedes agregar código para abrir el archivo o compartirlo
      }
    } catch (e) {
      print('Error al generar el PDF: $e');
    }
  }


  pw.Widget _buildPDFTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: pw.Alignment.center,
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
      padding: const pw.EdgeInsets.all(8),
      alignment: pw.Alignment.center,
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
              fontSize: 16,
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