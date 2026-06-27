import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Background isolate entrypoint callback for fallbacks.
@pragma('vm:entry-point')
void fallbackAlarmCallback() async {
  if (kDebugMode) {
    // ignore: avoid_print
    print('DEBUG [MemoryOS]: Fallback Alarm Manager Callback Triggered!');
  }

  // Ensure background binding initialized
  WidgetsFlutterBinding.ensureInitialized();

  final plugin = FlutterLocalNotificationsPlugin();
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await plugin.initialize(settings: initSettings);

  await plugin.show(
    id: 9998,
    title: 'Reminder (Fallback Alert)',
    body:
        'A scheduled memory reminder has triggered via background fallback system.',
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'memory_reminders',
        'Memory Reminders',
        channelDescription: 'Notifications for MemoryOS scheduled reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
    ),
  );
}

/// Scheduling wrapper interface for notifications.
abstract class NotificationService {
  Future<void> init();
  Future<bool> requestPermissions();
  Future<bool> canScheduleExactAlarms();
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  });
  Future<void> showInstantNotification(int id, String title, String body);
  Future<void> showInstantTestNotification();
  Future<void> cancelReminder(int id);
  Future<void> cancelNotification(int id);
  Future<void> cancelAllNotifications();
  Future<List<PendingNotificationRequest>> getPendingNotifications();

  // Settings channels
  Future<void> openNotificationSettings();
  Future<void> openBatteryOptimizationSettings();

  // Variables to hold debug values
  DateTime? get lastScheduledTime;
  int? get lastScheduledId;
  String? get lastErrorMessage;

  // Diagnostics scheduled flags
  bool get isPrimaryScheduled;
  bool get isFallbackScheduled;
}

