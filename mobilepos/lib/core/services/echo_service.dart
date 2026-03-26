import 'package:laravel_echo/laravel_echo.dart';
import 'package:pusher_client/pusher_client.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class EchoService {
  late Echo _echo;

  void init() {
    if (kIsWeb) {
      debugPrint("Echo/Pusher not supported on Web (pusher_client limitation)");
      return;
    }

    // 1. Configure Pusher Options for Reverb (Self-hosted)
    PusherOptions options = PusherOptions(
      host: AppConfig.reverbHost,
      wsPort: AppConfig.reverbPort,
      wssPort: AppConfig.reverbPort,
      encrypted: AppConfig.useTls,
      cluster: AppConfig.reverbCluster,
    );

    // 2. Initialize Pusher Client
    PusherClient pusherClient = PusherClient(
      AppConfig.reverbKey,
      options,
      autoConnect: false,
      enableLogging: kDebugMode,
    );

    // 3. Initialize Echo
    _echo = Echo(
      broadcaster: EchoBroadcasterType.Pusher,
      client: pusherClient,
      options: {
        'key': AppConfig.reverbKey,
        'cluster': AppConfig.reverbCluster,
        'wsHost': AppConfig.reverbHost,
        'wsPort': AppConfig.reverbPort,
        'wssPort': AppConfig.reverbPort,
        'forceTLS': AppConfig.useTls,
        'disableStats': true,
        'enabledTransports': ['ws', 'wss'],
      },
    );

    // 4. Connect
    pusherClient.connect();

    pusherClient.onConnectionStateChange((state) {
      debugPrint("Pusher Connection State: ${state?.currentState}");
    });

    debugPrint("Echo Service Initialized");
  }

  void listenToOrders(Function(Map<String, dynamic>) onOrderCreated) {
    if (kIsWeb) return;

    _echo.channel('orders').listen('.OrderCreated', (e) {
      debugPrint("Event Received: $e");
      if (e is Map<String, dynamic>) {
        onOrderCreated(e);
      }
    });
  }

  void disconnect() {
    _echo.disconnect();
  }

  void reconnect() {
    if (kIsWeb) return;
    try {
      disconnect();
      Future.delayed(const Duration(milliseconds: 500), () {
        init();
        // Since listeners are tied to the echo instance, we should ideally re-bind them or just trust that PosLayout re-binds.
        // Actually, re-initializing `_echo` requires re-listening. It's safer to just disconnect and let the UI call init() + listenToOrders() again.
      });
    } catch (e) {
      debugPrint("Error reconnecting Echo: $e");
    }
  }
}
