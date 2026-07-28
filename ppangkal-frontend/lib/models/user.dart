/// The signup response only includes {id, name, daily_goal_calories};
/// GET /users/me includes the full profile. All fields besides id/name
/// are therefore nullable here rather than split into two model classes.
class User {
  final String id;
  final String name;
  final String? gender;
  final int? age;
  final double? height;
  final double? weight;
  final String? activityLevel;
  final int? dailyGoalCalories;

  const User({
    required this.id,
    required this.name,
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
        gender: json['gender'] as String?,
        age: json['age'] as int?,
        height: (json['height'] as num?)?.toDouble(),
        weight: (json['weight'] as num?)?.toDouble(),
        activityLevel: json['activity_level'] as String?,
        dailyGoalCalories: json['daily_goal_calories'] as int?,
      );
}