class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const _settingsChannel = MethodChannel(
    'com.memoryos.memory_os/settings',
  );

  DateTime? _lastScheduledTime;
  int? _lastScheduledId;
  String? _lastErrorMessage;
  bool _isPrimaryScheduled = false;
  bool _isFallbackScheduled = false;

  @override
  DateTime? get lastScheduledTime => _lastScheduledTime;

  @override
  int? get lastScheduledId => _lastScheduledId;

  @override
  String? get lastErrorMessage => _lastErrorMessage;

  @override
  bool get isPrimaryScheduled => _isPrimaryScheduled;

  @override
  bool get isFallbackScheduled => _isFallbackScheduled;

  @override
  Future<void> init() async {
    try {
      // 1. Initialize timezones
      tz.initializeTimeZones();
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = tzInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      // 2. Android settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // 3. iOS/macOS settings
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(settings: initSettings);

      // Create/Recreate the channel explicitly with maximum settings
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        try {
          await androidImplementation.deleteNotificationChannel(
            channelId: 'memory_reminders',
          );
        } catch (_) {}

        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'memory_reminders',
            'Memory Reminders',
            description: 'Notifications for MemoryOS scheduled reminders',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
      }

      // 4. Request permissions on app startup & print status
      final granted = await requestPermissions();
      final exactAllowed = await canScheduleExactAlarms();
      _log('DEBUG [MemoryOS]: Initialized NotificationService.');
      _log(
        'DEBUG [MemoryOS]: App Start Notification permission granted = $granted',
      );
      _log(
        'DEBUG [MemoryOS]: App Start Exact alarm permission allowed = $exactAllowed',
      );
    } catch (e) {
      _lastErrorMessage = 'Init error: $e';
      _log('DEBUG [MemoryOS]: NotificationService init error: $e');
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      // Request permission for Android (Tiramisu and above require post_notifications)
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      bool androidGranted = false;
      if (androidImplementation != null) {
        final granted = await androidImplementation
            .requestNotificationsPermission();
        androidGranted = granted ?? false;

        // Request exact alarm permission dynamically if available
        try {
          final exactAllowed = await androidImplementation
              .canScheduleExactNotifications();
          if (exactAllowed == false) {
            final exactGranted = await androidImplementation
                .requestExactAlarmsPermission();
            _log(
              'DEBUG [MemoryOS]: Android exact alarm requested: $exactGranted',
            );
          }
        } catch (e) {
          _log('DEBUG [MemoryOS]: Android exact alarm request error: $e');
        }
      }

      // Request permission for iOS
      final iosImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      bool iosGranted = false;
      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        iosGranted = granted ?? false;
      }

      return androidGranted || iosGranted;
    } catch (e) {
      _lastErrorMessage = 'Request permission error: $e';
      return false;
    }
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    try {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        final allowed = await androidImplementation
            .canScheduleExactNotifications();
        return allowed ?? false;
      }
      return true;
    } catch (e) {
      _lastErrorMessage = 'CanScheduleExactAlarms check error: $e';
      return false;
    }
  }

  @override
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    _lastScheduledId = id;
    _lastScheduledTime = scheduledDate;
    _isPrimaryScheduled = true;
    _isFallbackScheduled = true;

    try {
      final hasPermission = await requestPermissions();
      final exactAllowed = await canScheduleExactAlarms();
      final now = DateTime.now();

      _log('DEBUG [MemoryOS]: current time = $now');
      _log('DEBUG [MemoryOS]: scheduled time = $scheduledDate');
      _log('DEBUG [MemoryOS]: notification id = $id');
      _log(
        'DEBUG [MemoryOS]: notification permission granted = $hasPermission',
      );
      _log('DEBUG [MemoryOS]: exact alarm permission status = $exactAllowed');

      // Double check that we aren't scheduling in the past
      if (scheduledDate.isBefore(now)) {
        _log(
          'DEBUG [MemoryOS]: scheduledDate is in the past, skipping schedule.',
        );
        _lastErrorMessage = 'Skipped: scheduled time is in the past';
        return;
      }

      // 1. Primary scheduler
      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'memory_reminders', // channel id
            'Memory Reminders', // channel name
            channelDescription:
                'Notifications for MemoryOS scheduled reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDateTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      // 2. Fallback Alarm Manager scheduler
      try {
        final alarmSuccess = await AndroidAlarmManager.oneShotAt(
          scheduledDate,
          id,
          fallbackAlarmCallback,
          alarmClock: true,
          allowWhileIdle: true,
          exact: true,
        );
        _isFallbackScheduled = alarmSuccess;
        _log(
          'DEBUG [MemoryOS]: Fallback alarm manager scheduled = $alarmSuccess',
        );
      } catch (alarmError) {
        _isFallbackScheduled = false;
        _log('DEBUG [MemoryOS]: Fallback alarm manager error = $alarmError');
      }

      // After scheduling, print pending notifications count
      final pending = await getPendingNotifications();
      _log('DEBUG [MemoryOS]: pending notification count = ${pending.length}');
    } catch (e) {
      _lastErrorMessage = 'Schedule error: $e';
      _isPrimaryScheduled = false;
      _isFallbackScheduled = false;
      _log('DEBUG [MemoryOS]: Notification schedule error: $e');
    }
  }

  @override
  Future<void> showInstantNotification(
    int id,
    String title,
    String body,
  ) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'memory_reminders',
            'Memory Reminders',
            channelDescription:
                'Notifications for MemoryOS scheduled reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          );
      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      _lastErrorMessage = 'Instant notification error: $e';
      _log('DEBUG [MemoryOS]: Instant notification error: $e');
    }
  }

  @override
  Future<void> showInstantTestNotification() async {
    await showInstantNotification(
      9999,
      'Instant Test Alert',
      'Local notification test fired successfully!',
    );
  }

  @override
  Future<void> cancelReminder(int id) async {
    try {
      await _plugin.cancel(id: id);
      await AndroidAlarmManager.cancel(id);
      _isPrimaryScheduled = false;
      _isFallbackScheduled = false;
    } catch (e) {
      _lastErrorMessage = 'Cancel error: $e';
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    await cancelReminder(id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
      _isPrimaryScheduled = false;
      _isFallbackScheduled = false;
    } catch (e) {
      _lastErrorMessage = 'Cancel all error: $e';
    }
  }

  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (e) {
      _lastErrorMessage = 'Get pending error: $e';
      return [];
    }
  }

  @override
  Future<void> openNotificationSettings() async {
    try {
      await _settingsChannel.invokeMethod('openNotificationSettings');
    } catch (e) {
      _lastErrorMessage = 'Open notifications error: $e';
    }
  }

  @override
  Future<void> openBatteryOptimizationSettings() async {
    try {
      await _settingsChannel.invokeMethod('openBatteryOptimizationSettings');
    } catch (e) {
      _lastErrorMessage = 'Open battery error: $e';
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(message);
    }
  }
}
