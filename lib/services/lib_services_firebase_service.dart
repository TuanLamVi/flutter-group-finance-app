import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../models/announcement_model.dart';
import '../models/transaction_model.dart';
import '../utils/encryption_helper.dart';
import '../utils/phone_normalizer.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String usersCollection = 'users';
  static const String groupsCollection = 'groups';
  static const String announcementsCollection = 'announcements';
  static const String transactionsCollection = 'transactions';
  static const String commentsCollection = 'comments';

  // ================ AUTH SERVICE ================

  /// Đăng ký người dùng mới
  Future<UserModel?> registerUser({
    required String phoneNumber,
    required String fullName,
    required String password,
    required String pin,
    required String address,
    required String deviceToken,
  }) async {
    try {
      final normalizedPhone = PhoneNormalizer.normalize(phoneNumber);
      if (normalizedPhone.isEmpty) throw Exception('Số điện thoại không hợp lệ');

      // Check if phone already exists
      final existingUser = await _firestore
          .collection(usersCollection)
          .where('phoneNumber', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception('Số điện thoại đã được đăng ký');
      }

      final user = UserModel(
        id: _firestore.collection(usersCollection).doc().id,
        phoneNumber: normalizedPhone,
        fullName: fullName,
        password: EncryptionHelper.hashPassword(password),
        pin: EncryptionHelper.hashPin(pin),
        address: address,
        groupIds: [],
        deviceToken: deviceToken,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      await _firestore.collection(usersCollection).doc(user.id).set(user.toJson());
      return user;
    } catch (e) {
      print('Register error: $e');
      return null;
    }
  }

  /// Đăng nhập
  Future<UserModel?> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final normalizedPhone = PhoneNormalizer.normalize(phoneNumber);
      if (normalizedPhone.isEmpty) throw Exception('Số điện thoại không hợp lệ');

      final userQuery = await _firestore
          .collection(usersCollection)
          .where('phoneNumber', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('Tài khoản không tồn tại');
      }

      final userData = userQuery.docs.first.data();
      final user = UserModel.fromJson(userData);

      if (!EncryptionHelper.verifyPassword(password, user.password)) {
        throw Exception('Mật khẩu không đúng');
      }

      return user;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  /// Quên mật khẩu: xác thực SĐT + PIN
  Future<bool> verifyPhoneAndPin({
    required String phoneNumber,
    required String pin,
  }) async {
    try {
      final normalizedPhone = PhoneNormalizer.normalize(phoneNumber);
      if (normalizedPhone.isEmpty) throw Exception('Số điện thoại không hợp lệ');

      final userQuery = await _firestore
          .collection(usersCollection)
          .where('phoneNumber', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('Tài khoản không tồn tại');
      }

      final userData = userQuery.docs.first.data();
      final user = UserModel.fromJson(userData);

      return EncryptionHelper.verifyPin(pin, user.pin);
    } catch (e) {
      print('Verify error: $e');
      return false;
    }
  }

  /// Cập nhật mật khẩu
  Future<bool> updatePassword({
    required String phoneNumber,
    required String newPassword,
  }) async {
    try {
      final normalizedPhone = PhoneNormalizer.normalize(phoneNumber);
      if (normalizedPhone.isEmpty) throw Exception('Số điện thoại không hợp lệ');

      final userQuery = await _firestore
          .collection(usersCollection)
          .where('phoneNumber', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('Tài khoản không tồn tại');
      }

      final docId = userQuery.docs.first.id;
      await _firestore.collection(usersCollection).doc(docId).update({
        'password': EncryptionHelper.hashPassword(newPassword),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Update password error: $e');
      return false;
    }
  }

  // ================ USER SERVICE ================

  /// Lấy thông tin người dùng
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  /// Cập nhật device token
  Future<bool> updateDeviceToken({
    required String userId,
    required String deviceToken,
  }) async {
    try {
      await _firestore.collection(usersCollection).doc(userId).update({
        'deviceToken': deviceToken,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Update device token error: $e');
      return false;
    }
  }

  /// Stream người dùng theo thời gian thực
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore.collection(usersCollection).doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data()!);
    });
  }

  // ================ GROUP SERVICE ================

  /// Tạo nhóm mới
  Future<GroupModel?> createGroup({
    required String name,
    required String ownerId,
    String? description,
    String? avatarUrl,
  }) async {
    try {
      final group = GroupModel(
        id: _firestore.collection(groupsCollection).doc().id,
        name: name,
        ownerId: ownerId,
        deputies: [],
        members: [ownerId],
        balance: 0,
        description: description,
        avatarUrl: avatarUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection(groupsCollection).doc(group.id).set(group.toJson());

      // Add groupId to user's groupIds
      await _firestore.collection(usersCollection).doc(ownerId).update({
        'groupIds': FieldValue.arrayUnion([group.id]),
      });

      return group;
    } catch (e) {
      print('Create group error: $e');
      return null;
    }
  }

  /// Lấy danh sách nhóm của người dùng
  Future<List<GroupModel>> getUserGroups(String userId) async {
    try {
      final docs = await _firestore
          .collection(groupsCollection)
          .where('members', arrayContains: userId)
          .get();

      return docs.docs.map((doc) => GroupModel.fromJson(doc.data())).toList();
    } catch (e) {
      print('Get user groups error: $e');
      return [];
    }
  }

  /// Stream danh sách nhóm của người dùng
  Stream<List<GroupModel>> getUserGroupsStream(String userId) {
    return _firestore
        .collection(groupsCollection)
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => GroupModel.fromJson(doc.data())).toList();
    });
  }

  /// Lấy thông tin nhóm
  Future<GroupModel?> getGroup(String groupId) async {
    try {
      final doc = await _firestore.collection(groupsCollection).doc(groupId).get();
      if (!doc.exists) return null;
      return GroupModel.fromJson(doc.data()!);
    } catch (e) {
      print('Get group error: $e');
      return null;
    }
  }

  /// Stream thông tin nhóm theo thời gian thực
  Stream<GroupModel?> getGroupStream(String groupId) {
    return _firestore.collection(groupsCollection).doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GroupModel.fromJson(doc.data()!);
    });
  }

  /// Cập nhật số dư nhóm
  Future<bool> updateGroupBalance({
    required String groupId,
    required double newBalance,
  }) async {
    try {
      await _firestore.collection(groupsCollection).doc(groupId).update({
        'balance': newBalance,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Update group balance error: $e');
      return false;
    }
  }

  /// Đề xuất nhường quyền Trưởng nhóm
  Future<bool> proposeGroupOwner({
    required String groupId,
    required String newOwnerId,
  }) async {
    try {
      await _firestore.collection(groupsCollection).doc(groupId).update({
        'pendingOwner': newOwnerId,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Propose group owner error: $e');
      return false;
    }
  }

  /// Chấp nhận nhường quyền Trưởng nhóm
  Future<bool> acceptGroupOwnership({
    required String groupId,
    required String newOwnerId,
  }) async {
    try {
      await _firestore.collection(groupsCollection).doc(groupId).update({
        'ownerId': newOwnerId,
        'pendingOwner': null,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Accept group ownership error: $e');
      return false;
    }
  }

  // ================ ANNOUNCEMENT SERVICE ================

  /// Tạo bảng tin mới
  Future<AnnouncementModel?> createAnnouncement({
    required String groupId,
    required String authorId,
    required String authorName,
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    try {
      final announcement = AnnouncementModel(
        id: _firestore.collection(announcementsCollection).doc().id,
        groupId: groupId,
        authorId: authorId,
        authorName: authorName,
        title: title,
        content: content,
        imageUrl: imageUrl,
        reactions: [],
        comments: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection(announcementsCollection).doc(announcement.id).set(
            announcement.toJson(),
          );

      // Update lastAnnoId in group
      await _firestore.collection(groupsCollection).doc(groupId).update({
        'lastAnnoId': announcement.id,
      });

      return announcement;
    } catch (e) {
      print('Create announcement error: $e');
      return null;
    }
  }

  /// Lấy danh sách bảng tin của nhóm
  Future<List<AnnouncementModel>> getGroupAnnouncements(String groupId) async {
    try {
      final docs = await _firestore
          .collection(announcementsCollection)
          .where('groupId', isEqualTo: groupId)
          .orderBy('createdAt', descending: true)
          .get();

      return docs.docs.map((doc) => AnnouncementModel.fromJson(doc.data())).toList();
    } catch (e) {
      print('Get announcements error: $e');
      return [];
    }
  }

  /// Stream danh sách bảng tin của nhóm
  Stream<List<AnnouncementModel>> getGroupAnnouncementsStream(String groupId) {
    return _firestore
        .collection(announcementsCollection)
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AnnouncementModel.fromJson(doc.data())).toList();
    });
  }

  // ================ TRANSACTION SERVICE ================

  /// Tạo giao dịch mới
  Future<TransactionModel?> createTransaction({
    required String groupId,
    required String userId,
    required String userName,
    required TransactionType type,
    required double amount,
    required String description,
  }) async {
    try {
      final transaction = TransactionModel(
        id: _firestore.collection(transactionsCollection).doc().id,
        groupId: groupId,
        userId: userId,
        userName: userName,
        type: type,
        amount: amount,
        description: description,
        status: TransactionStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestore.collection(transactionsCollection).doc(transaction.id).set(
            transaction.toJson(),
          );

      return transaction;
    } catch (e) {
      print('Create transaction error: $e');
      return null;
    }
  }

  /// Duyệt giao dịch
  Future<bool> approveTransaction({
    required String transactionId,
    required String approvedBy,
  }) async {
    try {
      await _firestore.collection(transactionsCollection).doc(transactionId).update({
        'status': TransactionStatus.approved.index,
        'approvedBy': approvedBy,
        'approvedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Approve transaction error: $e');
      return false;
    }
  }

  /// Từ chối giao dịch
  Future<bool> rejectTransaction({
    required String transactionId,
    required String rejectionReason,
    required String approvedBy,
  }) async {
    try {
      await _firestore.collection(transactionsCollection).doc(transactionId).update({
        'status': TransactionStatus.rejected.index,
        'rejectionReason': rejectionReason,
        'approvedBy': approvedBy,
        'approvedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Reject transaction error: $e');
      return false;
    }
  }

  /// Lấy danh sách giao dịch của nhóm
  Future<List<TransactionModel>> getGroupTransactions(String groupId) async {
    try {
      final docs = await _firestore
          .collection(transactionsCollection)
          .where('groupId', isEqualTo: groupId)
          .orderBy('createdAt', descending: true)
          .get();

      return docs.docs.map((doc) => TransactionModel.fromJson(doc.data())).toList();
    } catch (e) {
      print('Get transactions error: $e');
      return [];
    }
  }

  /// Stream danh sách giao dịch của nhóm
  Stream<List<TransactionModel>> getGroupTransactionsStream(String groupId) {
    return _firestore
        .collection(transactionsCollection)
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TransactionModel.fromJson(doc.data())).toList();
    });
  }
}