class UserProfile {
  UserProfile({required this.id, required this.email});

  final String id;
  final String email;

  factory UserProfile.fromApi(Map<String, dynamic> json) {
    final directId = json['id']?.toString();
    final userId = json['userId']?.toString();
    final userRoles = json['userRoles'];
    String? roleUserId;

    if (userRoles is List && userRoles.isNotEmpty) {
      final firstRole = userRoles.first;
      if (firstRole is Map) {
        roleUserId = firstRole['userId']?.toString();
      }
    }

    return UserProfile(
      id: directId ?? userId ?? roleUserId ?? '',
      email: (json['email'] ?? '').toString(),
    );
  }
}
