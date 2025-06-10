import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier();
});

class SessionState {
  final bool isLoggedIn;
  final String? loginType; // 'owner' or 'attendance'
  final bool isInitialized;

  SessionState({
    this.isLoggedIn = false,
    this.loginType,
    this.isInitialized = false,
  });

  SessionState copyWith({
    bool? isLoggedIn,
    String? loginType,
    bool? isInitialized,
  }) {
    return SessionState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      loginType: loginType ?? this.loginType,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier() : super(SessionState()) {
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final loginType = prefs.getString('loginType');

      state = SessionState(
        isLoggedIn: isLoggedIn,
        loginType: loginType,
        isInitialized: true,
      );
    } catch (e) {
      // If there's an error, still mark as initialized but not logged in
      state = SessionState(isInitialized: true);
    }
  }

  Future<void> login(String loginType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('loginType', loginType);

      state = state.copyWith(
        isLoggedIn: true,
        loginType: loginType,
      );
    } catch (e) {
      // Handle error if needed
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('loginType');

      state = SessionState(isInitialized: true);
    } catch (e) {
      // Handle error if needed
      rethrow;
    }
  }
}
