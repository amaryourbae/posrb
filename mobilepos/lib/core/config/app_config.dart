class AppConfig {
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'prod',
  );

  // --- Base URLs ---
  static const String _localUrl = 'http://127.0.0.1:8000';
  static const String _emulatorUrl = 'http://10.0.2.2:8000';
  static const String _prodUrl =
      'https://ruangbincang.coffee';

  // --- Reverb/Pusher Config ---
  static const String _localHost = '127.0.0.1';
  static const String _prodHost =
      'ruangbincang.coffee';

  static String get baseUrl {
    switch (environment) {
      case 'prod':
        return _prodUrl;
      case 'emulator':
        return _emulatorUrl;
      default:
        return _localUrl;
    }
  }

  static String get apiUrl => '$baseUrl/api';

  // --- WebSocket Config ---
  static String get reverbHost {
    switch (environment) {
      case 'prod':
        return _prodHost;
      case 'emulator':
        return '10.0.2.2';
      default:
        return _localHost;
    }
  }

  static int get reverbPort =>
      environment == 'prod' ? 443 : 8080; // Standard HTTP port for Reverb, use 443 for Prod with SSL
  static String get reverbKey =>
      'xdik7l2qogd6m5qz8qn7'; // Ensure this matches .env
  static String get reverbCluster => 'mt1';

  static bool get useTls {
    return environment == 'prod';
  }
}
