import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  bool get isListening => _speech.isListening;

  /// Initialize the speech engine
  Future<void> init({
    required Function(String status) onStatus,
    required Function(String error) onError,
  }) async {
    _available = await _speech.initialize(
      onStatus: (status) => onStatus(status),
      onError: (err) => onError(err.errorMsg),
    );
  }

  /// Start listening and call `onResult` with real-time recognized text
  Future<void> startListening(Function(String text) onResult) async {
    if (!_available) return;

    _speech.listen(
      onResult: (result) {
        if (result.finalResult || result.recognizedWords.isNotEmpty) {
          onResult(result.recognizedWords.trim());
        }
      },
      listenFor: const Duration(minutes: 1),
      pauseFor: const Duration(seconds: 3),
    );
  }

  /// Stop listening if active
  void stopListening() {
    if (_speech.isListening) {
      _speech.stop();
    }
  }
}
