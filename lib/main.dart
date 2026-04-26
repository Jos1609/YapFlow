import 'package:flutter/material.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/notifications/notification_service.dart';
import 'core/background/background_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Usar nuestro callback puro (que está libre de dependencias de UI)
  await NotificationsListener.initialize(callbackHandle: onYapFlowEvent);
  
  final notificationService = NotificationService();
  await notificationService.init();
  
  runApp(const YapFlowApp());
}

class YapFlowApp extends StatelessWidget {
  const YapFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YapFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const DashboardScreen(),
    );
  }
}
