import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PaymentService {
  // Base URL for the main API
  static const String baseUrl = 'https://farmaciaserver-ashen.vercel.app/api/v1';

  // Base URL for the bodega API
  static const String bodegaUrl = 'https://bodega-server.vercel.app/api/v1';

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
        // Step 2: Register the transaction as an "egreso" in the main system
        final transactionResult = await _registerTransaction(
          descripcion: 'Pago de pedido #$codigoPedido a $proveedor ($metodoPago)',
          monto: monto,
          tipo: 'egreso',
          fecha: DateTime.now(),
        );

        // Step 3: Register the transaction as "ingreso" in the bodega system
        final bodegaResult = await _registerBodegaIngreso(
          descripcion: 'Pago de pedido #$codigoPedido a $proveedor ($metodoPago)',
          monto: monto,
        );

        return {
          'success': true,
          'message': 'Pago confirmado y transacciones registradas exitosamente',
          'pedidoResult': paidResult,
          'transactionResult': transactionResult,
          'bodegaResult': bodegaResult,
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

  // Helper method to register transaction in main system
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

  // Helper method to register income transaction in bodega system
  static Future<Map<String, dynamic>> _registerBodegaIngreso({
    required String descripcion,
    required double monto,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$bodegaUrl/transacciones-bodega/ingreso'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'descripcion': descripcion,
          'monto': monto,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        // Try to decode error message
        try {
          final errorData = json.decode(response.body);
          return {'success': false, 'message': errorData['mensaje'] ?? 'Error al registrar ingreso en bodega'};
        } catch (e) {
          return {'success': false, 'message': 'Error al registrar ingreso en bodega: ${response.statusCode}'};
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con bodega: $e'};
    }
  }

  // Method to check if a payment is successful and retry bodega registration if needed
  static Future<Map<String, dynamic>> verifyAndRetryBodegaTransaction({
    required int pedidoId,
    required String codigoPedido,
    required String proveedor,
    required double monto,
    required String metodoPago,
  }) async {
    try {
      // Check payment status first
      final paymentStatus = await _checkPaymentStatus(pedidoId);

      if (paymentStatus['is_paid']) {
        // Payment is confirmed, try to register in bodega if it wasn't already
        return await _registerBodegaIngreso(
          descripcion: 'Pago de pedido #$codigoPedido a $proveedor ($metodoPago) - Registro Tardío',
          monto: monto,
        );
      } else {
        return {'success': false, 'message': 'El pago aún no está confirmado'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al verificar estado de pago: $e'};
    }
  }

  // Helper method to check payment status
  static Future<Map<String, dynamic>> _checkPaymentStatus(int pedidoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pedidos/status/$pedidoId'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'is_paid': responseData['estado'] == 'pagado',
          'data': responseData
        };
      } else {
        return {'success': false, 'is_paid': false, 'message': 'Error al verificar estado'};
      }
    } catch (e) {
      return {'success': false, 'is_paid': false, 'message': 'Error de conexión: $e'};
    }
  }
}