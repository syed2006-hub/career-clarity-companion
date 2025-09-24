class CourseModel {
  final String id;
  final String title;
  final String platform;
  final String url;
  final String imageUrl;
  final String price;
  final String summary;
  final double rating;
  final int reviews;
  final List<String> instructors;

  CourseModel({
    required this.id,
    required this.title,
    required this.platform,
    required this.url,
    required this.imageUrl,
    required this.price,
    required this.summary,
    required this.rating,
    required this.reviews,
    required this.instructors,
  });

  /// Create model from your asset JSON (list structure)
  factory CourseModel.fromUdemyJson(Map<String, dynamic> data) {
    return CourseModel(
      id: data['id']?.toString() ?? '', // JSON may not have id
      title: data['title'] ?? 'No Title',
      platform: "Udemy",
      url: data['url'] ?? '',
      imageUrl: data['photo'] ?? '',
      price: data['price'] ?? 'Free',
      summary: '', // no summary in asset JSON
      rating: double.tryParse(data['rating'] ?? "0.0") ?? 0.0,
      reviews: int.tryParse(
            (data['numRatings'] ?? "0").toString().replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0,
      instructors: [], // asset JSON has no instructors
    );
  }

  /// Convert Firestore → Model
  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      id: map['id'] ?? '',
      title: map['title'] ?? 'No Title',
      platform: map['platform'] ?? '',
      url: map['url'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: map['price'] ?? 'Free',
      summary: map['summary'] ?? '',
      rating: (map['rating'] is double)
          ? map['rating']
          : double.tryParse(map['rating'].toString()) ?? 0.0,
      reviews: map['reviews'] ?? 0,
      instructors:
          map['instructors'] != null ? List<String>.from(map['instructors']) : [],
    );
  }

  /// Convert Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'platform': platform,
      'url': url,
      'imageUrl': imageUrl,
      'price': price,
      'summary': summary,
      'rating': rating,
      'reviews': reviews,
      'instructors': instructors,
    };
  }
}
