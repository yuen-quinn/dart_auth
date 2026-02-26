import 'models.dart';
import 'provider.dart';
import 'utils.dart';

class AuthX {
  final Map<String, OAuthProvider> _providers = {};
  final Map<String, DateTime> _states = {};
  final Duration expiration;

  AuthX({this.expiration = const Duration(minutes: 5)});

  // Register third-party OAuth provider
  void registerProvider(String id, OAuthProvider provider) {
    _providers[id] = provider;
  }

  // Generate authorization URL with state parameter
  Uri getAuthorizationUrl(String providerId) {
    final provider = _providers[providerId]!;
    final state = generateState();

    // Save state with configurable expiration
    _states[state] = DateTime.now().add(expiration);

    return provider.authorizationUrl(state);
  }

  // Validate state without removing it (for debugging)
  bool isStateValid(String state) {
    if (!_states.containsKey(state)) {
      return false;
    }
    final expirationTime = _states[state]!;
    if (DateTime.now().isAfter(expirationTime)) {
      _states.remove(state);
      return false;
    }
    return true;
  }

  // Clean up expired states
  void cleanStates() {
    final now = DateTime.now();
    _states.removeWhere((_, expiry) => now.isAfter(expiry));
  }

  // Handle callback and return OAuthProfile
  Future<OAuthProfile> handleCallback({
    required String providerId,
    required Map<String, String> query,
  }) async {
    try {
      final code = query["code"];
      final state = query["state"];

      if (code == null || state == null) {
        throw DartAuthException(
          message: "Invalid callback parameters: code and state are required",
          code: "INVALID_CALLBACK_PARAMS",
        );
      }

      if (!_states.containsKey(state)) {
        throw DartAuthException(
          message: "Invalid or expired state",
          code: "INVALID_OR_EXPIRED_STATE",
        );
      }

      // Check if state has expired
      final expirationTime = _states[state]!;
      if (DateTime.now().isAfter(expirationTime)) {
        _states.remove(state);
        throw DartAuthException(
          message: "State has expired (more than $expiration)",
          code: "INVALID_OR_EXPIRED_STATE",
        );
      }

      // Remove state to prevent reuse
      _states.remove(state);

      final provider = _providers[providerId];
      if (provider == null) {
        throw DartAuthException(
          message: "Provider '$providerId' is not registered",
          code: "PROVIDER_NOT_FOUND",
        );
      }

      // Fetch user profile from third-party provider
      final profile = await provider.getProfile(code);

      // Return OAuthProfile
      return profile;
    } catch (e, stackTrace) {
      if (e is DartAuthException) {
        rethrow;
      }
      throw DartAuthException(
        message: "Failed to handle callback: ${e.toString()}",
        code: "CALLBACK_HANDLING_FAILED",
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}