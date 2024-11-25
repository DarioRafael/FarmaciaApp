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
  List<Category> categories = [
    Category(
      id: '1',
      name: 'Papel',
      products: [
        Product(id: '1', name: 'Papel Bond', price: 15.50, stock: 100, categoryId: '1'),
        Product(id: '2', name: 'Papel Couché', price: 25.30, stock: 50, categoryId: '1'),
      ],
    ),
    Category(
      id: '2',
      name: 'Útiles',
      products: [
        Product(id: '3', name: 'Lápices', price: 5.99, stock: 200, categoryId: '2'),
        Product(id: '4', name: 'Bolígrafos', price: 8.50, stock: 150, categoryId: '2'),
      ],
    ),
  ];

  // Selected items
  String? selectedCategoryId;
  Set<String> selectedProductIds = {};
  bool selectAllProducts = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                Expanded(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildReportTypeSelector(),
                          const SizedBox(height: 24),
                          if (_reportType != null) ...[
                            _buildFilterSection(),
                            const SizedBox(height: 24),
                            _buildDateSelector(),
                            const SizedBox(height: 24),
                            _buildGenerateButton(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generación de Reportes',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            Text(
              'Configura y genera reportes detallados',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildReportTypeButton(
                  'Inventario',
                  Icons.inventory_2_outlined,
                  _reportType == 'Inventario',
                ),
              ),
              const SizedBox(width: 16),
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
        selectedCategoryId = null;
        selectedProductIds.clear();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue.shade100 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
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
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
          _buildCategorySelector(),
          if (selectedCategoryId != null) ...[
            const SizedBox(height: 16),
            _buildProductSelector(),
          ],
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
              selected: selectedCategoryId == null,
              onSelected: (bool selected) {
                setState(() {
                  selectedCategoryId = selected ? null : selectedCategoryId;
                  selectedProductIds.clear();
                });
              },
            ),
            ...categories.map((category) {
              return FilterChip(
                label: Text(category.name),
                selected: selectedCategoryId == category.id,
                onSelected: (bool selected) {
                  setState(() {
                    selectedCategoryId = selected ? category.id : null;
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
    final category = categories.firstWhere((c) => c.id == selectedCategoryId);

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
                    selectedProductIds.clear();
                  } else {
                    selectedProductIds = category.products.map((p) => p.id).toSet();
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
          children: category.products
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
                  selectAllProducts = selectedProductIds.length == category.products.length;
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
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateButton(false),
              ),
            ],
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
        (selectedCategoryId == null || !selectedProductIds.isEmpty);

    return ElevatedButton(
      onPressed: canGenerate ? _generateAndDownloadPDF : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.picture_as_pdf),
          SizedBox(width: 8),
          Text(
            'Generar Reporte',
            style: TextStyle(fontSize: 16),
          ),
        ],
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
      if (selectedCategoryId != null) {
        final category = categories.firstWhere((c) => c.id == selectedCategoryId);
        selectedProducts.addAll(
            category.products.where((p) => selectedProductIds.contains(p.id))
        );
      } else {
        for (var category in categories) {
          selectedProducts.addAll(category.products);
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Encabezado
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
                pw.SizedBox(height: 20),

                // Información del período
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Período del reporte:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Desde: ${DateFormat('dd/MM/yyyy').format(_startDate!)}',
                      ),
                      pw.Text(
                        'Hasta: ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Filtros aplicados
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Filtros aplicados:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Categoría: ${selectedCategoryId != null ? categories.firstWhere((c) => c.id == selectedCategoryId).name : "Todas"}',
                      ),
                      pw.Text(
                        'Productos seleccionados: ${selectedProducts.length}',
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Tabla de datos
                _buildPDFTable(selectedProducts),

                pw.SizedBox(height: 20),

                // Resumen
                _buildPDFSummary(selectedProducts),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement()
          ..href = url
          ..style.display = 'none'
          ..download = 'reporte_${_reportType?.toLowerCase()}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        Directory? directory;
        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        final String path = '${directory!.path}/reporte_${_reportType?.toLowerCase()}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
        final file = File(path);
        await file.writeAsBytes(bytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF guardado en: $path'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar el PDF: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  pw.Widget _buildPDFTable(List<Product> products) {
    return pw.Table(
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
        // Datos
        ...products.map((product) {
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
                _buildPDFTableCell('0'), // Aquí deberías poner la cantidad real vendida
                _buildPDFTableCell('\$0.00'), // Aquí deberías poner el total real
              ],
            ],
          );
        }).toList(),
      ],
    );
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