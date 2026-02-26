import 'provider.dart';
import 'models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GitHubProvider implements OAuthProvider {
  final String clientId;
  final String clientSecret;
  final String redirectUri;

  GitHubProvider({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
  });

  @override
  Uri authorizationUrl(String state) {
    return Uri.https("github.com", "/login/oauth/authorize", {
      "client_id": clientId,
      "redirect_uri": redirectUri,
      "scope": "user:email",
      "state": state,
    });
  }

  @override
  Future<OAuthProfile> getProfile(String code) async {
    try {
      final tokenRes = await http.post(
        Uri.parse("https://github.com/login/oauth/access_token"),
        headers: {
          "Accept": "application/json",
        },
        body: {
          "client_id": clientId,
          "client_secret": clientSecret,
          "code": code,
          "redirect_uri": redirectUri,
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
        Uri.parse("https://api.github.com/user"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Accept": "application/vnd.github.v3+json",
        },
      );

      if (profileRes.statusCode != 200) {
        throw DartAuthException(
          message: "Failed to fetch user profile: HTTP ${profileRes.statusCode}",
          code: "PROFILE_FETCH_FAILED",
          originalError: profileRes.body,
        );
      }

      final data = jsonDecode(profileRes.body);
      
      // GitHub might not return email directly, need to fetch separately
      String? email = data["email"];
      email ??= await _fetchPrimaryEmail(accessToken);

      if (email == null) {
        throw DartAuthException(
          message: "Email not available in user profile",
          code: "MISSING_EMAIL",
          originalError: data,
        );
      }

      return OAuthProfile(
        providerId: data["id"].toString(),
        email: email,
        name: data["name"],
        avatar: data["avatar_url"],
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

  Future<String?> _fetchPrimaryEmail(String accessToken) async {
    try {
      final res = await http.get(
        Uri.parse("https://api.github.com/user/emails"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Accept": "application/vnd.github.v3+json",
        },
      );

      if (res.statusCode != 200) {
        return null;
      }

      final emails = jsonDecode(res.body) as List;
      if (emails.isEmpty) {
        return null;
      }

      // Find primary email
      final primaryEmail = emails.firstWhere(
        (e) => e["primary"] == true,
        orElse: () => emails.first,
      );

      return primaryEmail["email"] as String?;
    } catch (e) {
      return null;
    }
  }
}
