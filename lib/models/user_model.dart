class UserModel {
  final String name;
  final String email;
  final String? photoUrl;

  UserModel({required this.name, required this.email, this.photoUrl});

  /// Convert Firebase User to UserModel
  factory UserModel.fromFirebaseUser(dynamic user) {
    return UserModel(
      name: user.displayName ?? 'Guest User',
      email: user.email ?? '',
      photoUrl: user.photoURL,
    );
  }

  /// Convert UserModel to JSON for SharedPreferences storage
  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'photoUrl': photoUrl,
  };

  /// Create UserModel from stored JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'],
      email: json['email'],
      photoUrl: json['photoUrl'],
    );
  }
}
