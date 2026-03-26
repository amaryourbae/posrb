import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/echo_service.dart';

final echoServiceProvider = Provider<EchoService>((ref) {
  return EchoService();
});
