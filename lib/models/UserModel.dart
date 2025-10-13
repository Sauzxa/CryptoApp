class ProfilePhoto {
  final String? url;
  final String? cloudinaryId;

  ProfilePhoto({this.url, this.cloudinaryId});

  factory ProfilePhoto.fromJson(Map<String, dynamic> json) {
    return ProfilePhoto(url: json['url'], cloudinaryId: json['cloudinaryId']);
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'cloudinaryId': cloudinaryId};
  }
}

class UserModel {
  final String? id;
  final String name;
  final String email;
  final String phone;
  final String? password; // Only for registration, not returned from server
  final String role; // 'admin', 'commercial', 'field'
  final String?
  availability; // 'available', 'not_available' - only for field agents
  final DateTime? dateAvailable; // Timestamp when agent became available/unavailable
  final ProfilePhoto? profilePhoto;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.password,
    required this.role,
    this.availability,
    this.dateAvailable,
    this.profilePhoto,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor for creating UserModel from JSON (API response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      availability: json['availability'],
      dateAvailable: json['dateAvailable'] != null
          ? DateTime.parse(json['dateAvailable'])
          : null,
      profilePhoto: json['profilePhoto'] != null
          ? ProfilePhoto.fromJson(json['profilePhoto'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Convert UserModel to JSON (for API requests)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
    };

    // Include password only if it's not null (for registration)
    if (password != null) {
      data['password'] = password;
    }

    // Include availability only for field agents
    if (availability != null) {
      data['availability'] = availability;
    }

    // Include profilePhoto if it exists
    if (profilePhoto != null) {
      data['profilePhoto'] = profilePhoto!.toJson();
    }

    return data;
  }

  // Method to create a copy of the user with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? password,
    String? role,
    String? availability,
    DateTime? dateAvailable,
    ProfilePhoto? profilePhoto,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      role: role ?? this.role,
      availability: availability ?? this.availability,
      dateAvailable: dateAvailable ?? this.dateAvailable,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters for role checking
  bool get isAdmin => role == 'admin';
  bool get isCommercial => role == 'commercial';
  bool get isField => role == 'field';

  // Helper getter for field agent availability
  bool get isAvailable => availability == 'available';

  // Helper method to get display name
  String get displayName => name;

  // Helper method to get role display name in French
  String get roleDisplayName {
    switch (role) {
      case 'admin':
        return 'Administrateur';
      case 'commercial':
        return 'Agent Commercial';
      case 'field':
        return 'Agent Terrain';
      default:
        return role;
    }
  }

  // Helper method to get availability display in French
  String get availabilityDisplayName {
    if (availability == null) return '';
    switch (availability) {
      case 'available':
        return 'Disponible';
      case 'not_available':
        return 'Non disponible';
      default:
        return availability ?? '';
    }
  }

  @override
  String toString() {
    return 'UserModel{id: $id, name: $name, email: $email, role: $role, availability: $availability}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}

// Enum for user roles (for type safety)
enum UserRole {
  admin('admin'),
  commercial('commercial'),
  field('field');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'commercial':
        return UserRole.commercial;
      case 'field':
        return UserRole.field;
      default:
        throw ArgumentError('Invalid role: $role');
    }
  }
}

// Enum for availability (for type safety)
enum UserAvailability {
  available('available'),
  notAvailable('not_available');

  const UserAvailability(this.value);
  final String value;

  static UserAvailability fromString(String availability) {
    switch (availability.toLowerCase()) {
      case 'available':
        return UserAvailability.available;
      case 'not_available':
        return UserAvailability.notAvailable;
      default:
        throw ArgumentError('Invalid availability: $availability');
    }
  }
}
