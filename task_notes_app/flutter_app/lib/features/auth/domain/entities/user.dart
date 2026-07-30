class AppUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final int roleId;

  const AppUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    required this.roleId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      roleId: json['roleId'] as int? ?? 1,
    );
  }
}
