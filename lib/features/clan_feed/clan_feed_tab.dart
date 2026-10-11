import 'package:flutter/material.dart';
import 'widgets/tharavad_horizontal_circles.dart';
import 'widgets/global_feed_header.dart';
import 'widgets/global_feed_posts_list.dart';
import 'widgets/create_feed_post_dialog.dart';

import '../../../core/services/guest_permission_service.dart';

class ClanFeedTab extends StatelessWidget {
  const ClanFeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: TharavadHorizontalCircles()),
          const SliverToBoxAdapter(child: GlobalFeedHeader()),
          const GlobalFeedPostsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF000080),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          if (GuestPermissionService.isGuest) {
            GuestPermissionService.showUploadRestrictedDialog(context);
            return;
          }
          showDialog(
            context: context,
            builder: (context) => const CreateFeedPostDialog(),
          );
        },
      ),
    );
  }
}
