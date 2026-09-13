import 'package:flutter_test/flutter_test.dart';
import 'package:semestra_app/core/notifications/deadline_notification_plan.dart';
import 'package:semestra_app/features/item/domain/entities/item_entity.dart';

void main() {
  group('DeadlineNotificationPlan', () {
    final now = DateTime(2026, 9, 12, 10);

    ItemEntity item({
      required String id,
      required ItemType type,
      DateTime? dueDate,
      int status = 0,
    }) {
      return ItemEntity(
        id: id,
        type: type,
        title: 'Research draft',
        content: '',
        dueDate: dueDate,
        status: status,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('schedules an open task before a future deadline', () {
      final dueDate = DateTime(2026, 9, 15);
      final plan = DeadlineNotificationPlan.fromItem(
        item(id: 'task-1', type: ItemType.task, dueDate: dueDate),
        now: now,
      );

      expect(plan, isNotNull);
      expect(plan!.id, DeadlineNotificationPlan.notificationIdFor('task-1'));
      expect(plan.scheduledFor, DateTime(2026, 9, 14, 9));
      expect(plan.title, 'Research draft is due soon');
    });

    test(
      'does not schedule notes, completed work, missing dates, or past dates',
      () {
        final skipped = [
          item(
            id: 'note',
            type: ItemType.note,
            dueDate: now.add(const Duration(days: 3)),
          ),
          item(
            id: 'done',
            type: ItemType.assignment,
            dueDate: now.add(const Duration(days: 3)),
            status: 2,
          ),
          item(id: 'missing', type: ItemType.task),
          item(
            id: 'past',
            type: ItemType.task,
            dueDate: now.subtract(const Duration(days: 1)),
          ),
        ];

        for (final candidate in skipped) {
          expect(
            DeadlineNotificationPlan.fromItem(candidate, now: now),
            isNull,
            reason: candidate.id,
          );
        }
      },
    );
  });
}
