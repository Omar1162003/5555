class User {
  final String id;
  final String name;
  final String email;
  final DateTime memberSince;
  final String? token;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.memberSince,
    this.token,
  });

  String get initials {
    return name
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .join('')
        .toUpperCase();
  }

  String get firstName => name.split(' ').first;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      memberSince:
          DateTime.tryParse(json['memberSince']?.toString() ?? '') ??
              DateTime.now(),
      token: json['token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'memberSince': memberSince.toIso8601String(),
      'token': token,
    };
  }
}