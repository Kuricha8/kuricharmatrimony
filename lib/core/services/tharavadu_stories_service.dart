import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../models/status_category.dart';
import '../../features/clan_feed/tharavadu_list.dart';

/// Single Story Item within a Tharavadu story group.
class TharavaduStoryItem {
  final String id;
  final String authorId;
  final int clanId;
  final String clanName;
  final String? clanImageUrl;
  final String content;
  final String? mediaUrl;
  final bool isVideo;
  final DateTime createdAt;
  final StatusCategory? category;
  final String creatorName;

  const TharavaduStoryItem({
    required this.id,
    this.authorId = '',
    required this.clanId,
    required this.clanName,
    this.clanImageUrl,
    required this.content,
    this.mediaUrl,
    this.isVideo = false,
    required this.createdAt,
    this.category,
    this.creatorName = 'തറവാട് അംഗം',
  });

  bool get isExpired =>
      DateTime.now().difference(createdAt).inHours >= 24;

  Duration get timeRemaining {
    final expiry = createdAt.add(const Duration(hours: 24));
    final diff = expiry.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}

/// A group of stories belonging to a single Tharavadu.
class TharavaduStoryGroup {
  final int clanId;
  final Clan clan;
  final List<TharavaduStoryItem> stories;
  final bool hasUnviewed;

  const TharavaduStoryGroup({
    required this.clanId,
    required this.clan,
    required this.stories,
    required this.hasUnviewed,
  });
}

/// Service managing Tharavadu Stories with 24-hour expiry and viewed state tracking.
class TharavaduStoriesService extends ChangeNotifier {
  static final TharavaduStoriesService _instance =
      TharavaduStoriesService._internal();
  static TharavaduStoriesService get instance => _instance;

  TharavaduStoriesService._internal() {
    _loadViewedStories();
  }

  static const String _kViewedStoriesKey = 'viewed_tharavadu_story_ids';
  final Set<String> _viewedStoryIds = {};
  bool _isInitialized = false;

  Set<String> get viewedStoryIds => Set.unmodifiable(_viewedStoryIds);
  bool get isInitialized => _isInitialized;

