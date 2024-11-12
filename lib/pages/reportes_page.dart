import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  _ReportesPageState createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _tipoReporte;
  String? _detalleReporte;

  final List<Map<String, dynamic>> productos = [
    {
      'nombre': 'Producto A',
      'cantidad': 10,
      'precio': 15.50,
      'fecha_venta': '2024-11-01',
    },
    {
      'nombre': 'Producto B',
      'cantidad': 5,
      'precio': 45.30,
      'fecha_venta': '2024-11-05',
    },
    {
      'nombre': 'Producto C',
      'cantidad': 20,
      'precio': 23.99,
      'fecha_venta': '2024-11-10',
    },
    {
      'nombre': 'Producto D',
      'cantidad': 8,
      'precio': 30.00,
      'fecha_venta': '2024-11-15',
    },
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
  }

  List<Map<String, dynamic>> _getProductosEnRango() {
    return productos.where((producto) {
      DateTime fechaVenta = DateFormat('yyyy-MM-dd').parse(producto['fecha_venta']);
      return fechaVenta.isAtSameMomentAs(_startDate!) ||
          fechaVenta.isAtSameMomentAs(_endDate!) ||
          (fechaVenta.isAfter(_startDate!) && fechaVenta.isBefore(_endDate!));
    }).toList();
  }

  Future<void> _generateAndDownloadPDF() async {
    final pdf = pw.Document();
    final productosEnRango = _getProductosEnRango();

    // Calcular totales solo de los productos en rango
    double totalVentas = 0;
    int totalProductos = 0;
    for (var producto in productosEnRango) {
      totalVentas += (producto['cantidad'] as int) * (producto['precio'] as double);
      totalProductos += producto['cantidad'] as int;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Título
              pw.Center(
                child: pw.Text(
                  'Reporte de Ventas',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Información del período
              pw.Text(
                'Período: ${DateFormat('yyyy-MM-dd').format(_startDate!)} - ${DateFormat('yyyy-MM-dd').format(_endDate!)}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 10),

              pw.Text(
                'Total de productos encontrados: ${productosEnRango.length}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),

              if (productosEnRango.isEmpty)
                pw.Center(
                  child: pw.Text(
                    'No se encontraron productos en el rango de fechas seleccionado',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red,
                    ),
                  ),
                )
              else
                pw.Column(
                  children: [
                    // Tabla de productos
                    pw.Table(
                      border: pw.TableBorder.all(),
                      children: [
                        // Encabezados
                        pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey300,
                          ),
                          children: [
                            pw.Padding(
                              padding: pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Producto',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Cantidad',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Precio Unit.',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Total',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Fecha',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        // Filas de productos
                        ...productosEnRango.map((producto) {
                          double total = producto['cantidad'] * producto['precio'];
                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: pw.EdgeInsets.all(8),
                                child: pw.Text(producto['nombre']),
                              ),
                              pw.Padding(
                                padding: pw.EdgeInsets.all(8),
                                child: pw.Text(producto['cantidad'].toString()),
                              ),
                              pw.Padding(
                                padding: pw.EdgeInsets.all(8),
                                child: pw.Text('\$${producto['precio'].toStringAsFixed(2)}'),
                              ),
                              pw.Padding(
                                padding: pw.EdgeInsets.all(8),
                                child: pw.Text('\$${total.toStringAsFixed(2)}'),
                              ),
                              pw.Padding(
                                padding: pw.EdgeInsets.all(8),
                                child: pw.Text(producto['fecha_venta']),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                    pw.SizedBox(height: 20),

                    // Resumen
                    pw.Container(
                      padding: pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        border: pw.Border.all(),
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
                          pw.Text('Total de productos vendidos: $totalProductos'),
                          pw.Text('Total de ventas: \$${totalVentas.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ],
                ),
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
        ..download = 'reporte_ventas.pdf';
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

      final String path = '${directory!.path}/reporte_ventas.pdf';
      final file = File(path);
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF guardado en: $path'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar Reportes'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Generar Reportes',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildTipoReporteDropdown(),
            const SizedBox(height: 20),
            if (_tipoReporte == 'Ventas') _buildDetalleReporteDropdown(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildDateButton(true, 'Fecha de Inicio')),
                const SizedBox(width: 10),
                Expanded(child: _buildDateButton(false, 'Fecha de Fin')),
              ],
            ),
            const SizedBox(height: 30),
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoReporteDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Tipo de Reporte',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      hint: const Text('Selecciona un tipo de reporte'),
      items: <String>['Ventas', 'Inventario'].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _tipoReporte = newValue;
          _detalleReporte = null;
        });
      },
    );
  }

  Widget _buildDetalleReporteDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Detalle del Reporte',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      hint: const Text('Selecciona un detalle de reporte'),
      items: <String>['De un artículo', 'De varios artículos'].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _detalleReporte = newValue;
        });
      },
    );
  }

  Widget _buildDateButton(bool isStartDate, String label) {
    final formattedDate = isStartDate
        ? (_startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : '')
        : (_endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : '');
    final buttonText = isStartDate ? 'Fecha de Inicio: $formattedDate' : 'Fecha de Fin: $formattedDate';

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.blueAccent, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: () => _selectDate(context, isStartDate),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            formattedDate,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return ElevatedButton(
      onPressed: () async {
        if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La fecha de fin no puede ser anterior a la fecha de inicio.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else {
          try {
            await _generateAndDownloadPDF();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al generar el PDF: $e'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text(
        'Generar Reporte',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }


  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime initialDate = isStartDate ? _startDate! : _endDate!;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = picked; // Ajustar la fecha de fin si es antes que la de inicio
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }
}
