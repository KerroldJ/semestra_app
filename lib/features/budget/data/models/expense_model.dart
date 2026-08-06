import '../../domain/entities/expense_entity.dart';

class ExpenseModel {
  final String id;
  final String category;
  final double amount;
  final String date;
  final String description;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const ExpenseModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: map['date'] as String,
      description: map['description'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'date': date,
      'description': description,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  factory ExpenseModel.fromEntity(ExpenseEntity entity) {
    return ExpenseModel(
      id: entity.id,
      category: entity.category,
      amount: entity.amount,
      date: entity.date.toIso8601String(),
      description: entity.description,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      deletedAt: entity.deletedAt?.toIso8601String(),
    );
  }

  ExpenseEntity toEntity() {
    return ExpenseEntity(
      id: id,
      category: category,
      amount: amount,
      date: DateTime.parse(date),
      description: description,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
    );
  }
}
