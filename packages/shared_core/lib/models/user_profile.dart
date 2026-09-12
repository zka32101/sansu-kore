class UserProfile {
  final String id;
  final String name;
  final int grade;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.grade,
    required this.createdAt,
  });

  // Alias for compatibility
  String get userId => id;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      grade: json['grade'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'grade': grade,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    int? grade,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
