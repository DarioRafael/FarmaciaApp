import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CajaPage extends StatefulWidget {
  const CajaPage({super.key});

  @override
  State<CajaPage> createState() => _CajaPageState();
}

class _CajaPageState extends State<CajaPage> {
  double availableMoney = 0.0;
  double ingresos = 0.0;
  double egresos = 0.0;
  bool isLoading = true;
  List<Transaction> transactions = [];
  List<Transaction> salesTransactions = [];
  List<Transaction> restockTransactions = [];

  bool _isSalesExpanded = false;
  bool _isRestockExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchSaldo();
    _fetchTransactions();
  }

  Future<void> _fetchSaldo() async {
    const String baseUrl = 'https://modelo-server.vercel.app/api/v1';
    const String saldoEndpoint = '/saldo';

    try {
      final response = await http.get(Uri.parse('$baseUrl$saldoEndpoint'));

      if (response.statusCode == 200) {
        // Verifica la respuesta antes de intentar decodificarla
        final dynamic data = json.decode(response.body);

        // Agrega un log para ver qué tipo de datos estás recibiendo
        print('Respuesta recibida: $data');

        // Cambia la verificación para aceptar un objeto en lugar de una lista
        if (data is Map<String, dynamic> && data.containsKey('baseSaldo')) {
          setState(() {
            availableMoney = data['baseSaldo'].toDouble();
            ingresos = data['totalIngresos'].toDouble();
            egresos = data['totalEgresos'].toDouble();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el saldo: $e')),
      );
    }
  }

  Future<void> _fetchTransactions() async {
    const String baseUrl = 'https://modelo-server.vercel.app/api/v1';
    const String transactionsEndpoint = '/transacciones';

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
          });
        } else {
          throw Exception('Unexpected format or "transacciones" field not found');
        }
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading transactions: $e')),
      );
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Caja'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              _fetchSaldo();
              _fetchTransactions();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildBalanceCard(),
            ),
            SliverToBoxAdapter(
              child: _buildSummary(),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _buildTransactionSections(),
              ),
            ),
          ],
        ),
      ),
    );
  }
//comienza
  Widget _buildTransactionSections() {
    // Ordenar todas las transacciones por fecha más reciente
    transactions.sort((a, b) => b.date.compareTo(a.date));

    // Tomar solo las 5 transacciones más recientes
    final recentTransactions = transactions.take(5).toList();

    return Column(
      children: [
        // Nueva sección de transacciones recientes
        if (recentTransactions.isNotEmpty) // Solo mostrar si hay transacciones
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Transacciones Recientes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                ...recentTransactions.map((transaction) =>
                    _TransactionCard(transaction: transaction)
                ),
              ],
            ),
          ),

        // Resto del código permanece igual...
        _buildExpandableSection(
          title: 'Ventas',
          count: salesTransactions.length,
          isExpanded: _isSalesExpanded,
          transactions: salesTransactions,
          onTap: () => setState(() {
            _isSalesExpanded = !_isSalesExpanded;
            _isRestockExpanded = false;
          }),
        ),
        const SizedBox(height: 16),
        _buildExpandableSection(
          title: 'Reabastecimientos',
          count: restockTransactions.length,
          isExpanded: _isRestockExpanded,
          transactions: restockTransactions,
          onTap: () => setState(() {
            _isRestockExpanded = !_isRestockExpanded;
            _isSalesExpanded = false;
          }),
        ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required int count,
    required bool isExpanded,
    required List<Transaction> transactions,
    required VoidCallback onTap,
  }) {
    // Ordenar transacciones de más reciente a más antigua
    transactions.sort((a, b) => b.date.compareTo(a.date));

    // Número de transacciones a mostrar inicialmente
    const int initialTransactionsToShow = 10;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: onTap,
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount:
              // Si hay más de 10 transacciones, mostrar 10 + botón de cargar más
              transactions.length > initialTransactionsToShow
                  ? initialTransactionsToShow + 1
                  : transactions.length,
              itemBuilder: (context, index) {
                // Si es el último índice y hay más transacciones, mostrar botón de cargar más
                if (transactions.length > initialTransactionsToShow &&
                    index == initialTransactionsToShow) {
                  return _buildLoadMoreButton(title, transactions);
                }

                // Mostrar transacciones normalmente
                final transaction = transactions[index];
                return _TransactionCard(transaction: transaction);
              },
            ),
          ],
        ],
      ),
    );
  }

// Nuevo método para construir el botón de "Cargar más"
  Widget _buildLoadMoreButton(String title, List<Transaction> allTransactions) {
    return InkWell(
      onTap: () {
        // Aquí podrías implementar una modal o una nueva pantalla para mostrar todas las transacciones
        _showAllTransactionsModal(title, allTransactions);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Text(
          'Cargar más transacciones',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

// Método para mostrar un modal con todas las transacciones
  void _showAllTransactionsModal(String title, List<Transaction> transactions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$title (${transactions.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Theme.of(context).primaryColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return _TransactionCard(transaction: transaction);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo Disponible',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
            NumberFormat.currency(locale: 'es_MX', symbol: '\$')
                .format(availableMoney),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'Ingresos',
              amount: ingresos,
              icon: Icons.arrow_upward,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _SummaryCard(
              title: 'Egresos',
              amount: egresos,
              icon: Icons.arrow_downward,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final transaction = transactions[index];
          return _TransactionCard(transaction: transaction);
        },
        childCount: transactions.length,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });//

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(amount),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.type == TransactionType.income
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          child: Icon(
            transaction.type == TransactionType.income
                ? Icons.arrow_upward
                : Icons.arrow_downward,
            color: transaction.type == TransactionType.income
                ? Colors.green
                : Colors.red,
          ),
        ),
        title: Text(transaction.description),
        subtitle: Text(
          DateFormat('dd/MM/yyyy').format(transaction.date),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          NumberFormat.currency(locale: 'es_MX', symbol: '\$')
              .format(transaction.amount),
          style: TextStyle(
            color: transaction.type == TransactionType.income
                ? Colors.green
                : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
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
