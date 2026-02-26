import 'dart:convert';
import 'dart:math';

String generateState() {
  final rand = Random();
  return base64UrlEncode(
    List.generate(32, (_) => rand.nextInt(255)),
  );
}