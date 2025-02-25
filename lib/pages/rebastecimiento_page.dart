import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

class ReabastecimientosPage extends StatefulWidget {
  const ReabastecimientosPage({super.key});

  @override
  _ReabastecimientosPageState createState() => _ReabastecimientosPageState();
}

class _ReabastecimientosPageState extends State<ReabastecimientosPage> {
  List<Map<String, dynamic>> reabastecimientos = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Sorting and filtering
  bool _isAscending = false;
  String _selectedSort = 'Fecha';
  final List<String> _sortOptions = ['Fecha', 'Monto'];

  @override
  void initState() {
    super.initState();
    _fetchReabastecimientos();
  }

  // Format date to just YYYY-MM-DD
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Sin fecha';
    try {
      DateTime parsedDate = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  Future<void> _fetchReabastecimientos() async {
    const String baseUrl = 'https://modelo-server.vercel.app/api/v1';
    const String transactionsEndpoint = '/transacciones';

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl$transactionsEndpoint'));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        if (data is Map<String, dynamic> && data.containsKey('transacciones')) {
          List<Map<String, dynamic>> allTransactions =
          List<Map<String, dynamic>>.from(data['transacciones']);

          setState(() {
            reabastecimientos = allTransactions
                .where((transaction) => transaction['tipo'] == 'egreso')
                .toList();
            _isLoading = false;
            _sortReabastecimientos();
          });
        } else {
          throw Exception('Unexpected format or "transacciones" field not found');
        }
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar reabastecimientos: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sortReabastecimientos() {
    setState(() {
      if (_selectedSort == 'Fecha') {
        reabastecimientos.sort((a, b) {
          DateTime? dateA = a['fecha'] != null ? DateTime.parse(a['fecha']) : null;
          DateTime? dateB = b['fecha'] != null ? DateTime.parse(b['fecha']) : null;

          if (dateA == null) return 1;
          if (dateB == null) return -1;

          return _isAscending
              ? dateA.compareTo(dateB)
              : dateB.compareTo(dateA);
        });
      } else if (_selectedSort == 'Monto') {
        reabastecimientos.sort((a, b) {
          double montoA = a['monto'] ?? 0.0;
          double montoB = b['monto'] ?? 0.0;

          return _isAscending
              ? montoA.compareTo(montoB)
              : montoB.compareTo(montoA);
        });
      }
    });
  }

  Widget _buildSortingHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sorting Dropdown
          DropdownButton<String>(
            value: _selectedSort,
            hint: const Text('Ordenar por'),
            items: _sortOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedSort = newValue;
                  _sortReabastecimientos();
                });
              }
            },
          ),

          // Ascending/Descending Toggle
          IconButton(
            icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
            onPressed: () {
              setState(() {
                _isAscending = !_isAscending;
                _sortReabastecimientos();
              });
            },
            tooltip: _isAscending ? 'Ascendente' : 'Descendente',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reabastecimientos'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Sorting Header
          _buildSortingHeader(),

          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Colors.deepPurple,
              ),
            )
                : _errorMessage.isNotEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.red[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _fetchReabastecimientos,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                  )
                ],
              ),
            )
                : reabastecimientos.isEmpty
                ? const Center(
              child: Text(
                'No hay reabastecimientos',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            )
                : ListView.builder(
              itemCount: reabastecimientos.length,
              itemBuilder: (context, index) {
                final reabastecimiento = reabastecimientos[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.deepPurple,
                        ),
                      ),
                      title: Text(
                        reabastecimiento['descripcion'] ?? 'Sin descripción',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Monto: \$${(reabastecimiento['monto'] ?? 0.0).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fecha: ${_formatDate(reabastecimiento['fecha'])}',
                            style: const TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchReabastecimientos,
        backgroundColor: Colors.deepPurple,
        tooltip: 'Recargar Reabastecimientos',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}