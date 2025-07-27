import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, parent, schoolAdmin, teacher }

enum AccountType { free, premiumIndividual, schoolMember }

class UserProfile {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final AccountType accountType;
  final String? schoolId;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.accountType,
    this.schoolId,
    required this.createdAt,
    this.metadata,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.student,
      ),
      accountType: AccountType.values.firstWhere(
        (e) => e.toString() == 'AccountType.${data['accountType']}',
        orElse: () => AccountType.free,
      ),
      schoolId: data['schoolId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'accountType': accountType.toString().split('.').last,
      'schoolId': schoolId,
      'createdAt': createdAt,
      'metadata': metadata,
    };
  }

  UserProfile copyWith({
    String? name,
    UserRole? role,
    AccountType? accountType,
    String? schoolId,
    Map<String, dynamic>? metadata,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      name: name ?? this.name,
      role: role ?? this.role,
      accountType: accountType ?? this.accountType,
      schoolId: schoolId ?? this.schoolId,
      createdAt: createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
