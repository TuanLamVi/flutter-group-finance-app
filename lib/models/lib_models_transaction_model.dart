import 'package:equatable/equatable.dart';

enum TransactionType { income, expense, joinRequest }
enum TransactionStatus { pending, approved, rejected }

class TransactionModel extends Equatable {
  final String id;
  final String groupId;
  final String userId;
  final String userName;
  final TransactionType type;
  final double amount;
  final String description;
  final TransactionStatus status;
  final String? rejectionReason;
  final String? approvedBy;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final List<String>? reactions;

  const TransactionModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.userName,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    this.rejectionReason,
    this.approvedBy,
    required this.createdAt,
    this.approvedAt,
    this.reactions,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      groupId: json['groupId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      type: TransactionType.values[json['type'] ?? 0],
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      status: TransactionStatus.values[json['status'] ?? 0],
      rejectionReason: json['rejectionReason'],
      approvedBy: json['approvedBy'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      reactions: List<String>.from(json['reactions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'userId': userId,
      'userName': userName,
      'type': type.index,
      'amount': amount,
      'description': description,
      'status': status.index,
      'rejectionReason': rejectionReason,
      'approvedBy': approvedBy,
      'createdAt': createdAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'reactions': reactions,
    };
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        userId,
        userName,
        type,
        amount,
        description,
        status,
        rejectionReason,
        approvedBy,
        createdAt,
        approvedAt,
        reactions,
      ];
}