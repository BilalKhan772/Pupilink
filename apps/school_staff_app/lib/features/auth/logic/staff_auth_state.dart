
class StaffAuthState {
  const StaffAuthState({
    this.isLoading = false,
    this.errorMessage,
    this.profile,
  });

  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? profile;

  bool get isLoggedIn => profile != null;

  String get name => profile?['name'] as String? ?? '';
  String get email => profile?['email'] as String? ?? '';
  String get role => profile?['role'] as String? ?? '';
  String get schoolId => profile?['schoolId'] as String? ?? '';
  String get uid => profile?['uid'] as String? ?? '';

  StaffAuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    Map<String, dynamic>? profile,
    bool clearProfile = false,
  }) {
    return StaffAuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearError ? null : errorMessage ?? this.errorMessage,
      profile: clearProfile ? null : profile ?? this.profile,
    );
  }
}
