import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import '../../core/widgets/animated_gradient_avatar_ring.dart';
import 'tharavadu_list.dart';
import 'tharavadu_details_page.dart';

class ClanFeedStories extends StatelessWidget {
  final UserProfile currentUser;
  final MockData mockData;

  const ClanFeedStories({
    super.key,
    required this.currentUser,
    required this.mockData,
  });

  bool _isUserOwnClan(Clan clan, UserProfile user) {
    if (user.id == 'guest' || user.id.isEmpty) return false;

    final targetId = clan.id;
    final targetIdStr = targetId.toString();

    // 1. Direct ID comparison strictly matching Mother's Clan ID / Mother's Illam ID
    if (targetId != 0) {
      if ((user.motherClanId > 0 && user.motherClanId == targetId) ||
          (user.motherIllamId != null && user.motherIllamId == targetId) ||
          (user.motherClanId.toString() == targetIdStr)) {
        return true;
      }
      // If user.tharavaduId matches targetId and is not father's clan
      if (user.tharavaduId > 0 &&
          user.tharavaduId == targetId &&
          user.fatherClanId != targetId) {
        return true;
      }
    }

    // 2. Direct string match strictly on Mother's Tharavadu names
    final cName = clan.name.trim().toLowerCase();
    final cNameMl = clan.nameMl.trim().toLowerCase();
    final cNameEn = clan.nameEn.trim().toLowerCase();

    final motherNames = [
      (user.motherTharavadu ?? '').trim().toLowerCase(),
      (user.motherTharavadName ?? '').trim().toLowerCase(),
      (user.mothersTarawad ?? '').trim().toLowerCase(),
    ].where((s) => s.isNotEmpty).toList();

    for (final mN in motherNames) {
      for (final cN in [cName, cNameMl, cNameEn]) {
        if (cN.isEmpty) continue;
        if (mN == cN || mN.contains(cN) || cN.contains(mN)) {
          return true;
        }
      }
    }

    // 3. Normalized Text comparison on Mother's Tharavadu
    String normalize(String? str) {
      if (str == null) return '';
      return str
          .toLowerCase()
          .replaceAll(RegExp(r'[\(\)\[\]\{\}\-\_\,\.\:\;\/\\\|]'), ' ')
          .replaceAll('panthi', '')
          .replaceAll('bandhu', '')
          .replaceAll('പന്തി', '')
          .replaceAll('ബന്ധു', '')
          .replaceAll('തറവാട്', '')
          .replaceAll('tharavadu', '')
          .replaceAll('tharavad', '')
          .replaceAll('ഗ്രൂപ്പ്', '')
          .replaceAll('group', '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    final cNames = [
      normalize(clan.name),
      normalize(clan.nameEn),
      normalize(clan.nameMl),
    ].where((s) => s.isNotEmpty).toList();

    for (final mN in motherNames) {
      final normMN = normalize(mN);
      if (normMN.isEmpty) continue;
      for (final cN in cNames) {
        if (normMN == cN || normMN.contains(cN) || cN.contains(normMN)) {
          return true;
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Get list of active clans sorted alphabetically
    final activeClans = allClans.where((c) => c.isActive).toList();
    activeClans.sort(
      (a, b) => (a.nameMl.isNotEmpty ? a.nameMl : a.name).compareTo(
        b.nameMl.isNotEmpty ? b.nameMl : b.name,
      ),
    );

    final String userTharavad =
        (currentUser.motherTharavadu ?? currentUser.motherTharavadName ?? '')
            .toString()
            .trim();

    // Move user's matching mother taravad to Index 0
    final List<Clan> displayClans = List<Clan>.from(activeClans);
    int myIndex = -1;
    if (userTharavad.isNotEmpty || currentUser.motherClanId > 0) {
      myIndex = displayClans.indexWhere((item) {
        final name = item.name.trim().toLowerCase();
        final nameMl = item.nameMl.trim().toLowerCase();
        final uT = userTharavad.toLowerCase();
        return _isUserOwnClan(item, currentUser) ||
            (uT.isNotEmpty &&
                (name == uT ||
                    nameMl == uT ||
                    name.contains(uT) ||
                    nameMl.contains(uT) ||
                    uT.contains(name) ||
                    uT.contains(nameMl)));
      });
    }

    if (myIndex != -1) {
      final myTaravadItem = displayClans.removeAt(myIndex);
      displayClans.insert(0, myTaravadItem);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Icon(Icons.diversity_3, size: 16, color: Color(0xFF000080)),
              SizedBox(width: 6),
              Text(
                'തറവാട് ചാറ്റുകൾ (Tharavad Chats):',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF5C3E00),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 118,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayClans.length,
            itemBuilder: (context, index) {
              final clan = displayClans[index];
              final displayName = clan.displayName;
              final hasImage =
                  clan.imageUrl != null && clan.imageUrl!.isNotEmpty;

              final bool isMyTharavad =
                  (userTharavad.isNotEmpty || currentUser.motherClanId > 0) &&
                  (_isUserOwnClan(clan, currentUser) ||
                      (userTharavad.isNotEmpty &&
                          (clan.name.trim().toLowerCase() ==
                                  userTharavad.toLowerCase() ||
                              clan.nameMl.trim().toLowerCase() ==
                                  userTharavad.toLowerCase() ||
                              clan.name.trim().toLowerCase().contains(
                                userTharavad.toLowerCase(),
                              ) ||
                              clan.nameMl.trim().toLowerCase().contains(
                                userTharavad.toLowerCase(),
                              ) ||
                              userTharavad.toLowerCase().contains(
                                clan.name.trim().toLowerCase(),
                              ) ||
                              userTharavad.toLowerCase().contains(
                                clan.nameMl.trim().toLowerCase(),
                              ))));

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TharavaduDetailsPage(
                        clan: clan,
                        currentUser: currentUser,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isMyTharavad
                                ? Colors.green
                                : Colors.blueGrey.shade200,
                            width: isMyTharavad ? 3.0 : 1.5,
                          ),
                        ),
                        child: AnimatedGradientAvatarRing(
                          isMyStatus: isMyTharavad,
                          hasActiveStatus: true,
                          radius: isMyTharavad ? 28 : 26,
                          borderWidth: isMyTharavad ? 2 : 1.5,
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: isMyTharavad
                                ? Colors.green.shade50
                                : Colors.brown.shade50,
                            backgroundImage: hasImage
                                ? NetworkImage(clan.imageUrl!)
                                : null,
                            child: !hasImage
                                ? Text(
                                    displayName.isNotEmpty
                                        ? displayName[0]
                                        : 'T',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isMyTharavad
                                          ? Colors.green.shade900
                                          : Colors.brown.shade800,
                                      fontSize: 15,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: isMyTharavad ? 78 : 70,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isMyTharavad
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isMyTharavad
                                    ? Colors.green.shade900
                                    : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isMyTharavad) ...[
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.deepOrange.shade300,
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  'എന്റെ തറവാട്',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
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
  }
}
