import 'package:flutter/material.dart';
import '../../../core/services/tharavadu_stories_service.dart';
import '../../../core/utils/mock_data.dart';
import '../../../core/widgets/animated_gradient_avatar_ring.dart';
import '../../../core/services/guest_permission_service.dart';
import 'tharavadu_story_full_screen_viewer.dart';

/// WhatsApp/Instagram-style horizontal story tray for Tharavadu statuses.
///
/// Access Control:
/// - Guest Mode: Completely hides the "Add Status (+)" button or blocks uploads
///   with standard Malayalam modal. Guests can freely VIEW all stories.
/// - Authenticated Members: Shows "എന്റെ തറവാട് (Add Status)" button if authorized.
class TharavaduStoryTray extends StatefulWidget {
  final VoidCallback? onAddStatus;
  final bool isGuest;
  final bool hideAddStatusForGuest;

  const TharavaduStoryTray({
    super.key,
    this.onAddStatus,
    this.isGuest = false,
    this.hideAddStatusForGuest = true,
  });

  @override
  State<TharavaduStoryTray> createState() => _TharavaduStoryTrayState();
}

class _TharavaduStoryTrayState extends State<TharavaduStoryTray> {
  List<TharavaduStoryGroup> _storyGroups = [];
  bool _isLoading = true;

  bool get _isGuestUser => widget.isGuest || GuestPermissionService.isGuest;
  bool get _shouldShowAddStatus => !_isGuestUser || !widget.hideAddStatusForGuest;

  @override
  void initState() {
    super.initState();
    _loadStories();
    TharavaduStoriesService.instance.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    TharavaduStoriesService.instance.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      _loadStories(refresh: false);
    }
  }

  Future<void> _loadStories({bool refresh = true}) async {
    if (refresh && mounted) {
      setState(() => _isLoading = true);
    }
    final groups = await TharavaduStoriesService.instance.fetchActiveStories();
    if (mounted) {
      setState(() {
        _storyGroups = groups;
        _isLoading = false;
      });
    }
  }

  void _handleAddStatusTap(BuildContext context) {
    if (_isGuestUser) {
      GuestPermissionService.showUploadRestrictedDialog(context);
      return;
    }

    if (!GuestPermissionService.canUploadStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'സ്ഥിരീകരിച്ച തറവാട് വിവരങ്ങളുള്ള അംഗങ്ങൾക്ക് മാത്രമേ സ്റ്റാറ്റസ് പങ്കിടാൻ സാധിക്കൂ.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (widget.onAddStatus != null) {
      widget.onAddStatus!();
      return;
    }

    _showAddStatusBottomSheet(context);
  }

  void _showAddStatusBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'തറവാട് സ്റ്റാറ്റസ് ചേർക്കുക',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE91E63),
                  child: Icon(Icons.favorite, color: Colors.white),
                ),
                title: const Text('വിവാഹം (Wedding)'),
                subtitle: const Text('തറവാട്ടിലെ പുതിയ വിവാഹ വാർത്ത പങ്കുവെക്കുക'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('സ്റ്റാറ്റസ് അപ്‌ലോഡ് തയ്യാറാകുന്നു...')),
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF000080),
                  child: Icon(Icons.campaign, color: Colors.white),
                ),
                title: const Text('അറിയിപ്പ് (Notice)'),
                subtitle: const Text('തറവാട്ടു യോഗങ്ങൾ, പൂജകൾ തുടങ്ങിയവ'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('സ്റ്റാറ്റസ് അപ്‌ലോഡ് തയ്യാറാകുന്നു...')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openStory(int groupIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TharavaduStoryFullScreenViewer(
          storyGroups: _storyGroups,
          initialGroupIndex: groupIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showAdd = _shouldShowAddStatus;
    final totalCount = showAdd ? 1 + _storyGroups.length : _storyGroups.length;

    return Container(
      height: 114,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _isLoading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: totalCount,
              itemBuilder: (context, index) {
                // When Add Status is enabled, index 0 is Add Status
                if (showAdd && index == 0) {
                  return _buildAddStatusItem(context);
                }

                // Adjust index based on whether Add Status was inserted
                final groupIndex = showAdd ? index - 1 : index;
                final group = _storyGroups[groupIndex];
                return _buildTharavaduStoryAvatarItem(group, groupIndex);
              },
            ),
    );
  }

  Widget _buildAddStatusItem(BuildContext context) {
    final currentUser = MockData().currentUser;
    final hasUserPhoto = currentUser != null && currentUser.photoUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: () => _handleAddStatusTap(context),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE2E8F0),
                    backgroundImage: hasUserPhoto
                        ? NetworkImage(currentUser.photoUrl)
                        : null,
                    child: !hasUserPhoto
                        ? const Icon(
                            Icons.temple_hindu,
                            color: Color(0xFF1E3A8A),
                            size: 26,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E), // Green plus badge
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const SizedBox(
              width: 72,
              child: Text(
                'എന്റെ തറവാട്',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTharavaduStoryAvatarItem(
    TharavaduStoryGroup group,
    int groupIndex,
  ) {
    final hasUnviewed = group.hasUnviewed;
    final clan = group.clan;
    final hasImage = clan.imageUrl != null && clan.imageUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: () => _openStory(groupIndex),
        child: Column(
          children: [
            AnimatedGradientAvatarRing(
              hasActiveStatus: hasUnviewed,
              paletteIndex: clan.id % AvatarRingPalettes.allPalettes.length,
              radius: 28,
              borderWidth: hasUnviewed ? 2.5 : 1.5,
              child: CircleAvatar(
                radius: 27,
                backgroundColor: const Color(0xFF1E3A8A),
                backgroundImage: hasImage ? NetworkImage(clan.imageUrl!) : null,
                child: !hasImage
                    ? const Icon(
                        Icons.temple_hindu,
                        color: Colors.white,
                        size: 24,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 72,
              child: Text(
                clan.displayName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: hasUnviewed ? FontWeight.bold : FontWeight.w500,
                  color: hasUnviewed
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
