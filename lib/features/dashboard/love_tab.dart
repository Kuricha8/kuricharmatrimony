import 'package:flutter/material.dart';
import '../../core/utils/mock_data.dart';
import '../clan_feed/tharavadu_list.dart';
import '../matching/match_success_sheet.dart';

class LoveTab extends StatelessWidget {
  const LoveTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MockData(),
      builder: (context, child) {
        final mockData = MockData();
        final me = mockData.currentUser;

        if (me == null) {
          return const Center(
            child: Text(
              'ദയവായി ആദ്യം രജിസ്റ്റർ ചെയ്യുക.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        }

        final favorites = mockData.profiles
            .where((p) => me.favoriteProfileIds.contains(p.id))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ഷോർട്ട്‌ലിസ്റ്റ് ചെയ്ത പ്രൊഫൈലുകൾ (${favorites.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF5C3E00),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: favorites.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'ഷോർട്ട്‌ലിസ്റ്റ് ശൂന്യമാണ്.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'പ്രൊഫൈലുകളിൽ ഹൃദയ ഐക്കൺ ടാപ്പ് ചെയ്ത് ഇവിടെ സേവ് ചെയ്യുക.',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final profile = favorites[index];
                        final fatherClan = getClanById(profile.fatherClanId);
                        final motherClan = getClanById(profile.motherClanId);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: const Color(
                                        0xFF1B8C4E,
                                      ).withValues(alpha: 0.15),
                                      child: const Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Color(0xFF1B8C4E),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${profile.name}, ${profile.age} വയസ്സ്',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'পিതാവ്: ${fatherClan?.type ?? "PANDI"} (${fatherClan?.name ?? profile.fatherTharavadu ?? "—"})\nമാതാവ്: ${motherClan?.type ?? "BANDHU"} (${motherClan?.name ?? profile.motherTharavadu ?? "—"})',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          if (profile.region.isNotEmpty)
                                            Text(
                                              'പ്രദേശം: ${profile.region}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Remove from shortlist
                                    IconButton(
                                      icon: const Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        mockData.toggleFavorite(profile.id);
                                      },
                                      tooltip:
                                          'ഷോർട്ട്‌ലിസ്റ്റിൽ നിന്ന് നീക്കം ചെയ്യുക',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Match Success CTA — triggers audio sheet
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        showMatchSuccessSheet(context, profile),
                                    icon: const Icon(
                                      Icons.celebration,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'പൊരുത്തം ആഘോഷിക്കുക!',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B8C4E),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
