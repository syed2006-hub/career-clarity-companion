import 'package:cloud_firestore/cloud_firestore.dart';

class DomainModel {
  final String name;
  final String domainImgUrl;
  final String intro;

  DomainModel({
    required this.name,
    required this.domainImgUrl,
    required this.intro,
  });

  // Build model from Firestore snapshot
  factory DomainModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return DomainModel(
      name: data?['name'] ?? doc.id, // prefer field, fallback to doc.id
      domainImgUrl: data?['domainImgUrl'] ?? '',
      intro: data?['intro'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'domainImgUrl': domainImgUrl, 'intro': intro};
  }
}
