import 'provider.dart';
import 'models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleProvider implements OAuthProvider {
  final String clientId;
  final String clientSecret;
  final String redirectUri;

  GoogleProvider({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
  });

  @override
  Uri authorizationUrl(String state) {
    return Uri.https("accounts.google.com", "/o/oauth2/v2/auth", {
      "client_id": clientId,
      "redirect_uri": redirectUri,
      "response_type": "code",
      "scope": "openid email profile",
      "state": state,
    });
  }

  @override
  Future<OAuthProfile> getProfile(String code) async {
    try {
      final tokenRes = await http.post(
        Uri.parse("https://oauth2.googleapis.com/token"),
        body: {
          "code": code,
          "client_id": clientId,
          "client_secret": clientSecret,
          "redirect_uri": redirectUri,
          "grant_type": "authorization_code",
        },
      );

      if (tokenRes.statusCode != 200) {
        final error = jsonDecode(tokenRes.body);
        throw DartAuthException(
          message: "Failed to get access token: ${error['error_description'] ?? error['error']}",
          code: "TOKEN_EXCHANGE_FAILED",
          originalError: error,
        );
      }

      final tokenData = jsonDecode(tokenRes.body);
      if (tokenData["access_token"] == null) {
        throw DartAuthException(
          message: "No access token in response",
          code: "NO_ACCESS_TOKEN",
          originalError: tokenData,
        );
      }
      final accessToken = tokenData["access_token"];

      final profileRes = await http.get(
        Uri.parse("https://www.googleapis.com/oauth2/v2/userinfo"),
        headers: {"Authorization": "Bearer $accessToken"},
      );

      if (profileRes.statusCode != 200) {
        throw DartAuthException(
          message: "Failed to fetch user profile: HTTP ${profileRes.statusCode}",
          code: "PROFILE_FETCH_FAILED",
          originalError: profileRes.body,
        );
      }

      final data = jsonDecode(profileRes.body);
      if (data["email"] == null) {
        throw DartAuthException(
          message: "Email not provided in user profile",
          code: "MISSING_EMAIL",
          originalError: data,
        );
      }

      return OAuthProfile(
        providerId: data["id"] ?? "unknown",
        email: data["email"],
        name: data["name"],
        avatar: data["picture"],
        raw: data,
      );
    } catch (e, stackTrace) {
      if (e is DartAuthException) {
        rethrow;
      }
      throw DartAuthException(
        message: "Failed to get user profile: ${e.toString()}",
        code: "GET_PROFILE_FAILED",
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}