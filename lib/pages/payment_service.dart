import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PaymentService {
  // Base URL for the API
  static const String baseUrl = 'https://farmaciaserver-ashen.vercel.app/api/v1';

  // Method to mark a pedido as paid and record the transaction
  static Future<Map<String, dynamic>> confirmPayment({
    required int pedidoId,
    required String codigoPedido,
    required String proveedor,
    required double monto,
    required String metodoPago,
  }) async {
    try {
      // Step 1: Mark the pedido as paid
      final paidResult = await _markPedidoAsPaid(pedidoId);

      if (paidResult['success']) {
        // Step 2: Register the transaction as an "egreso"
        final transactionResult = await _registerTransaction(
          descripcion: 'Pago de pedido #$codigoPedido a $proveedor ($metodoPago)',
          monto: monto,
          tipo: 'egreso',
          fecha: DateTime.now(),
        );

        return {
          'success': true,
          'message': 'Pago confirmado y transacción registrada exitosamente',
          'pedidoResult': paidResult,
          'transactionResult': transactionResult,
        };
      } else {
        return {'success': false, 'message': paidResult['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al procesar el pago: $e'};
    }
  }

  // Helper method to mark pedido as paid
  static Future<Map<String, dynamic>> _markPedidoAsPaid(int pedidoId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bodega/pagar-pedido'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'pedido_id': pedidoId}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Error al marcar como pagado'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Helper method to register transaction
  static Future<Map<String, dynamic>> _registerTransaction({
    required String descripcion,
    required double monto,
    required String tipo,
    required DateTime fecha,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transacciones'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'descripcion': descripcion,
          'monto': monto,
          'tipo': tipo,
          'fecha': DateFormat('yyyy-MM-dd').format(fecha),
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'message': responseData['mensaje'] ?? 'Error al registrar transacción'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}