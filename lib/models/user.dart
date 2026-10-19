class User {
  final String name;
  final String email;
  final String phone;
  final String location;
  final String avatarUrl;

  Map<String, Object?> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'location': location,
    'avatarUrl': avatarUrl,
  };

  factory User.fromJson(Map<String, Object?> json) => User(
    name: json['name']! as String,
    email: json['email']! as String,
    phone: json['phone']! as String,
    location: json['location']! as String,
    avatarUrl: json['avatarUrl'] as String? ?? '',
  );

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
