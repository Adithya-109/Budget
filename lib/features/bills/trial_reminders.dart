import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

import '../../core/database/app_database.dart';
import '../../core/money.dart';
import 'trial_shield.dart';

part 'trial_reminders.g.dart';

/// Free Trial Shield: high-priority local notifications 48 h and 12 h
/// before a trial converts to paid, opening the cancel page on tap.
///
/// A no-op on web and wherever the plugin isn't registered (widget tests).
class TrialReminderScheduler {
  TrialReminderScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<bool>? _ready;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'trial_shield',
      'Free Trial Shield',
      channelDescription: 'Warnings before a free trial charges your card',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBanner: true,
    ),
  );

  Future<bool> _init() => _ready ??= _initialize();

  Future<bool> _initialize() async {
    if (kIsWeb) return false;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: _onTap,
      );
      // Cold start from a tapped reminder.
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        final response = launch!.notificationResponse;
        if (response != null) _onTap(response);
      }
      return true;
    } on MissingPluginException {
      return false;
    }
  }

  static void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final uri = Uri.tryParse(payload);
    if (uri != null && uri.hasScheme) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Asks for notification permission (Android 13+, iOS). Returns whether
  /// reminders can be shown.
  Future<bool> requestPermission() async {
    if (!await _init()) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            sound: true,
            badge: true,
          ) ??
          false;
    }
    return false;
  }

  /// (Re)schedules the reminders for one trial; cancels them for anything
  /// that is no longer an active trial.
  Future<void> schedule(
    Subscription sub, {
    required DateTime now,
    required String symbol,
  }) async {
    if (!await _init()) return;
    await cancel(sub.id);
    if (!sub.isActive || !sub.isFreeTrial) return;
    final price = Money.format(Money.toMinor(sub.amount), symbol: symbol);
    for (final reminder in TrialShield.remindersFor(
      subscriptionId: sub.id,
      billingDate: sub.billingDate,
      now: now,
    )) {
      await _plugin.zonedSchedule(
        id: reminder.notificationId,
        // An absolute instant: UTC keeps it correct across time zones.
        scheduledDate: tz.TZDateTime.from(reminder.fireAt, tz.UTC),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: '⏰ ${sub.name} charges in ${reminder.hoursBefore}h',
        body: '$price will hit your card. Tap to cancel before it does.',
        payload: sub.cancelUrl ?? 'splitburn://bills',
      );
    }
  }

  Future<void> cancel(String subscriptionId) async {
    if (!await _init()) return;
    for (final id in TrialShield.notificationIds(subscriptionId)) {
      await _plugin.cancel(id: id);
    }
  }

  /// Makes the scheduled reminders match the active subscriptions (run on
  /// launch / resume, so edits made elsewhere and reboots are covered).
  Future<void> resync(
    List<Subscription> subscriptions, {
    required DateTime now,
    required String symbol,
  }) async {
    if (!await _init()) return;
    for (final sub in subscriptions) {
      await schedule(sub, now: now, symbol: symbol);
    }
  }
}

@Riverpod(keepAlive: true)
TrialReminderScheduler trialReminderScheduler(Ref ref) =>
    TrialReminderScheduler();
