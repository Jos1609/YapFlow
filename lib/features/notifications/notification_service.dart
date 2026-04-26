import 'dart:async';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import '../../core/models/payment.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  
  @pragma('vm:entry-point')
  NotificationService._internal();

  final _paymentController = StreamController<Payment>.broadcast();
  Stream<Payment> get paymentStream => _paymentController.stream;

  @pragma('vm:entry-point')
  Future<void> init() async {
    bool hasPermission = await NotificationsListener.hasPermission ?? false;
    if (hasPermission) {
      print("Iniciando servicio de escucha...");
      NotificationsListener.startService(
        title: "YapFlow Activo",
        description: "Esperando pagos...",
        showWhen: true,
        foreground: false,
      );
    }
  }

  Future<void> requestPermission() async {
    await NotificationsListener.openPermissionSettings();
  }

  Future<bool> checkPermission() async {
    return await NotificationsListener.hasPermission ?? false;
  }

  void dispose() {
    _paymentController.close();
  }
}
