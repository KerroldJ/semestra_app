import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/item/domain/entities/item_entity.dart';
import 'deadline_notification_plan.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool? _permissionGranted;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    await _configureLocalTimeZone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linux = LinuxInitializationSettings(defaultActionName: 'Open');

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
        linux: linux,
      ),
    );
    _initialized = true;
  }

  Future<void> syncItems({
    required List<ItemEntity> items,
    required bool notificationsEnabled,
  }) async {
    await initialize();
    await _plugin.cancelAll();
    if (!notificationsEnabled) {
      return;
    }
    if (!_supportsScheduledNotifications) return;

    final canNotify = await requestPermissions();
    if (!canNotify) return;

    for (final item in items) {
      await scheduleForItem(
        item,
        notificationsEnabled: notificationsEnabled,
        requestPermission: false,
      );
    }
  }

  Future<void> scheduleForItem(
    ItemEntity item, {
    required bool notificationsEnabled,
    bool requestPermission = true,
  }) async {
    await initialize();

    final notificationId = DeadlineNotificationPlan.notificationIdFor(item.id);
    await _plugin.cancel(id: notificationId);

    final plan = DeadlineNotificationPlan.fromItem(item);
    if (!notificationsEnabled ||
        plan == null ||
        !_supportsScheduledNotifications) {
      return;
    }

    if (requestPermission && !await requestPermissions()) return;

    await _plugin.zonedSchedule(
      id: plan.id,
      title: plan.title,
      body: plan.body,
      scheduledDate: tz.TZDateTime.from(plan.scheduledFor, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'deadline_reminders',
          'Deadline reminders',
          channelDescription: 'Reminders for upcoming tasks and assignments',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: plan.payload,
    );
  }

  Future<void> cancelForItem(String itemId) async {
    await initialize();
    await _plugin.cancel(
      id: DeadlineNotificationPlan.notificationIdFor(itemId),
    );
  }

  Future<bool> requestPermissions() async {
    if (!_supportsScheduledNotifications) return false;
    if (_permissionGranted == true) return true;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidGranted =
        await android?.requestNotificationsPermission() ?? true;

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosGranted =
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;

    final macOS = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    final macOSGranted =
        await macOS?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;

    _permissionGranted = androidGranted && iosGranted && macOSGranted;
    return _permissionGranted!;
  }

  bool get _supportsScheduledNotifications {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb) return;
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }
}
