import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/models.dart';
import '../../core/services/clan_matching_engine.dart';

// ─── Single Unified Consumption Point ─────────────────────────────────────────

/// Top-level getter pointing strictly to the single source of truth in TharavaduService
List<Clan> get allClans => TharavaduService.allClans;

// ─── Utility functions ─────────────────────────────────────────────────────────

/// Look up a clan by its integer ID. Returns null if not found.
Clan? getClanById(int id) {
  try {
    return TharavaduService.allClans.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}

/// Look up a clan by its authoritative name or English name (case-insensitive). Returns null if not found.
Clan? getClanByName(String name) {
  final clean = name.toLowerCase().trim();
  if (clean.isEmpty) return null;
  try {
    return TharavaduService.allClans.firstWhere(
      (c) =>
          c.name.toLowerCase().trim() == clean ||
          c.nameMl.toLowerCase().trim() == clean ||
          c.nameEn.toLowerCase().trim() == clean ||
          c.displayName.toLowerCase().trim() == clean ||
          c.displayLabel.toLowerCase().trim() == clean ||
          c.displayLabelEn.toLowerCase().trim() == clean ||
          ((clean == 'പെരിഞ്ചോല' || clean == 'perinjola') &&
              (c.id == 57 || c.name.contains('പെരിഞ്ചോല'))),
    );
  } catch (_) {
    try {
      return TharavaduService.allClans.firstWhere(
        (c) =>
            c.name.toLowerCase().contains(clean) ||
            c.nameMl.toLowerCase().contains(clean) ||
            c.nameEn.toLowerCase().contains(clean) ||
            c.displayName.toLowerCase().contains(clean) ||
            clean.contains(c.name.toLowerCase().trim()) ||
            clean.contains(c.nameMl.toLowerCase().trim()),
      );
    } catch (_) {
      return null;
    }
  }
}

bool calculateIsOutOfCaste(int fatherClanId, int motherClanId) {
  final father = getClanById(fatherClanId);
  final mother = getClanById(motherClanId);
  if (father == null || mother == null) return false;
  return false;
}

bool isMoietyCompatible(UserProfile a, UserProfile b) {
  return ClanMatchingEngine.instance.areProfilesCompatible(a, b);
}

// ─── TharavaduService ──────────────────────────────────────────────────────────
// STRICTLY REALTIME LIVE SINGLE SOURCE OF TRUTH (Listens directly to database updates)

class TharavaduService extends ChangeNotifier {
  TharavaduService._() {
    subscribeToUpdates();
  }

  static final TharavaduService _instance = TharavaduService._();
  static TharavaduService get instance => _instance;

  /// Default Baseline Bandhu Clans (Empty baseline, 100% database driven)
  static List<Clan> get defaultBandhuList => [];

  /// Default Baseline Pandi Clans (Empty baseline, 100% database driven)
  static List<Clan> get defaultPandiList => [];

  /// The live in-memory single sources of truth (from live database stream)
  static List<Clan> bandhuClans = [];
  static List<Clan> pandiClans = [];

  /// Unified single-point consumption
  static List<Clan> get allClans => [...bandhuClans, ...pandiClans];

  final StreamController<List<Clan>> _clansStreamController =
      StreamController<List<Clan>>.broadcast();

  /// Reactive stream for direct StreamBuilder consumption
  Stream<List<Clan>> get liveClansStream => _clansStreamController.stream;

  StreamSubscription<QuerySnapshot>? _firestoreSub;
  StreamSubscription<List<Map<String, dynamic>>>? _supabaseSub;

  List<Map<String, dynamic>> get bandhuGroups => bandhuClans
      .map(
        (c) => {
          'id': c.id,
          'name': c.name,
          'name_ml': c.nameMl,
          'type': 'bandhu',
          'location': c.location,
        },
      )
      .toList();

  /// Reset to baseline lists
  void resetToDefaults() {
    bandhuClans = [];
    pandiClans = [];
    notifyListeners();
    _clansStreamController.add([]);
  }

  /// Backward compatible stub: dropdown listens directly to live database streams
  Future<void> loadCachedClans() async {
    subscribeToUpdates();
  }

  /// Subscribe to live database streams (Firestore tharavadus & Supabase clans)
  void subscribeToUpdates() {
    _startFirestoreStream();
    _startSupabaseStream();
  }

  void _startFirestoreStream() {
    if (_firestoreSub != null) return;
    try {
      _firestoreSub = FirebaseFirestore.instance
          .collection('tharavadus')
          .snapshots()
          .listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final List<Clan> fetched = [];
            for (int i = 0; i < snapshot.docs.length; i++) {
              final doc = snapshot.docs[i];
              final data = doc.data();
              final parsedId = data['id'] is int
                  ? data['id'] as int
                  : (int.tryParse(data['id']?.toString() ?? '') ??
                      (int.tryParse(doc.id) ?? (i + 1)));
              data['id'] = parsedId;
              final clan = Clan.fromMap(data);
              if (clan.isActive) {
                fetched.add(clan);
              }
            }
            if (fetched.isNotEmpty) {
              _updateInMemoryClans(fetched);
              notifyListeners();
              _clansStreamController.add(allClans);
              debugPrint(
                'TharavaduService: Realtime update from Firestore (${bandhuClans.length} Bandhu, ${pandiClans.length} Pandi)',
              );
            }
          }
        },
        onError: (e) {
          debugPrint('TharavaduService Firestore stream note: $e');
        },
      );
    } catch (e) {
      debugPrint('TharavaduService: Firestore stream attachment error: $e');
    }
  }

  void _startSupabaseStream() {
    if (_supabaseSub != null) return;
    try {
      _supabaseSub = Supabase.instance.client
          .from('clans')
          .stream(primaryKey: ['id'])
          .listen(
        (data) {
          if (data.isNotEmpty) {
            final List<Clan> fetched = [];
            for (int i = 0; i < data.length; i++) {
              final row = Map<String, dynamic>.from(data[i]);
              final clan = Clan.fromMap(row);
              if (clan.isActive) {
                fetched.add(clan);
              }
            }
            if (fetched.isNotEmpty) {
              _updateInMemoryClans(fetched);
              notifyListeners();
              _clansStreamController.add(allClans);
              debugPrint(
                'TharavaduService: Realtime update from Supabase (${bandhuClans.length} Bandhu, ${pandiClans.length} Pandi)',
              );
            }
          }
        },
        onError: (e) {
          debugPrint('TharavaduService Supabase stream note: $e');
        },
      );
    } catch (e) {
      debugPrint('TharavaduService: Supabase stream init note: $e');
    }
  }

  /// Sync clan list from live database without session blocking or version skipping
  Future<void> syncClans({
    dynamic client,
    int maxRetries = 2,
    Duration retryDelay = const Duration(seconds: 1),
    bool forceRefresh = false,
  }) async {
    subscribeToUpdates();

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('tharavadus')
            .get(const GetOptions(source: Source.serverAndCache));

        if (snapshot.docs.isEmpty) {
          final altSnap = await FirebaseFirestore.instance
              .collection('tharavads')
              .get(const GetOptions(source: Source.serverAndCache));
          if (altSnap.docs.isNotEmpty) {
            snapshot = altSnap;
          } else {
            final masterSnap = await FirebaseFirestore.instance
                .collection('tharavadu_master')
                .get(const GetOptions(source: Source.serverAndCache));
            if (masterSnap.docs.isNotEmpty) {
              snapshot = masterSnap;
            }
          }
        }

        final List<Clan> fetched = [];
        for (int i = 0; i < snapshot.docs.length; i++) {
          final doc = snapshot.docs[i];
          final data = doc.data() as Map<String, dynamic>;
          final parsedId = data['id'] is int
              ? data['id'] as int
              : (int.tryParse(data['id']?.toString() ?? '') ??
                  (int.tryParse(doc.id) ?? (i + 1)));
          data['id'] = parsedId;
          final clan = Clan.fromMap(data);
          if (clan.isActive) {
            fetched.add(clan);
          }
        }

        if (fetched.isNotEmpty) {
          _updateInMemoryClans(fetched);
          notifyListeners();
          _clansStreamController.add(allClans);
          debugPrint(
            'TharavaduService: synced ${bandhuClans.length} Bandhu & ${pandiClans.length} Pandi active clans from Firestore',
          );
          return;
        }

        // Fallback to Supabase table clans
        try {
          final res = await Supabase.instance.client
              .from('clans')
              .select('*')
              .eq('is_active', true);
          if (res.isNotEmpty) {
            final List<Clan> supaFetched = res
                .map((r) => Clan.fromMap(Map<String, dynamic>.from(r)))
                .where((c) => c.isActive)
                .toList();
            if (supaFetched.isNotEmpty) {
              _updateInMemoryClans(supaFetched);
              notifyListeners();
              _clansStreamController.add(allClans);
              return;
            }
          }
        } catch (_) {}

        return;
      } catch (e) {
        debugPrint(
          'TharavaduService sync attempt $attempt/$maxRetries error: $e',
        );
        if (attempt < maxRetries) {
          await Future.delayed(retryDelay);
        }
      }
    }
  }

  void _updateInMemoryClans(List<Clan> fetched) {
    final activeFetched = fetched.where((c) => c.isActive).toList();

    final Map<int, Clan> bandhuMap = {};
    final Map<int, Clan> pandiMap = {};

    for (int i = 0; i < activeFetched.length; i++) {
      final clan = activeFetched[i];
      final id = clan.id > 0 ? clan.id : (i + 1);
      final resolved = clan.id > 0
          ? clan
          : clan.copyWith(id: id);

      final isBandhu = resolved.type.toLowerCase() == 'bandhu' ||
          resolved.groupName.contains('ബന്ധു') ||
          resolved.clanGroup.contains('ബന്ധു');
      if (isBandhu) {
        bandhuMap[id] = resolved;
      } else {
        pandiMap[id] = resolved;
      }
    }

    bandhuClans = bandhuMap.values.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    pandiClans = pandiMap.values.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  /// Add or update clan in local state and emit notifyListeners() for instant UI response
  void addOrUpdateClanLocally(Clan clan) {
    final isBandhu =
        clan.type.toLowerCase() == 'bandhu' ||
        clan.groupName.contains('ബന്ധു') ||
        clan.clanGroup.contains('ബന്ധു');

    if (isBandhu) {
      final idx = bandhuClans.indexWhere(
        (c) =>
            c.id == clan.id ||
            c.name.toLowerCase().trim() == clan.name.toLowerCase().trim(),
      );
      if (idx != -1) {
        bandhuClans[idx] = clan;
      } else {
        bandhuClans.add(clan);
      }
      pandiClans.removeWhere((c) => c.id == clan.id);
      bandhuClans.sort((a, b) => a.displayName.compareTo(b.displayName));
    } else {
      final idx = pandiClans.indexWhere(
        (c) =>
            c.id == clan.id ||
            c.name.toLowerCase().trim() == clan.name.toLowerCase().trim(),
      );
      if (idx != -1) {
        pandiClans[idx] = clan;
      } else {
        pandiClans.add(clan);
      }
      bandhuClans.removeWhere((c) => c.id == clan.id);
      pandiClans.sort((a, b) => a.displayName.compareTo(b.displayName));
    }

    notifyListeners();
    _clansStreamController.add(allClans);
  }

  /// Remove a clan locally
  void removeClanLocally(int clanId) {
    bandhuClans.removeWhere((c) => c.id == clanId);
    pandiClans.removeWhere((c) => c.id == clanId);
    notifyListeners();
    _clansStreamController.add(allClans);
  }

  /// Admin: Directly add a clan to live database (Firestore & Supabase)
  Future<Clan> addClan(Clan clan) async {
    addOrUpdateClanLocally(clan);

    final isBandhu =
        clan.type.toLowerCase() == 'bandhu' ||
        clan.groupName.contains('ബന്ധു') ||
        clan.clanGroup.contains('ബന്ധു');
    final gothramVal = isBandhu ? 'BANDHU' : 'PANTHI';
    final nameVal = clan.name;

    final payload = {
      if (clan.id > 0) 'id': clan.id,
      'name': nameVal,
      if (clan.nameMl.isNotEmpty) 'name_ml': clan.nameMl,
      if (clan.nameEn.isNotEmpty) 'name_en': clan.nameEn,
      if (clan.subName.isNotEmpty) 'sub_name': clan.subName,
      if (clan.subName.isNotEmpty) 'subName': clan.subName,
      'gothram': gothramVal,
      'clanGroup': isBandhu ? 'ബന്ധു' : 'പന്തി',
      'type': isBandhu ? 'bandhu' : 'pandi',
      'group_name': isBandhu ? 'ബന്ധു ഗ്രൂപ്പ്' : 'പന്തി ഗ്രൂപ്പ്',
      'description':
          clan.description ??
          '${gothramVal == 'BANDHU' ? 'Bandhu' : 'Panthi'} Tharavadu - $nameVal',
      'is_active': true,
      'updated_at': FieldValue.serverTimestamp(),
    };

    try {
      final batch = FirebaseFirestore.instance.batch();
      final newDocRef = FirebaseFirestore.instance.collection('tharavadus').doc();
      batch.set(newDocRef, payload);

      final versionRef = FirebaseFirestore.instance.collection('app_config').doc('tharavadu_version');
      batch.set(versionRef, {
        'version': FieldValue.increment(1),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      debugPrint('Admin addClan Firestore error: $e');
    }

    try {
      await Supabase.instance.client.from('clans').upsert({
        if (clan.id > 0) 'id': clan.id,
        'name_ml': clan.nameMl.isNotEmpty ? clan.nameMl : nameVal,
        'name_en': clan.nameEn,
        'name': nameVal,
        'type': isBandhu ? 'bandhu' : 'pandi',
        'group_name': isBandhu ? 'ബന്ധു ഗ്രൂപ്പ്' : 'പന്തി ഗ്രൂപ്പ്',
        'is_active': true,
      });
    } catch (e) {
      debugPrint('Admin addClan Supabase note: $e');
    }

    return clan;
  }

  /// Admin: Directly update a clan in live database (Firestore & Supabase)
  Future<Clan> updateClan(Clan clan) async {
    addOrUpdateClanLocally(clan);

    final isBandhu =
        clan.type.toLowerCase() == 'bandhu' ||
        clan.groupName.contains('ബന്ധു') ||
        clan.clanGroup.contains('ബന്ധു');
    final gothramVal = isBandhu ? 'BANDHU' : 'PANTHI';
    final nameVal = clan.name;

    final payload = {
      'name': nameVal,
      if (clan.nameMl.isNotEmpty) 'name_ml': clan.nameMl,
      if (clan.nameEn.isNotEmpty) 'name_en': clan.nameEn,
      'gothram': gothramVal,
      'clanGroup': isBandhu ? 'ബന്ധു' : 'പന്തി',
      'type': isBandhu ? 'bandhu' : 'pandi',
      if (clan.description != null) 'description': clan.description,
      'updated_at': FieldValue.serverTimestamp(),
    };

    try {
      final snap = await FirebaseFirestore.instance
          .collection('tharavadus')
          .where('id', isEqualTo: clan.id)
          .limit(1)
          .get(const GetOptions(source: Source.serverAndCache));

      final batch = FirebaseFirestore.instance.batch();
      if (snap.docs.isNotEmpty) {
        batch.update(snap.docs.first.reference, payload);
      } else {
        final newDoc = FirebaseFirestore.instance.collection('tharavadus').doc();
        batch.set(newDoc, {...payload, 'id': clan.id});
      }

      final versionRef = FirebaseFirestore.instance.collection('app_config').doc('tharavadu_version');
      batch.set(versionRef, {
        'version': FieldValue.increment(1),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      debugPrint('Admin updateClan Firestore error: $e');
    }

    try {
      await Supabase.instance.client.from('clans').update({
        'name_ml': clan.nameMl.isNotEmpty ? clan.nameMl : nameVal,
        if (clan.nameEn.isNotEmpty) 'name_en': clan.nameEn,
        'name': nameVal,
        'type': isBandhu ? 'bandhu' : 'pandi',
      }).eq('id', clan.id);
    } catch (e) {
      debugPrint('Admin updateClan Supabase note: $e');
    }

    return clan;
  }

  /// Admin: Directly delete a clan in live database (Firestore & Supabase)
  Future<void> deleteClan(int clanId, {bool hardDelete = true}) async {
    removeClanLocally(clanId);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tharavadus')
          .where('id', isEqualTo: clanId)
          .limit(1)
          .get(const GetOptions(source: Source.serverAndCache));

      final batch = FirebaseFirestore.instance.batch();
      if (snapshot.docs.isNotEmpty) {
        if (hardDelete) {
          batch.delete(snapshot.docs.first.reference);
        } else {
          batch.update(snapshot.docs.first.reference, {
            'is_active': false,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }

      final versionRef = FirebaseFirestore.instance.collection('app_config').doc('tharavadu_version');
      batch.set(versionRef, {
        'version': FieldValue.increment(1),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      debugPrint('Admin deleteClan Firestore error: $e');
    }

    try {
      if (hardDelete) {
        await Supabase.instance.client.from('clans').delete().eq('id', clanId);
      } else {
        await Supabase.instance.client.from('clans').update({'is_active': false}).eq('id', clanId);
      }
    } catch (e) {
      debugPrint('Admin deleteClan Supabase note: $e');
    }
  }

  @override
  void dispose() {
    _firestoreSub?.cancel();
    _supabaseSub?.cancel();
    _clansStreamController.close();
    super.dispose();
  }

  /// Fetch all active display labels in Malayalam or English.
  Future<List<String>> fetchDisplayLabels() async {
    return allClans
        .where((c) => c.isActive)
        .map((c) => c.displayName)
        .toList();
  }
}
