// lib/data/models/user_model.dart
class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String collegeName;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.collegeName,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      collegeName: data['collegeName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'fullName': fullName, 'collegeName': collegeName};
  }
}
