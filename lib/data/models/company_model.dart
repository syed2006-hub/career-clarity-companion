import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyInfo {
  final String name;
  final String logoUrl;
  final double rating;
  final int reviews;

  CompanyInfo({
    required this.name,
    required this.logoUrl,
    required this.rating,
    required this.reviews,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) => CompanyInfo(
    name: json["name"] ?? "N/A",
    logoUrl: json["logoUrl"] ?? "",
    rating: (json["rating"] ?? 0).toDouble(),
    reviews: json["reviews"] ?? 0,
  );
  factory CompanyInfo.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompanyInfo(
      name: data['name'] ?? 'Unknown',
      logoUrl: data['logoUrl'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      reviews: (data['reviews'] ?? 0).toInt(),
    );
  }
  Map<String, dynamic> toJson() => {
    "name": name,
    "logoUrl": logoUrl,
    "rating": rating,
    "reviews": reviews,
  };
}
