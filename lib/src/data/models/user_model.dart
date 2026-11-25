import 'package:equatable/equatable.dart';

/// Domain user entity. Parsing belongs in factories / data mappers.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.city,
    this.photoUrl,
    this.role = 'user',
    this.createdAt,
  });

  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String? city;
  final String? photoUrl;
  final String role;
  final DateTime? createdAt;

  factory AppUser.empty() => const AppUser(id: '', email: '');

  /// Null-safe JSON factory with map pattern matching.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': final Object? id,
        'email': final Object? email,
      } =>
        AppUser(
          id: id?.toString() ?? '',
          email: email?.toString() ?? '',
          name: json['name']?.toString() ?? json['full_name']?.toString(),
          phone: json['phone']?.toString() ?? json['phone_number']?.toString(),
          city: json['city']?.toString(),
          photoUrl: json['photoUrl']?.toString() ?? json['avatar_url']?.toString(),
          role: json['role']?.toString() ?? 'user',
          createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
        ),
      _ => AppUser.empty(),
    };
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'phone': phone,
        'city': city,
        'photoUrl': photoUrl,
        'role': role,
        'created_at': createdAt?.toIso8601String(),
      };

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;
  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [id, email, name, phone, city, photoUrl, role, createdAt];
}



