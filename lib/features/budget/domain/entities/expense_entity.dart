import '../../../../shared/domain/entities/base_entity.dart';

class ExpenseEntity extends BaseEntity {
  final String category;
  final double amount;
  final DateTime date;
  final String description;

  const ExpenseEntity({
    required super.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.description,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  ExpenseEntity copyWith({
    String? category,
    double? amount,
    DateTime? date,
    String? description,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ExpenseEntity(
      id: id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
