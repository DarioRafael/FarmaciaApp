import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Asegúrate de añadir intl como dependencia en pubspec.yaml

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar Reportes'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Generar Reportes',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildTipoReporteDropdown(),
              const SizedBox(height: 20),
              if (_tipoReporte == 'Ventas') _buildDetalleReporteDropdown(),
              const SizedBox(height: 20),
              _buildDateButton(true, 'Seleccionar Fecha de Inicio'),
              const SizedBox(height: 10),
              _buildDateButton(false, 'Seleccionar Fecha de Fin'),
              const SizedBox(height: 20),
              _buildGenerateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipoReporteDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
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
          _detalleReporte = null; // Reiniciar detalle al cambiar tipo
        });
      },
    );
  }

  Widget _buildDetalleReporteDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
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

  Widget _buildDateButton(bool isStartDate, String defaultText) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent, // Color de fondo del botón
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), // Padding del botón
      ),
      onPressed: () => _selectDate(context, isStartDate),
      child: Text(
        isStartDate
            ? (_startDate == null ? defaultText : 'Fecha de Inicio: ${DateFormat('yyyy-MM-dd').format(_startDate!)}')
            : (_endDate == null ? defaultText : 'Fecha de Fin: ${DateFormat('yyyy-MM-dd').format(_endDate!)}'),
        style: const TextStyle(color: Colors.white), // Color del texto
      ),
    );
  }

  Widget _buildGenerateButton() {
    return ElevatedButton(
      onPressed: () {
        // Implementar funcionalidad para generar reportes aquí
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green, // Color de fondo del botón
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), // Padding del botón
      ),
      child: const Text(
        'Generar Reportes',
        style: TextStyle(color: Colors.white), // Color del texto
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime initialDate = DateTime.now();
    if (!isStartDate && _startDate != null) {
      initialDate = _startDate!.add(const Duration(days: 1));
    }

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
        } else {
          _endDate = picked;
        }
      });
    }
  }
}
