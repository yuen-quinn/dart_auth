class OAuthProfile {
  final String providerId;
  final String email;
  final String? name;
  final String? avatar;
  final Map<String, dynamic> raw;

  OAuthProfile({
    required this.providerId,
    required this.email,
    this.name,
    this.avatar,
    required this.raw,
  });
}


/// OAuth authentication exception
class DartAuthException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  DartAuthException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('DartAuthException');
    if (code != null) {
      buffer.write('[$code]');
    }
    buffer.write(': $message');
    if (originalError != null) {
      buffer.write(' (original error: $originalError)');
    }
    return buffer.toString();
  }
}
