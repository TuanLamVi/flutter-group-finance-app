import 'package:equatable/equatable.dart';

class GroupModel extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final List<String> deputies;
  final List<String> members;
  final double balance;
  final String? description;
  final String? avatarUrl;
  final String? pendingOwner;
  final String? lastAnnoId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroupModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.deputies,
    required this.members,
    required this.balance,
    this.description,
    this.avatarUrl,
    this.pendingOwner,
    this.lastAnnoId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      ownerId: json['ownerId'] ?? '',
      deputies: List<String>.from(json['deputies'] ?? []),
      members: List<String>.from(json['members'] ?? []),
      balance: (json['balance'] ?? 0).toDouble(),
      description: json['description'],
      avatarUrl: json['avatarUrl'],
      pendingOwner: json['pendingOwner'],
      lastAnnoId: json['lastAnnoId'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'deputies': deputies,
      'members': members,
      'balance': balance,
      'description': description,
      'avatarUrl': avatarUrl,
      'pendingOwner': pendingOwner,
      'lastAnnoId': lastAnnoId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? ownerId,
    List<String>? deputies,
    List<String>? members,
    double? balance,
    String? description,
    String? avatarUrl,
    String? pendingOwner,
    String? lastAnnoId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      deputies: deputies ?? this.deputies,
      members: members ?? this.members,
      balance: balance ?? this.balance,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      pendingOwner: pendingOwner ?? this.pendingOwner,
      lastAnnoId: lastAnnoId ?? this.lastAnnoId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        ownerId,
        deputies,
        members,
        balance,
        description,
        avatarUrl,
        pendingOwner,
        lastAnnoId,
        createdAt,
        updatedAt,
      ];
}