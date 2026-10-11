/// Stub implementation of WebAudioTtsHelper for mobile and desktop platforms.
void unlockWebAudio() {}

void playWebAudio(
  String url, {
  void Function()? onStart,
  void Function()? onComplete,
}) {}

void playMalayalamTtsStreamWeb(
  String text, {
  void Function()? onStart,
  void Function()? onComplete,
}) {}

void speakWebSubtitleText(
  String text, {
  void Function()? onStart,
  void Function()? onComplete,
}) {}

void playMoietyResultAudioWeb({
  required bool isMatch,
  required String promptText,
  String? audioUrl,
  void Function()? onStart,
  void Function()? onComplete,
}) {}

void stopWebAudioAndSpeech() {}
