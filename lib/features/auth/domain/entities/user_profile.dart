/// The local, offline-first identity.
///
/// Semestra has no accounts and no network sign-in — the user simply picks a
/// [username] on first launch. Everything lives on-device in the single-row
/// `user_profile` table. [id] is a locally generated identifier (it maps to the
/// legacy `google_id` primary-key column so no schema migration is needed).
class UserProfile {
  final String id;

  /// Locally-chosen handle. Empty until the username step completes.
  final String username;

  /// Optional friendly display name. Defaults to the username when unset.
  final String displayName;

  const UserProfile({
    required this.id,
    required this.username,
    this.displayName = '',
  });

  bool get hasUsername => username.trim().isNotEmpty;

  /// A name suitable for greetings — the display name if set, else the handle.
  String get greetingName =>
      displayName.trim().isNotEmpty ? displayName.trim() : username;

  UserProfile copyWith({
    String? username,
    String? displayName,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['google_id'] as String,
      username: (map['username'] as String?) ?? '',
      displayName: (map['display_name'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'google_id': id,
      // `email` / `display_name` are NOT NULL legacy columns — keep them
      // satisfied with local values. Email is unused offline.
      'email': '',
      'display_name': displayName,
      'photo_url': null,
      'username': username,
      'onboarded_at': null,
    };
  }
}
