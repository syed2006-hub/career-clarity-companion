class LeaderboardEntry {
  final String id;
  final String name;
  final String university;
  final String degree;
  final String fieldOfStudy;
  final int points;
  final String photoUrl;

  LeaderboardEntry({
    required this.id,
    required this.name,
    required this.university,
    required this.degree,
    required this.fieldOfStudy,
    required this.points,
    required this.photoUrl,
  });

  factory LeaderboardEntry.fromMap(String id, Map<String, dynamic> data) {
    return LeaderboardEntry(
      id: id,
      name: data['name'] ?? '',
      university: data['university'] ?? '',
      degree: data['degree'] ?? '',
      fieldOfStudy: data['fieldOfStudy'] ?? '',
      points: (data['points'] ?? 0) as int,
      photoUrl: data['photoUrl'] ?? '',
    );
  }
}
