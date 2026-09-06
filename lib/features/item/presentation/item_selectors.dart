import '../domain/entities/item_entity.dart';

/// Urgency buckets used by the Assignments and Today screens.
enum Urgency { overdue, thisWeek, later }

extension ItemDueX on ItemEntity {
  /// True for tasks/assignments that are still open and dated.
  bool get isOpenDated =>
      type != ItemType.note && dueDate != null && !isCompleted;

  Urgency urgencyFrom(DateTime now) {
    final start = DateTime(now.year, now.month, now.day);
    final d = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final diff = d.difference(start).inDays;
    if (diff < 0) return Urgency.overdue;
    if (diff <= 7) return Urgency.thisWeek;
    return Urgency.later;
  }
}

/// Splits open dated items into ordered urgency buckets.
class UrgencyGroups {
  final List<ItemEntity> overdue;
  final List<ItemEntity> thisWeek;
  final List<ItemEntity> later;

  const UrgencyGroups(this.overdue, this.thisWeek, this.later);

  bool get isEmpty => overdue.isEmpty && thisWeek.isEmpty && later.isEmpty;
  int get total => overdue.length + thisWeek.length + later.length;

  static UrgencyGroups from(List<ItemEntity> items, DateTime now) {
    final open = items.where((i) => i.isOpenDated).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    final overdue = <ItemEntity>[];
    final week = <ItemEntity>[];
    final later = <ItemEntity>[];
    for (final i in open) {
      switch (i.urgencyFrom(now)) {
        case Urgency.overdue:
          overdue.add(i);
          break;
        case Urgency.thisWeek:
          week.add(i);
          break;
        case Urgency.later:
          later.add(i);
          break;
      }
    }
    return UrgencyGroups(overdue, week, later);
  }
}

/// Recency buckets for the Notes screen.
class NoteGroups {
  final List<ItemEntity> today;
  final List<ItemEntity> thisWeek;
  final List<ItemEntity> earlier;

  const NoteGroups(this.today, this.thisWeek, this.earlier);

  bool get isEmpty => today.isEmpty && thisWeek.isEmpty && earlier.isEmpty;

  static NoteGroups from(List<ItemEntity> items, DateTime now) {
    final notes = items.where((i) => i.type == ItemType.note).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final start = DateTime(now.year, now.month, now.day);
    final today = <ItemEntity>[];
    final week = <ItemEntity>[];
    final earlier = <ItemEntity>[];
    for (final n in notes) {
      final u = DateTime(n.updatedAt.year, n.updatedAt.month, n.updatedAt.day);
      final diff = start.difference(u).inDays;
      if (diff <= 0) {
        today.add(n);
      } else if (diff <= 7) {
        week.add(n);
      } else {
        earlier.add(n);
      }
    }
    return NoteGroups(today, week, earlier);
  }
}
