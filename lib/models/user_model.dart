/// Basic user model used for mapping API data in and out of the app.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
  });

  /// Creates a user object from API JSON.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profile_picture'],
    );
  }

  /// Converts the model back into JSON for requests/storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_picture': profilePicture,
    };
  }
}
