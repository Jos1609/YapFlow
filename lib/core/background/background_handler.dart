import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/payments/payment_parser.dart';

@pragma('vm:entry-point')
void onYapFlowEvent(NotificationEvent event) async {
  try {
    // Es ABSOLUTAMENTE VITAL inicializar los plugins en este Isolate (el nuevo motor de Kotlin)
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();
    
    // 1. Notificar a la UI si está activa
    final SendPort? send = IsolateNameServer.lookupPortByName("yapflow_listener");
    if (send != null) {
      // SOLO enviar un string simple. Enviar objetos complejos entre Isolates distintos crashea DartVM.
      send.send("RELOAD_PAYMENTS");
    }

    // 2. Parsear y guardar el pago
    final payment = PaymentParser.parse(
      event.packageName ?? '',
      event.title ?? '',
      event.text ?? '',
    );

    if (payment != null) {
      final prefs = await SharedPreferences.getInstance();
      final payments = prefs.getStringList('payments') ?? [];
      if (!payments.any((p) => p.contains(payment.id))) {
        payments.insert(0, payment.toJson());
        await prefs.setStringList('payments', payments);
      }
    }
  } catch (e, stack) {
    print("YAPFLOW_BG_ERROR: $e");
    print("YAPFLOW_BG_STACK: $stack");
  }
}
