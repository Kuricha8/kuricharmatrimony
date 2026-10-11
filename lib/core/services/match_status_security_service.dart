import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../security/guest_security_service.dart';
import '../utils/mock_data.dart';
import 'digipin_service.dart';

/// Security & Privacy Service for Match Status Validation and House GPS Navigation
class MatchStatusSecurityService {
  /// Cache of verified mutual accepted status with TTL
  static final Map<String, ({bool isMutual, DateTime checkedAt})> _statusCache = {};

  /// Checks if match status between current user and profile owner in Firestore
  /// strictly satisfies: matchStatus == 'mutual_accepted' AND both parties approved the proposal.
  /// For all other states (browsing, pending, guest), returns false.
  static Future<bool> isMutualAcceptedWithApproval({
    required String currentUserId,
    required String targetProfileId,
    UserProfile? currentUser,
  }) async {
    // 1. Strict Guest Check: Guests can NEVER view house coordinates or navigation button
    final viewer = currentUser ?? MockData().currentUser;
    if (viewer == null ||
        GuestSecurityService.isGuest(viewer) ||
        currentUserId.isEmpty ||
        currentUserId == 'guest' ||
        targetProfileId.isEmpty ||
        currentUserId == targetProfileId) {
      return false;
    }

    final cacheKey = '${currentUserId}_$targetProfileId';
    final cached = _statusCache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.checkedAt).inSeconds < 15) {
      return cached.isMutual;
    }

    bool isMutualAccepted = false;

    // 2. Primary Source: Query Firestore `matches` collection
    try {
      final doc1 = await FirebaseFirestore.instance
          .collection('matches')
          .doc('${currentUserId}_$targetProfileId')
          .get(const GetOptions(source: Source.serverAndCache));

      if (doc1.exists && doc1.data() != null) {
        final data = doc1.data()!;
        final status = (data['matchStatus'] ?? data['status'] ?? '').toString().toLowerCase();
        final bool isAccepted = status == 'mutual_accepted';
        final bool bothApproved = data['both_approved'] == true ||
            (data['user1_approved'] == true && data['user2_approved'] == true) ||
            (data['sender_approved'] == true && data['receiver_approved'] == true) ||
            (isAccepted && data['approved'] != false);

        if (isAccepted && bothApproved) {
          isMutualAccepted = true;
        }
      }

      if (!isMutualAccepted) {
        final doc2 = await FirebaseFirestore.instance
            .collection('matches')
            .doc('${targetProfileId}_$currentUserId')
            .get(const GetOptions(source: Source.serverAndCache));

        if (doc2.exists && doc2.data() != null) {
          final data = doc2.data()!;
          final status = (data['matchStatus'] ?? data['status'] ?? '').toString().toLowerCase();
          final bool isAccepted = status == 'mutual_accepted';
          final bool bothApproved = data['both_approved'] == true ||
              (data['user1_approved'] == true && data['user2_approved'] == true) ||
              (data['sender_approved'] == true && data['receiver_approved'] == true) ||
              (isAccepted && data['approved'] != false);

          if (isAccepted && bothApproved) {
            isMutualAccepted = true;
          }
        }
      }

      // Check Firestore `proposals` collection
      if (!isMutualAccepted) {
        final pDoc = await FirebaseFirestore.instance
            .collection('proposals')
            .doc('${currentUserId}_$targetProfileId')
            .get(const GetOptions(source: Source.serverAndCache));

        if (pDoc.exists && pDoc.data() != null) {
          final data = pDoc.data()!;
          final status = (data['matchStatus'] ?? data['status'] ?? '').toString().toLowerCase();
          if (status == 'mutual_accepted' && (data['both_approved'] == true || data['matchStatus'] == 'mutual_accepted')) {
            isMutualAccepted = true;
          }
        }
      }

      if (!isMutualAccepted) {
        final pDoc2 = await FirebaseFirestore.instance
            .collection('proposals')
            .doc('${targetProfileId}_$currentUserId')
            .get(const GetOptions(source: Source.serverAndCache));

        if (pDoc2.exists && pDoc2.data() != null) {
          final data = pDoc2.data()!;
          final status = (data['matchStatus'] ?? data['status'] ?? '').toString().toLowerCase();
          if (status == 'mutual_accepted' && (data['both_approved'] == true || data['matchStatus'] == 'mutual_accepted')) {
            isMutualAccepted = true;
          }
        }
      }
    } catch (e) {
      debugPrint('[Security] Firestore match status query notice: $e');
    }

    // 3. Fallback & Cross-Verification with Local Agreed Matches & Supabase
    if (!isMutualAccepted) {
      if (viewer.agreedMutualMatches.contains(targetProfileId)) {
        isMutualAccepted = true;
      }
    }

    if (!isMutualAccepted) {
      try {
        final res = await Supabase.instance.client.rpc(
          'get_interest_relationship_status',
          params: {'target_user_id': targetProfileId},
        );
        if (res?.toString().toUpperCase() == 'MUTUAL') {
          isMutualAccepted = true;
          // Sync to Firestore to ensure Firestore consistency
          await recordMutualAcceptedInFirestore(
            currentUserId: currentUserId,
            targetProfileId: targetProfileId,
          );
        }
      } catch (_) {}
    }

    _statusCache[cacheKey] = (isMutual: isMutualAccepted, checkedAt: DateTime.now());
    return isMutualAccepted;
  }

  /// Records mutual accepted match status in Firestore so both parties' devices recognize it
  static Future<void> recordMutualAcceptedInFirestore({
    required String currentUserId,
    required String targetProfileId,
  }) async {
    try {
      final docId = '${currentUserId}_$targetProfileId';
      final payload = {
        'matchStatus': 'mutual_accepted',
        'status': 'mutual_accepted',
        'user1': currentUserId,
        'user2': targetProfileId,
        'users': [currentUserId, targetProfileId],
        'user1_approved': true,
        'user2_approved': true,
        'both_approved': true,
        'proposal_approved_at': DateTime.now().toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('matches')
          .doc(docId)
          .set(payload, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('proposals')
          .doc(docId)
          .set(payload, SetOptions(merge: true));

      _statusCache['${currentUserId}_$targetProfileId'] =
          (isMutual: true, checkedAt: DateTime.now());
      _statusCache['${targetProfileId}_$currentUserId'] =
          (isMutual: true, checkedAt: DateTime.now());

      debugPrint('[Security] Successfully recorded mutual_accepted in Firestore matches & proposals');
    } catch (e) {
      debugPrint('[Security] Error recording mutual_accepted in Firestore: $e');
    }
  }

  /// Resolves the candidate's exact home latitude and longitude
  static Future<({double lat, double lng})?> getHouseCoordinates({
    required UserProfile profile,
  }) async {
    // 1. Direct profile model coordinates
    if (profile.homeLat != null && profile.homeLng != null) {
      return (lat: profile.homeLat!, lng: profile.homeLng!);
    }

    // 2. Decode DIGIPIN if available
    if (profile.digipin != null && profile.digipin!.isNotEmpty) {
      final decoded = DigiPinService.decode(profile.digipin);
      if (decoded != null) {
        return decoded;
      }
    }

    // 3. Query Firestore user doc for exact coordinates
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(profile.id)
          .get(const GetOptions(source: Source.serverAndCache));
      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;
        final latVal = d['home_lat'] ?? d['homeLat'] ?? d['latitude'] ?? d['lat'];
        final lngVal = d['home_lng'] ?? d['homeLng'] ?? d['longitude'] ?? d['lng'];
        final double? lat = latVal != null ? double.tryParse(latVal.toString()) : null;
        final double? lng = lngVal != null ? double.tryParse(lngVal.toString()) : null;
        if (lat != null && lng != null) {
          return (lat: lat, lng: lng);
        }

        final digipinVal = d['digipin']?.toString();
        if (digipinVal != null && digipinVal.isNotEmpty) {
          final decoded = DigiPinService.decode(digipinVal);
          if (decoded != null) return decoded;
        }
      }
    } catch (e) {
      debugPrint('[Security] Error reading user house coordinates from Firestore: $e');
    }

    // 4. Wayanad regional coordinate resolution for Kurichiyar community candidates
    return _resolveRegionalCoordinates(profile.region);
  }

  static ({double lat, double lng})? _resolveRegionalCoordinates(String region) {
    final r = region.toLowerCase().trim();
    if (r.contains('kalpetta')) {
      return (lat: 11.6085, lng: 76.0856);
    } else if (r.contains('mananthavady') || r.contains('mananthavadi')) {
      return (lat: 11.8028, lng: 76.0028);
    } else if (r.contains('sulthan bathery') || r.contains('bathery')) {
      return (lat: 11.6622, lng: 76.2570);
    } else if (r.contains('vythiri')) {
      return (lat: 11.5518, lng: 76.0389);
    } else if (r.contains('panamaram')) {
      return (lat: 11.7456, lng: 76.0754);
    } else if (r.contains('meppadi')) {
      return (lat: 11.5500, lng: 76.1264);
    } else if (r.contains('pulpally')) {
      return (lat: 11.7925, lng: 76.2798);
    } else if (r.contains('ambalavayal')) {
      return (lat: 11.6212, lng: 76.2134);
    } else if (r.contains('thirunelly')) {
      return (lat: 11.9015, lng: 75.9922);
    } else if (r.contains('kannur')) {
      return (lat: 11.8745, lng: 75.3704);
    } else if (r.contains('kozhikode') || r.contains('calicut')) {
      return (lat: 11.2588, lng: 75.7804);
    } else if (region.isNotEmpty) {
      // Default to Wayanad center coordinates for Kurichiyar native territory
      return (lat: 11.6854, lng: 76.1320);
    }
    return (lat: 11.6854, lng: 76.1320);
  }

  /// Triggers URL launcher with exact Google Maps destination coordinates
  /// URL format: https://www.google.com/maps/dir/?api=1&destination=${homeLat},${homeLng}
  static Future<bool> launchNavigationToHouse({
    required double homeLat,
    required double homeLng,
  }) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$homeLat,$homeLng';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('[Security] Error launching Google Maps directions: $e');
      return false;
    }
  }
}
