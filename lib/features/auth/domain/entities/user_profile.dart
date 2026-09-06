/// The local identity created after Google sign-in.
///
/// Semestra is offline-first: the Google account only supplies identity
/// (email, name, photo). Everything else — including the chosen [username] —
/// lives on-device in the single-row `user_profile` table.
class UserProfile {
  final String googleId;
  final String email;
  final String displayName;
  final String? photoUrl;

  /// Locally-chosen handle. Null until the username onboarding step completes.
  final String? username;

  /// Set once the user has finished onboarding (username + at least one
  /// subject). Null means onboarding is still in progress.
  final DateTime? onboardedAt;

  const UserProfile({
    required this.googleId,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.username,
    this.onboardedAt,
  });

  bool get hasUsername => username != null && username!.trim().isNotEmpty;
  bool get isOnboarded => onboardedAt != null;

  UserProfile copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    String? username,
    DateTime? onboardedAt,
  }) {
    return UserProfile(
      googleId: googleId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      username: username ?? this.username,
      onboardedAt: onboardedAt ?? this.onboardedAt,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final onboarded = map['onboarded_at'] as String?;
    return UserProfile(
      googleId: map['google_id'] as String,
      email: map['email'] as String,
      displayName: map['display_name'] as String,
      photoUrl: map['photo_url'] as String?,
      username: map['username'] as String?,
      onboardedAt: (onboarded != null && onboarded.isNotEmpty)
          ? DateTime.parse(onboarded)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'google_id': googleId,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'username': username,
      'onboarded_at': onboardedAt?.toIso8601String(),
    };
  }
}
