import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/payment.dart';
import '../../core/background/background_handler.dart';
import '../notifications/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Payment> _payments = [];
  bool _hasPermission = false;
  final _notificationService = NotificationService();
  Timer? _refreshTimer;
  final ReceivePort _receivePort = ReceivePort();

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _loadPayments();
    
    // Escuchar el puerto de nuestra función en segundo plano
    IsolateNameServer.removePortNameMapping("yapflow_listener");
    IsolateNameServer.registerPortWithName(_receivePort.sendPort, "yapflow_listener");
    
    _receivePort.listen((message) {
      if (message == "RELOAD_PAYMENTS") {
        _loadPayments(); // Recargar pagos cuando el isolate de fondo los guarda
      }
    });

    // Auto-refresh cada 5 segundos como respaldo
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadPayments());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    IsolateNameServer.removePortNameMapping("yapflow_listener");
    _receivePort.close();
    super.dispose();
  }

  void _simulateNotification() async {
    final testEvent = NotificationEvent(
      packageName: 'com.bcp.innovacxion.yapeapp',
      title: 'Confirmación de Pago',
      text: 'Jose Qui* te envió un pago por S/ 1.5. El cód. de seguridad es: 999',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    
    onYapFlowEvent(testEvent);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Simulando Yapeo de S/ 1.50...')),
    );
    await Future.delayed(const Duration(seconds: 1));
    _loadPayments();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _notificationService.checkPermission();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<void> _loadPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final paymentStrings = prefs.getStringList('payments') ?? [];
    setState(() {
      _payments = paymentStrings.map((s) => Payment.fromJson(s)).toList();
    });
  }

  double get _totalToday {
    final now = DateTime.now();
    return _payments
        .where((p) => p.timestamp.day == now.day && p.timestamp.month == now.month && p.timestamp.year == now.year)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('YapFlow', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.bug_report),
                onPressed: _simulateNotification,
                tooltip: 'Simular Yapeo',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadPayments,
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _notificationService.requestPermission(),
              ),
            ],
          ),
          if (!_hasPermission)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Acceso a Notificaciones Requerido',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Para detectar pagos automáticamente, YapFlow necesita permiso para leer las notificaciones de tus apps bancarias.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        await _notificationService.requestPermission();
                        _checkPermission();
                      },
                      child: const Text('Conceder Permiso'),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: _buildSummaryCard(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Transacciones Recientes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          _payments.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: Text('No hay pagos registrados aún.'),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final payment = _payments[index];
                      return _buildPaymentTile(payment);
                    },
                    childCount: _payments.length,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7E3AF2), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7E3AF2).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Recibido Hoy',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(symbol: 'S/ ').format(_totalToday),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('Transacciones', _payments.length.toString()),
              _buildMiniStat('Estado', _hasPermission ? 'Activo' : 'Pausado'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildPaymentTile(Payment payment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSourceColor(payment.source).withValues(alpha: 0.1),
          child: Icon(_getSourceIcon(payment.source), color: _getSourceColor(payment.source)),
        ),
        title: Text(payment.senderName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${DateFormat('HH:mm - dd MMM').format(payment.timestamp)}${payment.securityCode != null ? ' • Cód: ${payment.securityCode}' : ''}'),
        trailing: Text(
          '+ ${NumberFormat.currency(symbol: 'S/ ').format(payment.amount)}',
          style: const TextStyle(
            color: Color(0xFF00C853),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Color _getSourceColor(PaymentSource source) {
    switch (source) {
      case PaymentSource.yape: return const Color(0xFF7E3AF2);
      case PaymentSource.plin: return const Color(0xFF00B0FF);
      case PaymentSource.bcp: return const Color(0xFF003DA5);
      default: return Colors.grey;
    }
  }

  IconData _getSourceIcon(PaymentSource source) {
    switch (source) {
      case PaymentSource.yape: return Icons.phone_android;
      case PaymentSource.plin: return Icons.account_balance_wallet;
      default: return Icons.account_balance;
    }
  }
}
