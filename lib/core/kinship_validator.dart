import 'models/models.dart';
import 'kurichiyar_clan_engine.dart';
import 'services/firebase_firestore_service.dart';

class KinshipValidator {
  static bool checkCompatibility(UserProfile userA, UserProfile userB) {
    if (userA.gender == userB.gender) return false;

    // Check strict matching of Mother's Tharavadu -> Same clan / സഹോദര തറവാട് (Sibling Tharavadu)
    if (userA.motherClanId == userB.motherClanId && userA.motherClanId > 0) {
      return false;
    }

    final tharavaduA = (userA.motherTharavadu ?? userA.mothersTarawad ?? '')
        .trim();
    final tharavaduB = (userB.motherTharavadu ?? userB.mothersTarawad ?? '')
        .trim();

    if (tharavaduA.isNotEmpty &&
        tharavaduB.isNotEmpty &&
        tharavaduA.toLowerCase() == tharavaduB.toLowerCase()) {
      return false;
    }

    // Check Lineage Match -> forbidden Panthi-Panthi or Bandhu-Bandhu (Restricted gotram overlap)
    final moietyA = KurichiyarClanEngine.getMoiety(
      tharavaduA.isNotEmpty ? tharavaduA : (userA.clan ?? ''),
    );
    final moietyB = KurichiyarClanEngine.getMoiety(
      tharavaduB.isNotEmpty ? tharavaduB : (userB.clan ?? ''),
    );

    if (moietyA.isNotEmpty && moietyB.isNotEmpty && moietyA == moietyB) {
      return false;
    }

    return true; // Match Allowed
  }

  static Future<void> updateKinshipProfile(
    String userId,
    String motherTharavaduId,
    String tharavaduName,
  ) async {
    // Determine lineage
    final lineageType = KurichiyarClanEngine.getMoiety(
      tharavaduName,
    ).toLowerCase();
    final derivedGotram =
        'kurichiyar_gotram_${tharavaduName.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';

    // Update in Firestore
    final firestore =
        FirestoreService(); // assuming it's available or we can just import it
    await firestore.saveUserProfile(userId, {
      'mother_tharavadu_id': motherTharavaduId,
      'derived_gotram': derivedGotram,
      'lineage_type': lineageType,
    });
  }
}
