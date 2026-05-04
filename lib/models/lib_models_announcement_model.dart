import 'package:equatable/equatable.dart';

class ReactionModel extends Equatable {
  final String emoji;
  final List<String> userIds;

  const ReactionModel({
    required this.emoji,
    required this.userIds,
  });

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      emoji: json['emoji'] ?? '',
      userIds: List<String>.from(json['userIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'userIds': userIds,
    };
  }

  @override
  List<Object?> get props => [emoji, userIds];
}

class CommentModel extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;
  final List<ReactionModel> reactions;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    required this.reactions,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      reactions: (json['reactions'] as List?)
              ?.map((r) => ReactionModel.fromJson(r))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'reactions': reactions.map((r) => r.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, userId, userName, content, createdAt, reactions];
}

class AnnouncementModel extends Equatable {
  final String id;
  final String groupId;
  final String authorId;
  final String authorName;
  final String title;
  final String content;
  final String? imageUrl;
  final List<ReactionModel> reactions;
  final List<CommentModel> comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AnnouncementModel({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.reactions,
    required this.comments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] ?? '',
      groupId: json['groupId'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'],
      reactions: (json['reactions'] as List?)
              ?.map((r) => ReactionModel.fromJson(r))
              .toList() ??
          [],
      comments: (json['comments'] as List?)
              ?.map((c) => CommentModel.fromJson(c))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'authorId': authorId,
      'authorName': authorName,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'comments': comments.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        authorId,
        authorName,
        title,
        content,
        imageUrl,
        reactions,
        comments,
        createdAt,
        updatedAt,
      ];
}