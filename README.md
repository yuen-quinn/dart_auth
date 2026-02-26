# dart_auth

A simple and flexible authentication library for Dart applications supporting multiple OAuth providers.

## Features

- 🔐 OAuth 2.0 authentication
- 🌐 Multiple provider support (GitHub, Google, and more)
- 📦 Easy integration
- 🎯 Type-safe API

## Supported Providers

- GitHub
- Google

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dart_auth: ^0.1.0
```

Then run:

```bash
dart pub get
```

## Quick Start

```dart
import 'package:dart_auth/dart_auth.dart';

void main() async {
  // Initialize with a provider
  final github = GithubProvider(
    clientId: 'your_client_id',
    clientSecret: 'your_client_secret',
    redirectUrl: 'http://localhost:3000/callback',
  );

  // Get authentication URL
  final authUrl = github.getAuthUrl();
  print('Visit: $authUrl');

  // Handle callback and get token
  final token = await github.getToken(code: 'auth_code');
  print('Token: $token');
}
```

## Examples

See the [example](example/) directory for more usage examples.

## License

MIT
