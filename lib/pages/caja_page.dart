import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CajaPage extends StatefulWidget {
  const CajaPage({Key? key}) : super(key: key);

  @override
  State<CajaPage> createState() => _CajaPageState();
}

class _CajaPageState extends State<CajaPage> {
  double availableMoney = 0.0;
  bool isLoading = true;

  // Sample data - In a real app this would come from a database
  final List<Transaction> transactions = [
    Transaction(
      id: '1',
      description: 'Venta de productos',
      amount: 1500,
      type: TransactionType.income,
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Transaction(
      id: '2',
      description: 'Pago de servicios',
      amount: 800,
      type: TransactionType.expense,
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    // Add more sample transactions here
  ];

  @override
  void initState() {
    super.initState();
    _fetchSaldo();
  }

  Future<void> _fetchSaldo() async {
    final String baseUrl = 'https://modelo-server.vercel.app/api/v1';
    final String saldoEndpoint = '/saldo';

    try {
      final response = await http.get(Uri.parse('$baseUrl$saldoEndpoint'));

      if (response.statusCode == 200) {
        // Verifica la respuesta antes de intentar decodificarla
        final dynamic data = json.decode(response.body);

        // Agrega un log para ver qué tipo de datos estás recibiendo
        print('Respuesta recibida: $data');

        if (data is List && data.isNotEmpty && data[0] is Map<String, dynamic> && data[0].containsKey('saldo')) {
          setState(() {
            availableMoney = data[0]['saldo'].toDouble();
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
              padding: const EdgeInsets.all(16),
              sliver: _buildTransactionsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add transaction
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add),
      ),
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
              amount: 15000,
              icon: Icons.arrow_upward,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _SummaryCard(
              title: 'Egresos',
              amount: 8000,
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
  });

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
      margin: const EdgeInsets.only(bottom: 8),
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
