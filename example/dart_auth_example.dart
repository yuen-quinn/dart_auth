import 'package:dart_auth/dart_auth.dart';

/// Complete OAuth flow example with proper state handling
void main() async {
  // 1. Configure AuthX singleton with providers and expiration (call once)
  AuthX.configure(
    expiration: Duration(minutes: 30),
    providers: {
      'github': GitHubProvider(
        clientId: '',
        clientSecret: '',
        redirectUri: 'http://localhost:8080/api/v1/auth/github/callback',
      ),
    },
  );

  // 2. Get the singleton instance
  final authX = AuthX.instance;

  // 3. Get authorization URL (redirect user to this URL)
  final authUrl = authX.getAuthorizationUrl('github');
  print('Redirect user to: $authUrl');

  // Extract state from the URL for demonstration
  final stateFromUrl = authUrl.queryParameters['state'];
  print('\nState generated: $stateFromUrl');
  print('Important: Use this exact state from the GitHub callback!\n');

  // Simulate browser redirect and callback
  print('=== Simulating GitHub Callback ===\n');

  // In real scenario, GitHub will redirect with:
  // http://localhost:8080/api/v1/auth/github/callback?code=XXXX&state=<same_state>

  try {
    // IMPORTANT: The state must be the SAME as generated in step 3
    final profile = await authX.handleCallback(
      providerId: 'github',
      query: {
        'code': 'test_authorization_code_123',
        'state': stateFromUrl!,  // Use the state from getAuthorizationUrl()
      },
    );

    print('✓ Authentication successful!');
    print('User email: ${profile.email}');
    print('User name: ${profile.name}');
    print('Avatar: ${profile.avatar}');
  } on DartAuthException catch (e) {
    print('✗ Authentication failed: ${e.message}');
    print('Error code: ${e.code}');

    if (e.code == 'INVALID_OR_EXPIRED_STATE') {
      print('\n💡 Tips to fix "Invalid or expired state":');
      print('  1. Use the SAME state value from getAuthorizationUrl()');
      print('  2. Ensure state has not expired (default: 5 minutes)');
      print('  3. Use the SAME AuthX instance for both calls');
      print('  4. Check that you extracted the correct state from the URL');
    }
  }
}

