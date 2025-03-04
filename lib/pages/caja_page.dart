import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

class CajaPage extends StatefulWidget {
  const CajaPage({super.key});

  @override
  State<CajaPage> createState() => _CajaPageState();
}

class _CajaPageState extends State<CajaPage> with SingleTickerProviderStateMixin {
  double availableMoney = 0.0;
  double ingresos = 0.0;
  double egresos = 0.0;
  bool isLoading = true;
  List<Transaction> transactions = [];
  List<Transaction> salesTransactions = [];
  List<Transaction> restockTransactions = [];

  bool _isSalesExpanded = false;
  bool _isRestockExpanded = false;

  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  // Paleta de colores elegante
  final Color primaryColor = const Color(0xFF0D47A1); // Azul oscuro
  final Color secondaryColor = const Color(0xFF2196F3); // Azul claro
  final Color accentColor = const Color(0xFF64B5F6); // Azul muy claro
  final Color backgroundColor = const Color(0xFFF5F9FF); // Blanco azulado
  final Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es');  // Initialize Spanish locale
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_scrollListener);
    _fetchSaldo();
    _fetchTransactions();

    // Configurar tema de la barra de estado para mejor integración
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  void _scrollListener() {
    if (_scrollController.offset > 20 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 20 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchSaldo() async {
    const String baseUrl = 'https://farmaciaserver-ashen.vercel.app/api/v1';
    const String saldoEndpoint = '/saldo';

    try {
      final response = await http.get(Uri.parse('$baseUrl$saldoEndpoint'));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        print('Respuesta recibida: $data');

        if (data is Map<String, dynamic> && data.containsKey('saldo')) {
          setState(() {
            availableMoney = data['saldo'].toDouble();
            ingresos = data['ingresos'].toDouble();
            egresos = data['egresos'].toDouble();
            isLoading = false;
          });
        } else {
          throw Exception('Formato inesperado o campo "saldo" no encontrado');
        }
      } else {
        throw Exception('Failed to load saldo');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackbar('Error al cargar el saldo: $e');
    }
  }

  Future<void> _fetchTransactions() async {
    const String baseUrl = 'https://farmaciaserver-ashen.vercel.app/api/v1';
    const String transactionsEndpoint = '/transaccionesGet';

    try {
      final response = await http.get(Uri.parse('$baseUrl$transactionsEndpoint'));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        if (data is Map<String, dynamic> && data.containsKey('transacciones')) {
          setState(() {
            transactions = (data['transacciones'] as List)
                .map((transaction) => Transaction(
              id: transaction['id'].toString(),
              description: transaction['descripcion'],
              amount: transaction['monto'].toDouble(),
              type: transaction['tipo'] == 'ingreso'
                  ? TransactionType.income
                  : TransactionType.expense,
              date: DateTime.parse(transaction['fecha']),
            ))
                .toList();

            // Separate transactions
            salesTransactions = transactions
                .where((t) => t.type == TransactionType.income)
                .toList();
            restockTransactions = transactions
                .where((t) => t.type == TransactionType.expense)
                .toList();

            // Ordenar todas las transacciones por fecha más reciente
            transactions.sort((a, b) => b.date.compareTo(a.date));
            salesTransactions.sort((a, b) => b.date.compareTo(a.date));
            restockTransactions.sort((a, b) => b.date.compareTo(a.date));
          });
        } else {
          throw Exception('Unexpected format or "transacciones" field not found');
        }
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      _showErrorSnackbar('Error loading transactions: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: cardColor,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        tabBarTheme: TabBarTheme(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      child: Scaffold(
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 210,
                floating: false,
                pinned: true,
                elevation: _isScrolled ? 4 : 0,
                backgroundColor: primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildBalanceHeader(),
                ),
                title: _isScrolled
                    ? Text('Control de Caja',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20
                    )
                )
                    : null,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                      });
                      _fetchSaldo();
                      _fetchTransactions();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Actualizando datos...'),
                          duration: Duration(seconds: 1),
                          backgroundColor: accentColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  tabs: [
                    Tab(text: 'Recientes'),
                    Tab(text: 'Ventas'),
                    Tab(text: 'Egresos'),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildRecentTransactionsList(),
              _buildSalesTransactionsList(),
              _buildRestockTransactionsList(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Aquí se podría implementar la funcionalidad para agregar una nueva transacción
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Nueva transacción'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: primaryColor,
              ),
            );
          },
          backgroundColor: secondaryColor,
          child: Icon(Icons.add),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildBalanceHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor,
            secondaryColor,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Saldo Disponible',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            isLoading
                ? CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
                : Text(
              NumberFormat.currency(locale: 'es_MX', symbol: '\$')
                  .format(availableMoney),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBalanceIndicator(
                  title: 'Ingresos',
                  amount: ingresos,
                  icon: Icons.arrow_upward,
                  color: Colors.green[400]!,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white24,
                ),
                _buildBalanceIndicator(
                  title: 'Egresos',
                  amount: egresos,
                  icon: Icons.arrow_downward,
                  color: Colors.red[400]!,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceIndicator({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(amount),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsList() {
    if (transactions.isEmpty) {
      return _buildEmptyState('No hay transacciones recientes');
    }

    // Tomar solo las 10 transacciones más recientes para la pestaña de recientes
    final recentTransactions = transactions.take(10).toList();

    return _buildTransactionListView(
      transactions: recentTransactions,
      title: 'Transacciones Recientes',
      emptyMessage: 'No hay transacciones recientes',
    );
  }

  Widget _buildSalesTransactionsList() {
    return _buildTransactionListView(
      transactions: salesTransactions,
      title: 'Ventas',
      emptyMessage: 'No hay ventas registradas',
    );
  }

  Widget _buildRestockTransactionsList() {
    return _buildTransactionListView(
      transactions: restockTransactions,
      title: 'Egresos',
      emptyMessage: 'No hay egresos registrados',
    );
  }

  Widget _buildTransactionListView({
    required List<Transaction> transactions,
    required String title,
    required String emptyMessage,
  }) {
    if (transactions.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildEnhancedTransactionCard(transaction);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: accentColor.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              _fetchSaldo();
              _fetchTransactions();
            },
            icon: Icon(Icons.refresh, color: secondaryColor),
            label: Text(
              'Actualizar',
              style: TextStyle(color: secondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTransactionCard(Transaction transaction) {
    // Formato para la fecha más detallado
    String dateFormatted = DateFormat('dd MMM yyyy', 'es').format(transaction.date);
    String timeFormatted = DateFormat('HH:mm', 'es').format(transaction.date);

    // Colores según el tipo de transacción
    Color typeColor = transaction.type == TransactionType.income
        ? Colors.green[700]!
        : Colors.red[700]!;

    Color bgColor = transaction.type == TransactionType.income
        ? Colors.green[50]!
        : Colors.red[50]!;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: typeColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Mostrar detalles adicionales de la transacción
          _showTransactionDetails(transaction);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono circular con fondo
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  transaction.type == TransactionType.income
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: typeColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              // Información de la transacción
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          dateFormatted,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          timeFormatted,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Monto
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  NumberFormat.currency(
                    locale: 'es_MX',
                    symbol: '\$',
                  ).format(transaction.amount),
                  style: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, -1),
              ),
            ],
          ),
          child: Column(
            children: [
              // Indicador de arrastre
              Container(
                height: 5,
                width: 40,
                margin: EdgeInsets.only(top: 16, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),

              // Título
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Detalles de la Transacción",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),

              Divider(),

              // Contenido
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Tipo y Monto
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: transaction.type == TransactionType.income
                              ? Colors.green[50]
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              transaction.type == TransactionType.income
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: transaction.type == TransactionType.income
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              size: 40,
                            ),
                            SizedBox(height: 8),
                            Text(
                              transaction.type == TransactionType.income
                                  ? "Ingreso"
                                  : "Egreso",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              NumberFormat.currency(
                                locale: 'es_MX',
                                symbol: '\$',
                              ).format(transaction.amount),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: transaction.type == TransactionType.income
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Detalles
                      _buildDetailItem(
                        "Descripción",
                        transaction.description,
                        Icons.description,
                      ),

                      _buildDetailItem(
                        "Fecha",
                        DateFormat('dd MMMM yyyy', 'es').format(transaction.date),
                        Icons.calendar_today,
                      ),

                      _buildDetailItem(
                        "Hora",
                        DateFormat('HH:mm:ss', 'es').format(transaction.date),
                        Icons.access_time,
                      ),

                      _buildDetailItem(
                        "ID de Transacción",
                        transaction.id,
                        Icons.fingerprint,
                      ),
                    ],
                  ),
                ),
              ),

              // Botones de acción
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.close),
                        label: Text("Cerrar"),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final String description;
  final double amount;
  final TransactionType type;
  final DateTime date;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
  });
}