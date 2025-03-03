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
    _initializeCategoriesAndProducts();
  }

  void _initializeCategoriesAndProducts() {
    categories = [
      Category(
        id: '1',
        name: 'Tabletas',
        products: [
          Product(id: '1',
              name: 'Paracetamol',
              price: 10.0,
              stock: 100,
              categoryId: '1'),
          Product(id: '2',
              name: 'Ibuprofeno',
              price: 15.0,
              stock: 150,
              categoryId: '1'),
        ],
      ),
      Category(
        id: '2',
        name: 'Bebibles',
        products: [
          Product(id: '3',
              name: 'Jarabe para la tos',
              price: 20.0,
              stock: 50,
              categoryId: '2'),
          Product(id: '4',
              name: 'Vitamina C',
              price: 25.0,
              stock: 75,
              categoryId: '2'),
        ],
      ),
    ];

    for (var category in categories) {
      categoryNameToId[category.name] = category.id;
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A2463),
              Color(0xFF3E92CC),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  SizedBox(height: isSmallScreen ? 16 : 32),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          backgroundBlendMode: BlendMode.overlay,
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
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generación de Reportes',
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 24 : 32,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  'Configura y genera reportes detallados',
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w300,
                    ),
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
          _buildCategorySelector(),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildProductSelector(),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    List<Category> filteredCategories = categories
        .where((category) =>
        category.name
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
                    selectedCategoryIds.clear();
                  } else {
                    selectedCategoryIds = categories.map((c) => c.id).toSet();
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
                label: Text(category.name),
                selected: selectedCategoryIds.contains(category.id),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      selectedCategoryIds.add(category.id);
                    } else {
                      selectedCategoryIds.remove(category.id);
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
                selectAllProducts ? Icons.check_box : Icons
                    .check_box_outline_blank,
                size: 20,
              ),
              label: const Text('Seleccionar todos'),
              onPressed: () {
                setState(() {
                  if (selectAllProducts) {
                    selectedProductIds.clear();
                  } else {
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
                .where((product) =>
                product.name
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
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Generando reporte...')
                ],
              ),
            ),
          );
        },
      );

      // Crear PDF
      final pdf = pw.Document();

      // Obtener productos seleccionados
      final selectedProducts = categories
          .where((category) => selectedCategoryIds.contains(category.id))
          .expand((category) => category.products)
          .where((product) => selectedProductIds.contains(product.id))
          .toList();

      final List<Product> productsForReport = selectedProducts.isEmpty &&
          selectedCategoryIds.isNotEmpty
          ? categories
          .where((category) => selectedCategoryIds.contains(category.id))
          .expand((category) => category.products)
          .toList()
          : selectedProducts;

      final List<Product> finalProducts = productsForReport.isEmpty &&
          selectedCategoryIds.isEmpty
          ? categories.expand((category) => category.products).toList()
          : productsForReport;

      // Intentar cargar imagen (temporalmente desactivada para pruebas)
      Uint8List? imageBytes;
      try {
        imageBytes = await loadImageBytes('assets/images/cinamon.png');
      } catch (e) {
        print('Error cargando imagen: $e');
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) =>
          [
            if (imageBytes != null) pw.Image(
                pw.MemoryImage(imageBytes), width: 50, height: 50),
            _buildPDFHeader(),
            pw.SizedBox(height: 20),
            _buildPDFContent(finalProducts),
          ],
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      print("PDF generado con ${pdfBytes.length} bytes");

      Navigator.of(context, rootNavigator: true).pop();
      _showPDFPreviewFromBytes(context, pdfBytes);
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al generar PDF: $e")),
      );
    }
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

  pw.Widget _buildPDFContent(List<Product> products) {
    if (_reportType == 'Inventario') {
      return _buildInventoryTable(products);
    } else {
      return _buildSalesTable(products);
    }
  }

  pw.Widget _buildSalesTable(List<Product> products) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableHeader('Producto'),
            _buildTableHeader('Categoría'),
            _buildTableHeader('Precio Unitario'),
            _buildTableHeader('Cantidad Vendida'),
            _buildTableHeader('Total'),
          ],
        ),
        ...products.map((product) {
          final category = categories.firstWhere(
                (cat) => cat.id == product.categoryId,
          );
          final quantitySold = Random().nextInt(50) + 1;
          final total = product.price * quantitySold;

          return pw.TableRow(
            children: [
              _buildTableCell(product.name),
              _buildTableCell(category.name),
              _buildTableCell('\$${product.price.toStringAsFixed(2)}'),
              _buildTableCell(quantitySold.toString()),
              _buildTableCell('\$${total.toStringAsFixed(2)}'),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildInventoryTable(List<Product> products) {
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
            color: PdfColor.fromInt(0xFF0A2463),
            width: 0.5,
          ),
        ),
      ),
      headers: ['Producto', 'Categoría', 'Stock', 'Precio'],
      data: products.map((product) {
        final category = categories.firstWhere(
              (cat) => cat.id == product.categoryId,
        );
        return [
          product.name,
          category.name,
          product.stock.toString(),
          '\$${product.price.toStringAsFixed(2)}',
        ];
      }).toList(),
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