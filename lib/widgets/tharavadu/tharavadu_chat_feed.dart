import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import 'widgets/tharavad_feed_header.dart';
import 'widgets/tharavad_post_card_list.dart';
import 'widgets/tharavad_chat_input_bar.dart';

class TharavaduChatFeed extends StatelessWidget {
  final Clan clan;
  final UserProfile? currentUser;
  final VoidCallback? onUploadSuccess;
  final Function(String imageUrl) onClanImageUpdate;

  const TharavaduChatFeed({
    super.key,
    required this.clan,
    this.currentUser,
    this.onUploadSuccess,
    required this.onClanImageUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final me = currentUser ?? MockData().currentUser;
    final String userMotherClan =
        (me?.motherTharavadu ?? me?.mothersTarawad ?? '')
            .toString()
            .trim()
            .toLowerCase();
    final String activeClan = clan.name.trim().toLowerCase();

    final bool isClanMember =
        userMotherClan.isNotEmpty &&
        (activeClan.contains(userMotherClan) ||
            userMotherClan.contains(activeClan));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          TharavadFeedHeader(canPost: isClanMember),
          Expanded(
            child: TharavadPostCardList(
              clan: clan,
              currentUser: currentUser,
              onClanImageUpdate: onClanImageUpdate,
            ),
          ),
        ],
      ),
      bottomNavigationBar: isClanMember
          ? TharavadChatInputBar(clan: clan, currentUser: currentUser)
          : null,
    );
  }
}
