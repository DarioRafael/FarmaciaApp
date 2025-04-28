import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'payment_service.dart';  // Ajusta la ruta según tu estructura de proyecto

class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  _PedidosPageState createState() => _PedidosPageState();
}
//
class _PedidosPageState extends State<PedidosPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _pedidos = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // For filtering
  String _selectedFilter = 'Todos';
  final List<String> _filterOptions = [
    'Todos',
    'En espera',
    'Confirmados',
    'Pagados',
    'Completados',
    'Cancelados'
  ];

  // For animations
  late AnimationController _refreshAnimationController;
  late AnimationController _emptyAnimationController;
  late TabController _tabController;

  // Expanded pedido detail
  int? _expandedPedidoId;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _filteredPedidos = [];

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _emptyAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _tabController = TabController(length: _filterOptions.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchPedidos();

    _searchController.addListener(() {
      _filterPedidos();
    });
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedFilter = _filterOptions[_tabController.index];
        _filterPedidos();
      });
    }
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    _emptyAnimationController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Sin fecha';
    try {
      DateTime parsedDate = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm').format(parsedDate);
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  Future<void> _fetchPedidos() async {
    const String apiUrl = 'https://farmaciaserver-ashen.vercel.app/api/v1/pedidosGet';

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        if (data is Map<String, dynamic> && data.containsKey('pedidos')) {
          setState(() {
            _pedidos = List<Map<String, dynamic>>.from(data['pedidos']);
            _isLoading = false;
            _filterPedidos();
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Formato de datos incorrecto';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar los pedidos: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error de conexión: $e';
      });
    }
  }

  void _filterPedidos() {
    List<Map<String, dynamic>> filtered = List.from(_pedidos);

    // Apply status filter
    if (_selectedFilter != 'Todos') {
      String statusFilter = '';
      switch (_selectedFilter) {
        case 'En espera':
          statusFilter = 'en_espera';
          break;
        case 'Confirmados':
          statusFilter = 'confirmado';
          break;
        case 'Pagados':
          statusFilter = 'pagado';
          break;
        case 'Completados':
          statusFilter = 'completado';
          break;
        case 'Cancelados':
          statusFilter = 'cancelado';
          break;
      }

      if (statusFilter.isNotEmpty) {
        filtered = filtered
            .where((pedido) => pedido['estado'] == statusFilter)
            .toList();
      }
    }

    // Apply search filter if text is provided
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((pedido) {
        final code = pedido['codigo_pedido']?.toString().toLowerCase() ?? '';
        final supplier = pedido['proveedor']?.toString().toLowerCase() ?? '';

        // Also search in products
        bool foundInProducts = false;
        if (pedido['productos'] != null && pedido['productos'] is List) {
          for (var product in pedido['productos']) {
            if (product['nombre'].toString().toLowerCase().contains(query)) {
              foundInProducts = true;
              break;
            }
          }
        }

        return code.contains(query) || supplier.contains(query) ||
            foundInProducts;
      }).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) {
      final DateTime dateA = a['fecha_actualizacion'] != null
          ? DateTime.parse(a['fecha_actualizacion'])
          : DateTime.parse(a['fecha_creacion']);
      final DateTime dateB = b['fecha_actualizacion'] != null
          ? DateTime.parse(b['fecha_actualizacion'])
          : DateTime.parse(b['fecha_creacion']);

      return dateB.compareTo(dateA);
    });

    setState(() {
      _filteredPedidos = filtered;
    });
  }

  Future<void> _changePedidoStatus(int pedidoId, String newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (newStatus == 'pagado') {
        // Encontrar el pedido que queremos marcar como pagado
        final pedido = _pedidos.firstWhere((p) => p['id'] == pedidoId);

        // Usar el PaymentService para confirmar el pago y registrar la transacción
        final result = await PaymentService.confirmPayment(
          pedidoId: pedidoId,
          codigoPedido: pedido['codigo_pedido'],
          proveedor: pedido['proveedor'],
          monto: pedido['total'],
          metodoPago: 'Transferencia Bancaria', // O el método seleccionado por el usuario
        );

        if (result['success']) {
          setState(() {
            final index = _pedidos.indexWhere((p) => p['id'] == pedidoId);
            if (index != -1) {
              _pedidos[index]['estado'] = newStatus;
              _pedidos[index]['fecha_actualizacion'] = DateTime.now().toIso8601String();
              _filterPedidos();
            }
          });

          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pago confirmado y registrado correctamente'),
              backgroundColor: _getStatusColor(newStatus),
            ),
          );
        } else {
          // Mostrar mensaje de error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Para otros cambios de estado, mantén la implementación actual
        setState(() {
          final index = _pedidos.indexWhere((p) => p['id'] == pedidoId);
          if (index != -1) {
            _pedidos[index]['estado'] = newStatus;
            _pedidos[index]['fecha_actualizacion'] = DateTime.now().toIso8601String();
            _filterPedidos();
          }
        });

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado del pedido actualizado a ${_getStatusText(newStatus)}'),
            backgroundColor: _getStatusColor(newStatus),
          ),
        );
      }
    } catch (e) {
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el estado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelOrder(int pedidoId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content: const Text(
            '¿Estás seguro que deseas cancelar este pedido? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _changePedidoStatus(pedidoId, 'cancelado');
            },
            child: const Text('Sí, Cancelar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(int pedidoId) async {
    // Show payment methods dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPaymentMethodsSheet(pedidoId),
    );
  }

  Widget _buildPaymentMethodsSheet(int pedidoId) {
    // Find the pedido
    final pedido = _pedidos.firstWhere((p) => p['id'] == pedidoId);
    final String folioPago = 'FP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 5,
            width: 50,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    Icons.payments_rounded,
                    color: Colors.purple[600],
                    size: 28
                ),
                const SizedBox(width: 10),
                const Text(
                  'Realizar Pago',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total a pagar',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\$${pedido['total'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Selecciona tu método de pago preferido',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildPaymentMethodCard(
                  'Transferencia Bancaria',
                  Icons.account_balance,
                  Colors.blue,
                  pedidoId,
                  [
                    {'label': 'Banco:', 'value': 'BancoFarmacia'},
                    {'label': 'Cuenta:', 'value': '0123 4567 8901 2345'},
                    {'label': 'CLABE:', 'value': '012345678901234567'},
                    {'label': 'Referencia:', 'value': folioPago},
                  ],
                ),
                _buildPaymentMethodCard(
                  'Tarjeta de Crédito/Débito',
                  Icons.credit_card,
                  Colors.purple,
                  pedidoId,
                  [
                    {'label': 'Tarjeta registrada:', 'value': '•••• •••• •••• 4589'},
                    {'label': 'Titular:', 'value': 'FARMACIA SA DE CV'},
                    {'label': 'Vencimiento:', 'value': '03/2026'},
                  ],
                ),
                _buildPaymentMethodCard(
                  'Pago en Efectivo',
                  Icons.attach_money,
                  Colors.green,
                  pedidoId,
                  [
                    {'label': 'Monto:', 'value': '\$${pedido['total'].toStringAsFixed(2)}'},
                    {'label': 'Folio de pago:', 'value': folioPago},
                    {'label': 'Vigencia:', 'value': '48 horas'},
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Resumen del pedido',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ),
                ...List.generate(
                  pedido['productos'].length,
                      (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.medication_outlined,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${pedido['productos'][index]['cantidad']}x ${pedido['productos'][index]['nombre']}',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${pedido['productos'][index]['subtotal'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPaymentMethodCard(String title, IconData icon, Color color, int pedidoId, List<Map<String, String>> details) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Mostrar detalles del método de pago
            ...details.map((detail) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    detail['label']!,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    detail['value']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )).toList(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Mostrar un diálogo de confirmación
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 10),
                          Text('Confirmación de Pago'),
                        ],
                      ),
                      content: Text('¿Confirmas que has realizado el pago de \$${_pedidos.firstWhere((p) => p['id'] == pedidoId)['total'].toStringAsFixed(2)} usando $title?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _changePedidoStatus(pedidoId, 'pagado');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: Text('Confirmar Pago'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.done),
                label: const Text('Proceder con el Pago'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTimeline(Map<String, dynamic> pedido) {
    final status = pedido['estado'];
    final List<Map<String, dynamic>> steps = [
      {
        'title': 'Pedido creado',
        'icon': Icons.shopping_cart_outlined,
        'isCompleted': true,
        'color': Colors.blue[400]!,
        'description': 'Pedido registrado en el sistema',
      },
      {
        'title': 'Confirmado por proveedor',
        'icon': Icons.check_circle_outline,
        'isCompleted': ['confirmado', 'pagado', 'completado'].contains(status),
        'color': Colors.blue[600]!,
        'description': 'El proveedor ha aceptado tu pedido',
      },
      {
        'title': 'Pago realizado',
        'icon': Icons.payments_outlined,
        'isCompleted': ['pagado', 'completado'].contains(status),
        'color': Colors.purple[600]!,
        'description': 'Se ha registrado el pago correctamente',
      },
      {
        'title': 'Recibido en inventario',
        'icon': Icons.inventory_2_outlined,
        'isCompleted': status == 'completado',
        'color': Colors.green[600]!,
        'description': 'Productos agregados al inventario',
      },
    ];

    if (status == 'cancelado') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cancel,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pedido cancelado',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Este pedido fue cancelado el ${_formatDate(pedido['fecha_actualizacion'])}',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        steps.length,
            (index) => TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.2,
          isFirst: index == 0,
          isLast: index == steps.length - 1,
          indicatorStyle: IndicatorStyle(
            width: 30,
            height: 30,
            indicator: Container(
              decoration: BoxDecoration(
                color: steps[index]['isCompleted']
                    ? steps[index]['color'] as Color
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                steps[index]['icon'] as IconData,
                color: steps[index]['isCompleted']
                    ? Colors.white
                    : Colors.grey[600],
                size: 16,
              ),
            ),
            drawGap: true,
          ),
          beforeLineStyle: LineStyle(
            color: index == 0
                ? Colors.transparent
                : steps[index - 1]['isCompleted']
                ? steps[index - 1]['color'] as Color
                : Colors.grey[300]!,
            thickness: 2,
          ),
          afterLineStyle: LineStyle(
            color: steps[index]['isCompleted'] && index < steps.length - 1
                ? steps[index]['color'] as Color
                : Colors.grey[300]!,
            thickness: 2,
          ),
          endChild: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  steps[index]['title'] as String,
                  style: TextStyle(
                    color: steps[index]['isCompleted']
                        ? Colors.black87
                        : Colors.grey[600],
                    fontWeight: steps[index]['isCompleted']
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (index == 0) const SizedBox(height: 4),
                if (index == 0)
                  Text(
                    _formatDate(pedido['fecha_creacion']),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                if (index == steps.length - 1 && status == 'completado')
                  const SizedBox(height: 4),
                if (index == steps.length - 1 && status == 'completado')
                  Text(
                    _formatDate(pedido['fecha_actualizacion']),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'en_espera':
        return 'En espera';
      case 'confirmado':
        return 'Confirmado';
      case 'pagado':
        return 'Pagado';
      case 'completado':
        return 'Completado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'en_espera':
        return Colors.orange;
      case 'confirmado':
        return Colors.blue;
      case 'pagado':
        return Colors.purple;
      case 'completado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'en_espera':
        return Icons.hourglass_empty;
      case 'confirmado':
        return Icons.check_circle_outline;
      case 'pagado':
        return Icons.payments_outlined;
      case 'completado':
        return Icons.inventory;
      case 'cancelado':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildActionButtons(Map<String, dynamic> pedido) {
    final status = pedido['estado'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (status == 'en_espera')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _changePedidoStatus(pedido['id'], 'confirmado'),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Confirmar Pedido'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                elevation: 0,
              ),
            ),
          ),
        if (status == 'confirmado')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _processPayment(pedido['id']),
              icon: const Icon(Icons.payment),
              label: const Text('Procesar Pago'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                elevation: 0,
              ),
            ),
          ),
        if (status == 'pagado')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _changePedidoStatus(pedido['id'], 'completado'),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Marcar como Completado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                elevation: 0,
              ),
            ),
          ),
        if ((status == 'en_espera' || status == 'confirmado') && (status == 'pagado' || status == 'completado' ? false : true))
          const SizedBox(width: 12),
        if (status == 'en_espera' || status == 'confirmado')
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _cancelOrder(pedido['id']),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancelar Pedido'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[600],
                side: BorderSide(color: Colors.red[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPedidoCard(Map<String, dynamic> pedido) {
    final String status = pedido['estado'];
    final bool isExpanded = _expandedPedidoId == pedido['id'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Slidable(
        key: ValueKey(pedido['id']),
        endActionPane: ActionPane(
          extentRatio: 0.5,
          motion: const DrawerMotion(),
          children: [
            if (status == 'en_espera') ...[
              SlidableAction(
                onPressed: (_) => _changePedidoStatus(pedido['id'], 'confirmado'),
                backgroundColor: Colors.blue[600]!,
                foregroundColor: Colors.white,
                icon: Icons.check_circle,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                label: 'Confirmar',
              ),
              SlidableAction(
                onPressed: (_) => _cancelOrder(pedido['id']),
                backgroundColor: Colors.red[600]!,
                foregroundColor: Colors.white,
                icon: Icons.cancel,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                label: 'Cancelar',
              ),
            ],
            if (status == 'confirmado')
              SlidableAction(
                onPressed: (_) => _processPayment(pedido['id']),
                backgroundColor: Colors.purple[600]!,
                foregroundColor: Colors.white,
                icon: Icons.payment,
                borderRadius: BorderRadius.circular(20),
                label: 'Pagar',
              ),
          ],
        ),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: _getStatusColor(status).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedPedidoId = isExpanded ? null : pedido['id'];
                  });
                },
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(20),
                  bottom: isExpanded
                      ? Radius.zero
                      : const Radius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getStatusIcon(status),
                                  color: _getStatusColor(status),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pedido['codigo_pedido'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pedido['proveedor'],
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  _getStatusText(status),
                                  style: TextStyle(
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${pedido['total'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(pedido['fecha_creacion']),
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Ver detalles',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                Icon(
                                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: Colors.blue[700],
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded) _buildExpandedDetails(pedido),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildExpandedDetails(Map<String, dynamic> pedido) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: Colors.blue[800], size: 20),
              const SizedBox(width: 8),
              Text(
                'Productos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(
            pedido['productos'].length,
                (index) => Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.medication_outlined,
                              color: Colors.blue[400],
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pedido['productos'][index]['nombre'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${pedido['productos'][index]['precio'].toStringAsFixed(2)} c/u',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${pedido['productos'][index]['cantidad']} unid.',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '\$${pedido['productos'][index]['subtotal'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 30),
          Row(
            children: [
              Icon(Icons.timeline, color: Colors.purple[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Estado del pedido',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOrderTimeline(pedido),
          if (pedido['notas'] != null && pedido['notas'].isNotEmpty) ...[
            const Divider(height: 30),
            Row(
              children: [
                Icon(Icons.note_alt_outlined, color: Colors.amber[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Notas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber[200]!,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.sticky_note_2_outlined, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pedido['notas'],
                      style: TextStyle(
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: _buildActionButtons(pedido),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(70),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 70,
                  color: Colors.blue[300],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No hay pedidos disponibles',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _selectedFilter != 'Todos'
                    ? 'No se encontraron pedidos con estado "$_selectedFilter"'
                    : 'Aún no hay pedidos registrados en el sistema',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchPedidos,
                icon: const Icon(Icons.refresh),
                label: const Text('Recargar Pedidos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 120,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: 80,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 60,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 120,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          width: 90,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pedidos'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh), // Replaced Lottie with regular icon temporarily
            onPressed: () {
              _fetchPedidos();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _filterOptions.map((filter) => Tab(text: filter)).toList(),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar pedidos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _isSearching = value.isNotEmpty;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredPedidos.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _fetchPedidos,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: _filteredPedidos.length,
                itemBuilder: (context, index) {
                  return _buildPedidoCard(_filteredPedidos[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}