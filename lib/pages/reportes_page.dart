import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1); // Primer día del mes actual
    _endDate = now; // Día actual
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
      onPressed: () {
        if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('La fecha de fin no puede ser anterior a la fecha de inicio.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Generando reporte...'),
              backgroundColor: Colors.green,
            ),
          );
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
