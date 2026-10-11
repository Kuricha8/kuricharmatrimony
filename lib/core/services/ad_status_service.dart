import '../utils/mock_data.dart';

class AdStatusService {
  static final AdStatusService instance = AdStatusService._internal();
  AdStatusService._internal();

  /// Checks if the user is a premium subscriber. Premium subscribers get a 100% ad-free experience.
  /// This check happens instantly upon user authentication/loading using the globally cached MockData.
  bool get isPremiumUser {
    return MockData().currentUser?.isPremium ?? false;
  }
}
