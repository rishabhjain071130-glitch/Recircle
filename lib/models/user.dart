class User {
  final String name;
  final String email;
  final String phone;
  final String location;
  final String avatarUrl;

  const User({
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    this.avatarUrl = '',
  });

  static const User defaultUser = User(
    name: 'Your Name',
    email: 'user@example.com',
    phone: '+1 234 567 890',
    location: 'Your Location',
  );

  User copyWith({
    String? name,
    String? email,
    String? phone,
    String? location,
    String? avatarUrl,
  }) {
    return User(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
