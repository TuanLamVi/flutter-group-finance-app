import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String phoneNumber;
  final String fullName;
  final String password; // Hashed in Firebase
  final String pin; // 4-6 digit code
  final String address;
  final String? avatarUrl;
  final List<String> groupIds;
  final String deviceToken;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    required this.password,
    required this.pin,
    required this.address,
    this.avatarUrl,
    required this.groupIds,
    required this.deviceToken,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      fullName: json['fullName'] ?? '',
      password: json['password'] ?? '',
      pin: json['pin'] ?? '',
      address: json['address'] ?? '',
      avatarUrl: json['avatarUrl'],
      groupIds: List<String>.from(json['groupIds'] ?? []),
      deviceToken: json['deviceToken'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'password': password,
      'pin': pin,
      'address': address,
      'avatarUrl': avatarUrl,
      'groupIds': groupIds,
      'deviceToken': deviceToken,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? fullName,
    String? password,
    String? pin,
    String? address,
    String? avatarUrl,
    List<String>? groupIds,
    String? deviceToken,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      password: password ?? this.password,
      pin: pin ?? this.pin,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      groupIds: groupIds ?? this.groupIds,
      deviceToken: deviceToken ?? this.deviceToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        phoneNumber,
        fullName,
        password,
        pin,
        address,
        avatarUrl,
        groupIds,
        deviceToken,
        createdAt,
        updatedAt,
        isActive,
      ];
}