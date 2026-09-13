import '../../features/item/domain/entities/item_entity.dart';

class DeadlineNotificationPlan {
  static const reminderHour = 9;

  final int id;
  final String itemId;
  final DateTime scheduledFor;
  final String title;
  final String body;
  final String payload;

  const DeadlineNotificationPlan({
    required this.id,
    required this.itemId,
    required this.scheduledFor,
    required this.title,
    required this.body,
    required this.payload,
  });

  static DeadlineNotificationPlan? fromItem(ItemEntity item, {DateTime? now}) {
    if (item.type == ItemType.note ||
        item.isCompleted ||
        item.dueDate == null) {
      return null;
    }

    final clock = now ?? DateTime.now();
    final due = item.dueDate!;
    final dueDay = DateTime(due.year, due.month, due.day);
    if (dueDay.isBefore(DateTime(clock.year, clock.month, clock.day))) {
      return null;
    }

    var scheduledFor = DateTime(due.year, due.month, due.day - 1, reminderHour);
    if (!scheduledFor.isAfter(clock)) {
      scheduledFor = DateTime(due.year, due.month, due.day, reminderHour);
    }
    if (!scheduledFor.isAfter(clock)) return null;

    return DeadlineNotificationPlan(
      id: notificationIdFor(item.id),
      itemId: item.id,
      scheduledFor: scheduledFor,
      title: '${item.title} is due ${_relativeDueLabel(dueDay, clock)}',
      body: item.type == ItemType.assignment
          ? 'Assignment deadline coming up.'
          : 'Task deadline coming up.',
      payload: item.id,
    );
  }

  static int notificationIdFor(String itemId) {
    var hash = 0x811c9dc5;
    for (final unit in itemId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  static String _relativeDueLabel(DateTime dueDay, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final diff = dueDay.difference(today).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    return 'soon';
  }
}
