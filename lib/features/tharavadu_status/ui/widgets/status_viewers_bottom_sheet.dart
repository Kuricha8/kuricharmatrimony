import 'package:flutter/material.dart';
import '../../../../core/models/status_view_model.dart';
import '../../../../core/services/status_view_tracking_service.dart';

/// Clean and minimal Viewers BottomSheet displaying status view analytics
/// and registered member viewer cards according to WhatsApp-style specifications.
class StatusViewersBottomSheet extends StatelessWidget {
  final String statusId;
  final String collection;
  final StatusViewData? initialData;

  const StatusViewersBottomSheet({
    super.key,
    required this.statusId,
    this.collection = 'statuses',
    this.initialData,
  });

  /// Static helper to display the sheet modally.
  static Future<void> show(
    BuildContext context, {
    required String statusId,
    String collection = 'statuses',
    StatusViewData? initialData,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatusViewersBottomSheet(
        statusId: statusId,
        collection: collection,
        initialData: initialData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StatusViewData>(
      stream: StatusViewTrackingService.instance.streamStatusViewData(
        statusId,
        collection: collection,
      ),
      initialData: initialData ??
          StatusViewTrackingService.instance.getCachedViewData(statusId),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const StatusViewData();
        final screenHeight = MediaQuery.of(context).size.height;

        return Container(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.72,
            minHeight: screenHeight * 0.35,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // ── Grab Bar Indicator ──
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Header Summary ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Total Views Title
                            Text(
                              'ആകെ കണ്ടവർ: ${data.viewCount}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Compact Pill / Badge for Guest Views
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '+${data.guestViewCount} ഗെസ്റ്റ് കാഴ്ചക്കാർ (Guest Views)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 24),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // ── Section Title ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Text(
                    'മെമ്പർ ലിസ്റ്റ് (${data.viewers.length})',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),

                // ── Member List Items ──
                Flexible(
                  child: data.viewers.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility_off_outlined,
                                  size: 38,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'ഇതുവരെ മെമ്പർമാർ ആരും കണ്ടിട്ടില്ല',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(bottom: 24),
                          physics: const BouncingScrollPhysics(),
                          itemCount: data.viewers.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            thickness: 0.7,
                            indent: 72,
                            endIndent: 20,
                            color: Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (context, index) {
                            final viewer = data.viewers[index];
                            final hasPhoto = viewer.photoUrl.isNotEmpty &&
                                viewer.photoUrl.startsWith('http');

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  // Profile Photo ONLY
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    backgroundImage: hasPhoto
                                        ? NetworkImage(viewer.photoUrl)
                                        : null,
                                    child: !hasPhoto
                                        ? const Icon(
                                            Icons.person,
                                            size: 22,
                                            color: Color(0xFF94A3B8),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  // Name ONLY (no subtitles, no tharavadu)
                                  Expanded(
                                    child: Text(
                                      viewer.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
