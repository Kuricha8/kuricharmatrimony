import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/mock_data.dart';
import '../../../core/widgets/animated_gradient_avatar_ring.dart';
import '../tharavadu_list.dart';
import '../tharavadu_details_page.dart';

class TharavadHorizontalCircles extends StatelessWidget {
  final UserProfile? currentUser;
  final String? currentUserMotherTharavad;

  const TharavadHorizontalCircles({
    super.key,
    this.currentUser,
    this.currentUserMotherTharavad,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MockData(),
      builder: (context, child) {
        final me =
            currentUser ??
            MockData().currentUser ??
            UserProfile(
              id: Supabase.instance.client.auth.currentUser?.id ?? 'guest_user',
              email:
                  Supabase.instance.client.auth.currentUser?.email ??
                  'user@kurichiyarmatrimony.in',
              name: 'അംഗം',
              photoUrl: '',
              gender: Gender.male,
              maritalStatus: MaritalStatus.first,
              fatherClanId: 0,
              motherClanId: 0,
              isOutOfCaste: false,
              age: 25,
            );

        final String myClan =
            currentUserMotherTharavad?.trim().toLowerCase() ??
            (me.motherTharavadu ?? me.motherTharavadName ?? '')
                .toString()
                .trim()
                .toLowerCase();

        // Verify & Log as requested
        debugPrint("ACTIVE MOTHER THARAVAD FOR FEED: $myClan");

        // Get list of active clans sorted alphabetically
        final activeClans = allClans.where((c) => c.isActive).toList();
        activeClans.sort(
          (a, b) => (a.nameMl.isNotEmpty ? a.nameMl : a.name).compareTo(
            b.nameMl.isNotEmpty ? b.nameMl : b.name,
          ),
        );

        final List<Clan> displayClans = List<Clan>.from(activeClans);
        int myIndex = -1;

        if (myClan.isNotEmpty) {
          myIndex = displayClans.indexWhere((c) {
            final cName = c.name.trim().toLowerCase();
            return myClan.contains(cName) || cName.contains(myClan);
          });
        }

        if (myIndex != -1) {
          final myCircleItem = displayClans.removeAt(myIndex);
          displayClans.insert(0, myCircleItem);
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
                      myClan.isNotEmpty &&
                      (myClan.contains(clan.name.trim().toLowerCase()) ||
                          clan.name.trim().toLowerCase().contains(myClan));

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TharavaduDetailsPage(clan: clan, currentUser: me),
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
      },
    );
  }
}
