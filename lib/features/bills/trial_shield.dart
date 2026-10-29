import '../ledger/shared_ledger.dart' show fnv1a32;

/// A Free Trial Shield reminder before a trial converts to paid.
class TrialReminder {
  const TrialReminder({
    required this.notificationId,
    required this.fireAt,
    required this.hoursBefore,
  });

  final int notificationId;
  final DateTime fireAt;
  final int hoursBefore;

  @override
  bool operator ==(Object other) =>
      other is TrialReminder &&
      other.notificationId == notificationId &&
      other.fireAt == fireAt &&
      other.hoursBefore == hoursBefore;

  @override
  int get hashCode => Object.hash(notificationId, fireAt, hoursBefore);

  @override
  String toString() =>
      'TrialReminder($notificationId, $fireAt, ${hoursBefore}h)';
}

/// When to warn about a trial (48 h and 12 h before it charges), and stable
/// notification ids so reminders can be cancelled or rescheduled.
abstract final class TrialShield {
  static const reminderHours = [48, 12];

  /// Reminders still in the future. If the 48 h mark already passed (trial
  /// logged late) only the remaining ones are returned.
  static List<TrialReminder> remindersFor({
    required String subscriptionId,
    required DateTime billingDate,
    required DateTime now,
  }) {
    final ids = notificationIds(subscriptionId);
    return [
      for (var i = 0; i < reminderHours.length; i++)
        if (billingDate.subtract(Duration(hours: reminderHours[i]))
            case final at when at.isAfter(now))
          TrialReminder(
            notificationId: ids[i],
            fireAt: at,
            hoursBefore: reminderHours[i],
          ),
    ];
  }

  /// Two ids per subscription, derived from its id (FNV-1a), kept positive
  /// and within Android's 32-bit notification id range.
  static List<int> notificationIds(String subscriptionId) {
    final hash = fnv1a32(subscriptionId.codeUnits);
    final base = (hash & 0x3fffffff) * 2 % 0x7ffffffe;
    return [base, base + 1];
  }

  /// "2d 4h", "5h 12m", "18m", or "now".
  static String countdown(DateTime until, DateTime now) {
    final left = until.difference(now);
    if (left <= Duration.zero) return 'now';
    final days = left.inDays;
    final hours = left.inHours % 24;
    final minutes = left.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h';
    if (left.inHours > 0) return '${left.inHours}h ${minutes}m';
    return '${left.inMinutes.clamp(1, 59)}m';
  }
}
