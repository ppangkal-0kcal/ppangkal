/// The signup response only includes {id, name, daily_goal_calories};
/// GET /users/me includes the full profile. All fields besides id/name
/// are therefore nullable here rather than split into two model classes.
class User {
  final String id;
  final String name;

  /// Login email — `null` for accounts created by app 1.0.0 (ID-only login)
  /// until they link one from 마이페이지 (`PUT /users/me/credentials`).
  final String? email;
  final String? gender;
  final int? age;
  final double? height;
  final double? weight;
  final String? activityLevel;
  final int? dailyGoalCalories;

  const User({
    required this.id,
    required this.name,
    this.email,
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.activityLevel,
    this.dailyGoalCalories,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        gender: json['gender'] as String?,
        age: json['age'] as int?,
        height: (json['height'] as num?)?.toDouble(),
        weight: (json['weight'] as num?)?.toDouble(),
        activityLevel: json['activity_level'] as String?,
        dailyGoalCalories: json['daily_goal_calories'] as int?,
      );
}
