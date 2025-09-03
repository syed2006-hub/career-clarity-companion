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

  /// Create model from Udemy API
  factory CourseModel.fromUdemyJson(Map<String, dynamic> data) {
    return CourseModel(
      id: data['id']?.toString() ?? '',
      title: data['title'] ?? 'No Title',
      platform: "Udemy",
      url: data['url'] != null ? "https://www.udemy.com${data['url']}" : '',
      imageUrl:
          (data['images'] != null && data['images'].isNotEmpty)
              ? data['images'].last
              : '',
      price: data['purchase']?['price']?['price_string'] ?? 'Free',
      summary:
          (data['objectives_summary'] != null &&
                  data['objectives_summary'].isNotEmpty)
              ? data['objectives_summary'].join(" • ")
              : data['headline'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      reviews: data['num_reviews'] ?? 0,
      instructors:
          data['instructors'] != null
              ? List<String>.from(
                data['instructors'].map((i) => i['display_name']),
              )
              : [],
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
      rating: (map['rating'] ?? 0).toDouble(),
      reviews: map['reviews'] ?? 0,
      instructors:
          map['instructors'] != null
              ? List<String>.from(map['instructors'])
              : [],
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
