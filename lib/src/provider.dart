import 'models.dart';

abstract class OAuthProvider {
  Uri authorizationUrl(String state);
  Future<OAuthProfile> getProfile(String code);
}