  Future<void> _loadViewedStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kViewedStoriesKey);
      if (list != null) {
        _viewedStoryIds.addAll(list);
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading viewed story IDs: $e');
    }
  }

  bool isStoryViewed(String storyId) => _viewedStoryIds.contains(storyId);

  bool isGroupAllViewed(List<TharavaduStoryItem> stories) {
    if (stories.isEmpty) return true;
    return stories.every((s) => _viewedStoryIds.contains(s.id));
  }

  Future<void> markStoryViewed(String storyId) async {
    if (storyId.isEmpty || _viewedStoryIds.contains(storyId)) return;
    _viewedStoryIds.add(storyId);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kViewedStoriesKey, _viewedStoryIds.toList());
    } catch (e) {
      debugPrint('Error saving viewed story ID: $e');
    }
  }

  /// Fetches active stories created within the last 24 hours.
  DocumentSnapshot? _lastStoryDocument;
  DocumentSnapshot? get lastStoryDocument => _lastStoryDocument;

  /// Fetches active stories created strictly within the last 24 hours.
  /// Enforces query limit (default 15) and supports Firestore `startAfterDocument` pagination.
  Future<List<TharavaduStoryGroup>> fetchActiveStories({
    DocumentSnapshot? lastDocument,
    int limit = 15,
  }) async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final List<TharavaduStoryItem> fetchedItems = [];

    // 1. First try Firestore 'stories' collection with 24-hr cutoff and pagination
    try {
      Query firestoreQuery = FirebaseFirestore.instance
          .collection('stories')
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
          .orderBy('created_at', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        firestoreQuery = firestoreQuery.startAfterDocument(lastDocument);
      }

      final snap = await firestoreQuery.get(
        const GetOptions(source: Source.serverAndCache),
      );

      if (snap.docs.isNotEmpty) {
        _lastStoryDocument = snap.docs.last;
        for (final doc in snap.docs) {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          final id = doc.id;
          final clanId = (data['clan_id'] as int?) ?? 1;
          final clan = getClanById(clanId);
          final text = (data['text'] ?? data['content'] ?? data['caption'] ?? '')
              .toString();
          final mediaUrl = data['media_url'] as String?;
          final isVideo = data['is_video'] == true;
          final createdAt = data['created_at'] is Timestamp
              ? (data['created_at'] as Timestamp).toDate()
              : (DateTime.tryParse(data['created_at']?.toString() ?? '') ??
                  DateTime.now());
          final categoryRaw = data['category'] ?? data['post_type'];
          final cat = StatusCategory.fromString(categoryRaw?.toString()) ??
              StatusCategory.fromString(text);

          if (createdAt.isAfter(cutoff)) {
            final authorId = (data['author_id'] ??
                    data['creator_id'] ??
                    data['user_id'] ??
                    data['sender_id'] ??
                    '')
                .toString();
            fetchedItems.add(
              TharavaduStoryItem(
                id: id,
                authorId: authorId,
                clanId: clanId,
                clanName: clan?.displayName ?? 'തറവാട്',
                clanImageUrl: clan?.imageUrl,
                content: text,
                mediaUrl: mediaUrl,
                isVideo: isVideo,
                createdAt: createdAt,
                category: cat,
                creatorName: data['sender_name']?.toString() ?? 'അംഗം',
              ),
            );
          }
        }
      }
    } catch (fe) {
      debugPrint('Firestore active stories query notice: $fe');
    }

    // 2. Query Supabase tharavadu_posts strictly filtered >= 24h and limit 15
    if (fetchedItems.isEmpty) {
      try {
        final res = await Supabase.instance.client
            .from('tharavadu_posts')
            .select()
            .gte('created_at', cutoff.toUtc().toIso8601String())
            .order('created_at', ascending: true)
            .limit(limit);

          for (final row in res) {
            try {
              final id = row['id']?.toString() ?? '';
              final clanId = (row['clan_id'] as int?) ?? 1;
              final clan = getClanById(clanId);
              final text = (row['text'] ?? row['content'] ?? row['caption'] ?? '')
                  .toString();
              final mediaUrl = row['media_url'] as String?;
              final isVideo = row['is_video'] == true;
              final createdAt = DateTime.tryParse(row['created_at'].toString()) ??
                  DateTime.now();
              final categoryRaw = row['category'] ?? row['post_type'];

              // Extract category from text or column
              final cat = StatusCategory.fromString(categoryRaw?.toString()) ??
                  StatusCategory.fromString(text);

              if (createdAt.isAfter(cutoff)) {
                final authorId = (row['creator_id'] ??
                        row['user_id'] ??
                        row['author_id'] ??
                        '')
                    .toString();
                fetchedItems.add(
                  TharavaduStoryItem(
                    id: id,
                    authorId: authorId,
                    clanId: clanId,
                    clanName: clan?.displayName ?? 'തറവാട്',
                    clanImageUrl: clan?.imageUrl,
                    content: text,
                    mediaUrl: mediaUrl,
                    isVideo: isVideo,
                    createdAt: createdAt,
                    category: cat,
                    creatorName: row['sender_name']?.toString() ?? 'അംഗം',
                  ),
                );
              }
            } catch (_) {}
          }
        } catch (e) {
          debugPrint('Note: Supabase active stories query: $e');
        }
      }

    // If remote DB returned empty or offline, provide curated vibrant demo stories
    if (fetchedItems.isEmpty) {
      fetchedItems.addAll(_getSampleActiveStories());
    }

    // Group stories by clanId
    final Map<int, List<TharavaduStoryItem>> grouped = {};
    for (final item in fetchedItems) {
      grouped.putIfAbsent(item.clanId, () => []).add(item);
    }

    final List<TharavaduStoryGroup> groups = [];
    for (final entry in grouped.entries) {
      final clan = getClanById(entry.key) ??
          Clan(
            id: entry.key,
            name: entry.value.first.clanName,
            nameMl: entry.value.first.clanName,
            nameEn: 'Tharavadu ${entry.key}',
            type: 'pandi',
            location: 'Wayanad',
          );
      final hasUnviewed = !isGroupAllViewed(entry.value);
      groups.add(
        TharavaduStoryGroup(
          clanId: entry.key,
          clan: clan,
          stories: entry.value,
          hasUnviewed: hasUnviewed,
        ),
      );
    }

    // Sort so Tharavadus with unviewed stories appear first
    groups.sort((a, b) {
      if (a.hasUnviewed && !b.hasUnviewed) return -1;
      if (!a.hasUnviewed && b.hasUnviewed) return 1;
      return a.clan.displayName.compareTo(b.clan.displayName);
    });

    return groups;
  }

  /// Curated active stories strictly within the last 24 hours for instant demo & offline resilience
  List<TharavaduStoryItem> _getSampleActiveStories() {
    final now = DateTime.now();
    return [
      // Muthanga Tharavadu (Wedding Celebration)
      TharavaduStoryItem(
        id: 'story_sample_1',
        clanId: 1,
        clanName: 'മുത്തങ്ങ തറവാട്',
        clanImageUrl:
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
        content:
            'നമ്മുടെ തറവാട്ടിലെ സുരേഷിന്റെയും അഞ്ജലിയുടെയും വിവാഹ നിശ്ചയം മംഗളകരമായി പൂർത്തിയായി! ഏവർക്കും ഹൃദയം നിറഞ്ഞ നന്ദി. 🎉❤️',
        mediaUrl:
            'https://images.unsplash.com/photo-1519741497674-611481863552?w=800',
        createdAt: now.subtract(const Duration(hours: 2)),
        category: StatusCategory.wedding,
        creatorName: 'രാഘവൻ മൂപ്പൻ',
      ),
      TharavaduStoryItem(
        id: 'story_sample_2',
        clanId: 1,
        clanName: 'മുത്തങ്ങ തറവാട്',
        clanImageUrl:
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
        content:
            'വിവാഹ സദ്യ ഒരുക്കങ്ങൾ തറവാട്ടു മുറ്റത്ത് ആരംഭിച്ചു. എല്ലാവരുടെയും സാന്നിധ്യം പ്രതീക്ഷിക്കുന്നു.',
        mediaUrl:
            'https://images.unsplash.com/photo-1555244162-803834f70033?w=800',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 20)),
        category: StatusCategory.celebration,
        creatorName: 'സുരേഷ് കുമാർ',
      ),

      // Padinjarathara Tharavadu (Annual Festival & Notice)
      TharavaduStoryItem(
        id: 'story_sample_3',
        clanId: 2,
        clanName: 'പടിഞ്ഞാറത്തറ തറവാട്',
        clanImageUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
        content:
            'തറവാട്ടു ക്ഷേത്രത്തിലെ വാർഷിക പൂജയും ഒത്തുചേരലും അടുത്ത ഞായറാഴ്ച രാവിലെ 10 മണിക്ക് നടക്കും. പ്രധാന അറിയിപ്പ്!',
        mediaUrl:
            'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=800',
        createdAt: now.subtract(const Duration(hours: 4)),
        category: StatusCategory.notice,
        creatorName: 'കേളപ്പൻ കാരണവർ',
      ),

      // Kaniyambetta Tharavadu (Celebration)
      TharavaduStoryItem(
        id: 'story_sample_4',
        clanId: 3,
        clanName: 'കണിയാമ്പറ്റ തറവാട്',
        clanImageUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        content:
            'നമ്മുടെ തറവാട്ടിലെ വിദ്യാർത്ഥികൾക്ക് ഉപരിപഠന സ്കോളർഷിപ്പ് വിതരണം ചെയ്തു. അനുമോദനങ്ങൾ! 🎓✨',
        mediaUrl:
            'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=800',
        createdAt: now.subtract(const Duration(hours: 6)),
        category: StatusCategory.celebration,
        creatorName: 'സുധാകരൻ പി.',
      ),

      // Pozhuthana Tharavadu (Obituary notice)
      TharavaduStoryItem(
        id: 'story_sample_5',
        clanId: 4,
        clanName: 'പൊഴുതന തറവാട്',
        clanImageUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
        content:
            'നമ്മുടെ പ്രിയങ്കരനായ മൂത്ത കാരണവർ ശ്രീ. ചാത്തൻ കുറുപ്പ് (86) നിര്യാതനായി. അഗാധമായ അനുശോചനം രേഖപ്പെടുത്തുന്നു. ആദരാഞ്ജലികൾ.',
        mediaUrl:
            'https://images.unsplash.com/photo-1518241353330-0f7941c2d9b5?w=800',
        createdAt: now.subtract(const Duration(hours: 9)),
        category: StatusCategory.obituary,
        creatorName: 'തറവാട് സമിതി',
      ),

      // Meppadi Tharavadu (Wedding Announcement)
      TharavaduStoryItem(
        id: 'story_sample_6',
        clanId: 5,
        clanName: 'മേപ്പാടി ശാഖ തറവാട്',
        clanImageUrl:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
        content:
            'വിവാഹ ക്ഷണക്കത്ത്: മകൻ വിഷ്ണുവിന്റെയും ശ്രുതിയുടെയും വിവാഹത്തിന് എല്ലാവരുടെയും അനുഗ്രഹം പ്രാർത്ഥിക്കുന്നു.',
        mediaUrl:
            'https://images.unsplash.com/photo-1583939003579-730e3918a45a?w=800',
        createdAt: now.subtract(const Duration(hours: 12)),
        category: StatusCategory.wedding,
        creatorName: 'വിഷ്ണു & കുടുംബം',
      ),
    ];
  }
}
