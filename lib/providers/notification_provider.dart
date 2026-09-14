import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notifications/browser_notification_service.dart';

final browserNotificationServiceProvider = Provider<BrowserNotificationService>((ref) {
  return BrowserNotificationService();
});

