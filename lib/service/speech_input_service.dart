import 'package:flutter/services.dart';

class SpeechInputService {
  static const channel = MethodChannel('townpass/speech');
  Future<String?> recognize() => channel.invokeMethod<String>('recognize');
}
