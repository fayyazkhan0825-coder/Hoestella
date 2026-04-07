enum UserRole { student, admin, warden, guard }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? roomNumber;
  final String? phone;
  final bool phoneVerified;
  final bool isProfileLoaded;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.roomNumber,
    this.phone,
    this.phoneVerified = false,
    this.isProfileLoaded = true,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: _roleFromString(data['role'] as String?),
      roomNumber: data['roomNumber'] as String?,
      phone: data['phone'] as String?,
      phoneVerified: data['phoneVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'roomNumber': roomNumber,
      'phone': phone,
      'phoneVerified': phoneVerified,
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? roomNumber,
    String? phone,
    bool? phoneVerified,
    bool? isProfileLoaded,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      roomNumber: roomNumber ?? this.roomNumber,
      phone: phone ?? this.phone,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      isProfileLoaded: isProfileLoaded ?? this.isProfileLoaded,
    );
  }

  static UserRole _roleFromString(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'warden':
        return UserRole.warden;
      case 'guard':
        return UserRole.guard;
      case 'student':
      default:
        return UserRole.student;
    }
  }
}

