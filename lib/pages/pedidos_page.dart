import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';





class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  _PedidosPageState createState() => _PedidosPageState();
}

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
    const String baseUrl = 'https://modelo-server.vercel.app/api/v1';
    const String pedidosEndpoint = '/pedidos';

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl$pedidosEndpoint'));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        if (data is Map<String, dynamic> && data.containsKey('pedidos')) {
          setState(() {
            _pedidos = List<Map<String, dynamic>>.from(data['pedidos']);
            _isLoading = false;
            _filterPedidos();
          });
        } else {
          // For demo purposes, generate mock data if API doesn't return expected format
          _generateMockPedidos();
        }
      } else {
        // For demo purposes, generate mock data if API fails
        _generateMockPedidos();
      }
    } catch (e) {
      // For demo purposes, generate mock data on error
      _generateMockPedidos();
    }
  }

  // For demo purposes only
  void _generateMockPedidos() {
    final List<String> productNames = [
      'Paracetamol 500mg',
      'Amoxicilina 250mg',
      'Loratadina 10mg',
      'Omeprazol 20mg',
      'Ibuprofeno 400mg',
      'Aspirina 100mg',
      'Cetirizina 10mg',
      'Metformina 850mg',
      'Enalapril 10mg',
      'Losartán 50mg',
    ];

    final List<String> proveedores = [
      'Farmacéutica Nacional',
      'MediSupply',
      'Droguería Continental',
      'FarmaPlus',
      'Distribuidora Médica',
    ];

    final List<String> estados = [
      'en_espera',
      'confirmado',
      'pagado',
      'completado',
      'cancelado'
    ];

    final random = DateTime.now().millisecondsSinceEpoch;
    final List<Map<String, dynamic>> mockPedidos = [];

    for (int i = 1; i <= 20; i++) {
      final productsCount = 1 + (random + i) % 5;
      final products = <Map<String, dynamic>>[];

      double total = 0;
      for (int j = 0; j < productsCount; j++) {
        final price = 10.0 + ((random + i + j) % 90);
        final quantity = 1 + ((random + i + j) % 10);
        final subtotal = price * quantity;
        total += subtotal;

        products.add({
          'nombre': productNames[(random + i + j) % productNames.length],
          'precio': price,
          'cantidad': quantity,
          'subtotal': subtotal,
        });
      }

      // Create a date in the past 30 days
      final daysAgo = (random + i) % 30;
      final date = DateTime.now().subtract(Duration(days: daysAgo));

      mockPedidos.add({
        'id': i,
        'proveedor': proveedores[(random + i) % proveedores.length],
        'fecha_creacion': date.toIso8601String(),
        'fecha_actualizacion': date
            .add(Duration(hours: (random + i) % 48))
            .toIso8601String(),
        'estado': estados[(random + i) % estados.length],
        'productos': products,
        'total': total,
        'codigo_pedido': 'PED-${date.year}${date.month.toString().padLeft(
            2, '0')}${i.toString().padLeft(3, '0')}',
        'notas': i % 3 == 0 ? 'Entregar en horario matutino' : '',
      });
    }

    setState(() {
      _pedidos = mockPedidos;
      _isLoading = false;
      _filterPedidos();
    });
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
    // Implement actual API call here
    setState(() {
      final index = _pedidos.indexWhere((p) => p['id'] == pedidoId);
      if (index != -1) {
        _pedidos[index]['estado'] = newStatus;
        _pedidos[index]['fecha_actualizacion'] =
            DateTime.now().toIso8601String();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Estado del pedido actualizado a ${_getStatusText(newStatus)}'),
            backgroundColor: _getStatusColor(newStatus),
          ),
        );

        _filterPedidos();
      }
    });
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
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
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Seleccionar método de pago',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total a pagar',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
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
          const Divider(height: 32),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildPaymentMethodTile(
                  'Transferencia Bancaria',
                  Icons.account_balance,
                  Colors.blue,
                  pedidoId,
                ),
                _buildPaymentMethodTile(
                  'Tarjeta de Crédito/Débito',
                  Icons.credit_card,
                  Colors.purple,
                  pedidoId,
                ),
                _buildPaymentMethodTile(
                  'Pago en Efectivo',
                  Icons.attach_money,
                  Colors.green,
                  pedidoId,
                ),
                const SizedBox(height: 20),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Resumen del pedido',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  trailing: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ),
                ...List.generate(
                  pedido['productos'].length,
                      (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${pedido['productos'][index]['cantidad']}x ${pedido['productos'][index]['nombre']}',
                          style: TextStyle(
                            color: Colors.grey[800],
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(String title, IconData icon, Color color,
      int pedidoId) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          // Process payment and update status
          _changePedidoStatus(pedidoId, 'pagado');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
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
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
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
        'color': Colors.blue,
      },
      {
        'title': 'Confirmado por proveedor',
        'icon': Icons.check_circle_outline,
        'isCompleted': ['confirmado', 'pagado', 'completado'].contains(status),
        'color': Colors.blue,
      },
      {
        'title': 'Pago realizado',
        'icon': Icons.payments_outlined,
        'isCompleted': ['pagado', 'completado'].contains(status),
        'color': Colors.purple,
      },
      {
        'title': 'Recibido en inventario',
        'icon': Icons.inventory,
        'isCompleted': status == 'completado',
        'color': Colors.green,
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
          ElevatedButton(
            onPressed: () => _changePedidoStatus(pedido['id'], 'confirmado'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Confirmar Pedido'),
          ),
        if (status == 'confirmado')
          ElevatedButton(
            onPressed: () => _processPayment(pedido['id']),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Procesar Pago'),
          ),
        if (status == 'pagado')
          ElevatedButton(
            onPressed: () => _changePedidoStatus(pedido['id'], 'completado'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Marcar como Completado'),
          ),
        if (status == 'en_espera' || status == 'confirmado')
          TextButton(
            onPressed: () => _cancelOrder(pedido['id']),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Cancelar Pedido'),
          ),
      ],
    );
  }

  Widget _buildPedidoCard(Map<String, dynamic> pedido) {
    final String status = pedido['estado'];
    final bool isExpanded = _expandedPedidoId == pedido['id'];

    return Slidable(
      key: ValueKey(pedido['id']),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          if (status == 'en_espera')
            SlidableAction(
              onPressed: (_) => _cancelOrder(pedido['id']),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.cancel,
              label: 'Cancelar',
            ),
          if (status == 'confirmado')
            SlidableAction(
              onPressed: (_) => _processPayment(pedido['id']),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: Icons.payment,
              label: 'Pagar',
            ),
        ],
      ),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
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
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getStatusIcon(status),
                                color: _getStatusColor(status),
                                size: 20,
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
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pedido['proveedor'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
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
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                                Icons.schedule, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(pedido['fecha_creacion']),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Row(
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
    );
  }

  Widget _buildExpandedDetails(Map<String, dynamic> pedido) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Productos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.medication_outlined,
                              color: Colors.grey,
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
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '\$${pedido['productos'][index]['precio']
                                    .toStringAsFixed(2)} c/u',
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
                  Text(
                    '${pedido['productos'][index]['cantidad']} unid.',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${pedido['productos'][index]['subtotal']
                        .toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Estado del pedido',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          _buildOrderTimeline(pedido),
          if (pedido['notas'] != null && pedido['notas'].isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Notas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.yellow[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.sticky_note_2_outlined, color: Colors.yellow[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pedido['notas'],
                      style: TextStyle(
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildActionButtons(pedido),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/empty-box.json',
            width: 200,
            height: 200,
            controller: _emptyAnimationController,
          ),
          const SizedBox(height: 20),
          Text(
            'No hay pedidos disponibles',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _selectedFilter != 'Todos'
                ? 'No hay pedidos con estado "$_selectedFilter"'
                : 'No se encontraron pedidos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchPedidos,
            child: const Text('Recargar'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
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
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 120,
                              height: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 100,
                        height: 12,
                        color: Colors.white,
                      ),
                      Container(
                        width: 80,
                        height: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
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