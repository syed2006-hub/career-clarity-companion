import 'dart:convert';

// A helper function to parse the entire API response
ApiResponse apiResponseFromJson(String str) =>
    ApiResponse.fromJson(json.decode(str));

// Model for the entire API response
class ApiResponse {
  final bool status;
  final int totalJobs;
  final List<JobListing> jobListings;

  ApiResponse({
    required this.status,
    required this.totalJobs,
    required this.jobListings,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) => ApiResponse(
    status: json["status"] ?? false,
    totalJobs: json["totalJobs"] ?? 0,
    jobListings: List<JobListing>.from(
      json["jobListings"]?.map((x) => JobListing.fromJson(x)) ?? [],
    ),
  );
}

class JobListing {
  final String title;
  final String url;
  final String companyName;
  final String companyLogoUrl;
  final double rating;
  final int reviews;
  final String experience;
  final String? salary;
  final String companyLocation;
  final String description;
  final List<String> allKeySkills;
  final String postedAgo;

  JobListing({
    required this.title,
    required this.url,
    required this.companyName,
    required this.companyLogoUrl,
    required this.rating,
    required this.reviews,
    required this.experience,
    this.salary,
    required this.companyLocation,
    required this.description,
    required this.allKeySkills,
    required this.postedAgo,
  });

  /// ✅ For API (old way)
  factory JobListing.fromJson(Map<String, dynamic> json) => JobListing(
    title: json["title"] ?? "No Title",
    url: json["url"] ?? "",
    companyName: json["company"]?["name"] ?? "N/A",
    companyLogoUrl: json["company"]?["logo"] ?? "",
    rating: (json["company"]?["rating"] ?? 0).toDouble(),
    reviews: json["company"]?["reviews"] ?? 0,
    experience: json["experience"]?.trim() ?? "N/A",
    salary: json["salary"],
    companyLocation: json["location"]?.trim() ?? "N/A",
    description: json["descriptionSnippet"] ?? "No Description",
    allKeySkills: List<String>.from(json["keySkills"]?.map((x) => x) ?? []),
    postedAgo: json["postedAgo"] ?? "",
  );

  /// ✅ For Firestore (flat structure)
  factory JobListing.fromMap(Map<String, dynamic> map) => JobListing(
    title: map["title"] ?? "No Title",
    url: map["url"] ?? "",
    companyName: map["companyName"] ?? "N/A",
    companyLogoUrl: map["companyLogoUrl"] ?? "",
    rating: (map["rating"] ?? 0).toDouble(),
    reviews: map["reviews"] ?? 0,
    experience: (map["experience"] ?? "N/A").toString(),
    salary: map["salary"]?.toString(),
    companyLocation: map["companyLocation"] ?? "N/A",
    description: map["description"] ?? "No Description",
    allKeySkills: List<String>.from(map["allKeySkills"] ?? []),
    postedAgo: map["postedAgo"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "title": title,
    "url": url,
    "companyName": companyName,
    "companyLogoUrl": companyLogoUrl,
    "rating": rating,
    "reviews": reviews,
    "experience": experience,
    "salary": salary,
    "companyLocation": companyLocation,
    "description": description,
    "allKeySkills": allKeySkills,
    "postedAgo": postedAgo,
  };
}
