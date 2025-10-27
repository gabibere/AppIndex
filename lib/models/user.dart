class User {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? profileImage;
  final List<String> roles;
  final Map<String, dynamic>? preferences;
  final DateTime lastLogin;
  final DateTime createdAt;
  final bool isActive;
  final bool isVerified;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.profileImage,
    required this.roles,
    this.preferences,
    required this.lastLogin,
    required this.createdAt,
    this.isActive = true,
    this.isVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'],
      profileImage: json['profile_image'],
      roles: (json['roles'] as List<dynamic>?)?.cast<String>() ?? [],
      preferences: json['preferences'],
      lastLogin: DateTime.parse(json['last_login'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'profile_image': profileImage,
      'roles': roles,
      'preferences': preferences,
      'last_login': lastLogin.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
      'is_verified': isVerified,
    };
  }

  String get fullName => '$firstName $lastName';
  
  String get displayName => fullName.isNotEmpty ? fullName : username;
  
  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }
    return username.isNotEmpty ? username[0].toUpperCase() : 'U';
  }
  
  bool get isAdmin => roles.contains('admin');
  
  bool get isReader => roles.contains('reader');
  
  bool get isManager => roles.contains('manager');
  
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImage,
    List<String>? roles,
    Map<String, dynamic>? preferences,
    DateTime? lastLogin,
    DateTime? createdAt,
    bool? isActive,
    bool? isVerified,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      roles: roles ?? this.roles,
      preferences: preferences ?? this.preferences,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
