import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TharavaduHouse {
  final String id;
  final int clanId;
  final String houseName;
  final String place;
  final bool isApproved;

  TharavaduHouse({
    required this.id,
    required this.clanId,
    required this.houseName,
    required this.place,
    this.isApproved = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'clan_id': clanId,
    'house_name': houseName,
    'place': place,
    'is_approved': isApproved,
  };

  factory TharavaduHouse.fromMap(Map<String, dynamic> map) => TharavaduHouse(
    id: map['id']?.toString() ?? '',
    clanId: map['clan_id'] as int,
    houseName: map['house_name']?.toString() ?? '',
    place: map['place']?.toString() ?? '',
    isApproved: map['is_approved'] as bool? ?? true,
  );
}

class TharavaduHousesService extends ChangeNotifier {
  TharavaduHousesService._();
  static final TharavaduHousesService instance = TharavaduHousesService._();

  final _supabase = Supabase.instance.client;
  final Map<int, List<TharavaduHouse>> _localCache = {};
  bool _isInitialized = false;

  /// Seed defaults for Wayanad-based Kurichiyar tharavadu clans so the app is populated
  void _seedDefaultHouses() {
    final regions = [
      'Mananthavady',
      'Kalpetta',
      'Sulthan Bathery',
      'Meenangadi',
      'Vellarikundu',
      'Thariode',
      'Panamaram',
      'Kaniyambetta',
      'Pozhuthana',
      'Vythiri',
      'Ambalavayal',
      'Muttil',
    ];

    // Seed house names and places for clans 1 to 60
    for (int id = 1; id <= 60; id++) {
      final suffix1 = id % 2 == 0 ? 'House' : 'Illam';
      final suffix2 = id % 3 == 0 ? 'Mansion' : 'Nivas';
      final suffix3 = 'Tharavadu';

      _localCache[id] = [
        TharavaduHouse(
          id: 'local-$id-1',
          clanId: id,
          houseName: 'Kudumba-$id $suffix1',
          place: regions[id % regions.length],
        ),
        TharavaduHouse(
          id: 'local-$id-2',
          clanId: id,
          houseName: 'Mooladhara-$id $suffix2',
          place: regions[(id + 3) % regions.length],
        ),
        TharavaduHouse(
          id: 'local-$id-3',
          clanId: id,
          houseName: 'Tharavadu-$id $suffix3',
          place: regions[(id + 7) % regions.length],
        ),
      ];
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _seedDefaultHouses();
    await _loadUserAddedHouses();
    _isInitialized = true;
  }

  Future<List<TharavaduHouse>> fetchHousesForClan(int clanId) async {
    await initialize();
    try {
      final res = await _supabase
          .from('tharavadu_houses')
          .select()
          .eq('clan_id', clanId)
          .eq('is_approved', true);

      final dbHouses = (res as List)
          .map((x) => TharavaduHouse.fromMap(x as Map<String, dynamic>))
          .toList();
      if (dbHouses.isNotEmpty) {
        // Merge with local user added ones
        final localAdded = _localCache[clanId]!
            .where((h) => h.id.startsWith('user-'))
            .toList();
        return [...dbHouses, ...localAdded];
      }
    } catch (e) {
      debugPrint(
        'TharavaduHousesService: Falling back to local storage list ($e)',
      );
    }

    return _localCache[clanId] ?? [];
  }

  Future<void> addHouse(int clanId, String houseName, String place) async {
    final newHouse = TharavaduHouse(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      clanId: clanId,
      houseName: houseName,
      place: place,
      isApproved: true,
    );

    // 1. Try DB insert
    try {
      await _supabase.from('tharavadu_houses').insert({
        'clan_id': clanId,
        'house_name': houseName,
        'place': place,
        'is_approved': true,
      });
      debugPrint('TharavaduHousesService: Inserted house in Supabase');
    } catch (e) {
      debugPrint(
        'TharavaduHousesService: DB Insert failed, keeping locally ($e)',
      );
    }

    // 2. Update local state
    if (!_localCache.containsKey(clanId)) {
      _localCache[clanId] = [];
    }
    _localCache[clanId]!.insert(0, newHouse);
    await _saveUserAddedHouses();
    notifyListeners();
  }

  Future<void> _saveUserAddedHouses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allUserAdded = <Map<String, dynamic>>[];
      for (var list in _localCache.values) {
        for (var h in list) {
          if (h.id.startsWith('user-')) {
            allUserAdded.add(h.toMap());
          }
        }
      }
      await prefs.setString(
        'user_added_tharavadu_houses',
        jsonEncode(allUserAdded),
      );
    } catch (e) {
      debugPrint('TharavaduHousesService: Save cache error: $e');
    }
  }

  Future<void> _loadUserAddedHouses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString('user_added_tharavadu_houses');
      if (dataStr != null) {
        final List<dynamic> list = jsonDecode(dataStr) as List<dynamic>;
        for (var item in list) {
          final h = TharavaduHouse.fromMap(item as Map<String, dynamic>);
          if (!_localCache.containsKey(h.clanId)) {
            _localCache[h.clanId] = [];
          }
          _localCache[h.clanId]!.insert(0, h);
        }
      }
    } catch (e) {
      debugPrint('TharavaduHousesService: Load cache error: $e');
    }
  }
}
