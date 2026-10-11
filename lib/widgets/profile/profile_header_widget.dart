import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/models.dart';
import '../../core/theme/subscription_theme.dart';
import '../../core/widgets/watermarked_image.dart';
import '../../core/widgets/fullscreen_image_viewer.dart';
import '../../features/clan_feed/tharavadu_list.dart';
import '../../features/dashboard/edit_profile_sheet.dart';
import '../../features/profile_detail/partner_preferences_edit_sheet.dart';
import '../../core/services/image_validation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/mock_data.dart';

class ProfileHeaderWidget extends StatefulWidget {
  final UserProfile me;
  final SubscriptionTheme subTheme;
  final Function(UserProfile) onProfileUpdated;

  const ProfileHeaderWidget({
    super.key,
    required this.me,
    required this.subTheme,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends State<ProfileHeaderWidget> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: widget.subTheme.backgroundGradient,
        border: widget.subTheme.level != MembershipLevel.free
            ? Border.all(color: widget.subTheme.accentColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: widget.subTheme.accentColor.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: widget.subTheme.level != MembershipLevel.free
            ? Colors.transparent
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              if (_isUploading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: CircularProgressIndicator(),
                ),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildPhotoItem(widget.me.photoUrl, widget.subTheme, 0, [
                      widget.me.photoUrl,
                      ...widget.me.additionalPhotos,
                    ], context),
                    ...widget.me.additionalPhotos.asMap().entries.map(
                      (e) => _buildPhotoItem(
                        e.value,
                        widget.subTheme,
                        e.key + 1,
                        [widget.me.photoUrl, ...widget.me.additionalPhotos],
                        context,
                      ),
                    ),
                    if (widget.me.allowPhotoEdit &&
                        widget.me.additionalPhotos.length < 4)
                      _buildAddPhotoButton(context, widget.me),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.me.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5C3E00),
                    ),
                  ),
                  if (widget.me.verificationStatus == 'approved' || widget.me.verificationStatus == 'verified') ...[
                    const SizedBox(width: 8),
                    const Tooltip(
                      message: 'Verified Profile',
                      child: Icon(Icons.verified, color: Colors.amber, size: 24),
                    ),
                  ],
                  if (widget.subTheme.badgeIcon != null) ...[
                    const SizedBox(width: 8),
                    widget.subTheme.badgeIcon!,
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'ID: KM-${widget.me.id.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => EditProfileSheet(user: widget.me),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5C3E00),
                      side: const BorderSide(color: Color(0xFFD4AF37)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (c) => Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(c).padding.top + 40,
                          ),
                          child: PartnerPreferencesEditSheet(
                            profile: widget.me,
                          ),
                        ),
                      );
                      if (result == true) {
                        final me = MockData().currentUser;
                        if (me != null) widget.onProfileUpdated(me);
                      }
                    },
                    icon: const Icon(Icons.favorite, size: 16),
                    label: const Text('Preferences'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.pink.shade700,
                      side: BorderSide(color: Colors.pink.shade200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ],
              ),
              if (widget.me.motherTharavadu != null &&
                      widget.me.motherTharavadu!.isNotEmpty ||
                  getClanById(widget.me.motherClanId)?.tharavadName !=
                      null) ...[
                const SizedBox(height: 4),
                Text(
                  'തറവാട്: ${widget.me.motherTharavadu ?? getClanById(widget.me.motherClanId)!.tharavadName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF000080),
                  ),
                ),
              ],
              if (widget.me.isPremium &&
                  widget.me.planTier != null &&
                  widget.me.planTier!.toLowerCase() != 'free')
                Chip(
                  label: const Text(
                    'Premium Subscriber',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.amber.shade700,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteProfilePhoto(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ഫോട്ടോ നീക്കം ചെയ്യണോ?'),
        content: const Text(
          'Are you sure you want to remove your profile photo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUploading = true);
    try {
      if (index == 0) {
        // Clear main profile photo
        await Supabase.instance.client
            .from('kurichiyar_profiles')
            .update({'photo_url': ''})
            .eq('id', widget.me.id);

        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.me.id)
              .set({
                'photo_url': '',
                'profile_photo': '',
                'avatar_url': '',
              }, SetOptions(merge: true));
        } catch (fErr) {
          debugPrint('Firestore photo delete sync note: $fErr');
        }

        final updatedMe = widget.me.copyWith(photoUrl: '');
        widget.onProfileUpdated(updatedMe);
        MockData().updateCurrentUser(updatedMe);
      } else {
        // Remove additional photo at index - 1
        final newAdditional = List<String>.from(widget.me.additionalPhotos);
        final targetIndex = index - 1;
        if (targetIndex >= 0 && targetIndex < newAdditional.length) {
          newAdditional.removeAt(targetIndex);
        }

        await Supabase.instance.client
            .from('kurichiyar_profiles')
            .update({'additional_photos': newAdditional})
            .eq('id', widget.me.id);

        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.me.id)
              .set({'additional_photos': newAdditional}, SetOptions(merge: true));
        } catch (fErr) {
          debugPrint('Firestore additional photo delete sync note: $fErr');
        }

        final updatedMe = widget.me.copyWith(additionalPhotos: newAdditional);
        widget.onProfileUpdated(updatedMe);
        MockData().updateCurrentUser(updatedMe);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'പ്രൊഫൈൽ ഫോട്ടോ നീക്കംചെയ്തു (Profile photo removed)',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete photo: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildPhotoItem(
    String path,
    SubscriptionTheme subTheme,
    int index,
    List<String> allPhotos,
    BuildContext context,
  ) {
    final bool hasValidPhoto =
        path.isNotEmpty && (path.startsWith('http') || File(path).existsSync());

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            if (hasValidPhoto) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => FullscreenImageViewer(
                    imageUrls: allPhotos.where((p) => p.isNotEmpty).toList(),
                    initialIndex: index,
                  ),
                ),
              );
            }
          },
          child: subTheme.wrapAvatar(
            Container(
              margin: const EdgeInsets.only(right: 12),
              width: 100,
              height: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: hasValidPhoto
                    ? (path.startsWith('http')
                          ? WatermarkedImage(
                              imageUrl: path,
                              height: 100,
                              width: 100,
                            )
                          : Image.file(
                              File(path),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(
                                    'assets/images/default_avatar.png',
                                    fit: BoxFit.cover,
                                  ),
                            ))
                    : Image.asset(
                        'assets/images/default_avatar.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
        ),
        if (hasValidPhoto)
          Positioned(
            top: 0,
            right: 12,
            child: InkWell(
              onTap: () => _deleteProfilePhoto(index),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddPhotoButton(BuildContext context, UserProfile me) {
    return GestureDetector(
      onTap: () async {
        final result = await FilePicker.pickFiles(type: FileType.image);
        if (result != null && result.files.single.path != null) {
          final path = result.files.single.path!;
          setState(() {
            _isUploading = true;
          });

          try {
            final validatedPath =
                await ImageValidationService.validateProfileImage(path);
            final file = File(validatedPath);
            final fileName =
                '${DateTime.now().millisecondsSinceEpoch}_additional.jpg';
            final storagePath = 'profile_photos/$fileName';

            await Supabase.instance.client.storage
                .from('user_documents')
                .upload(storagePath, file);

            final publicUrl = Supabase.instance.client.storage
                .from('user_documents')
                .getPublicUrl(storagePath);

            final response = await Supabase.instance.client
                .from('kurichiyar_profiles')
                .select('additional_photos')
                .eq('id', me.id)
                .maybeSingle();

            List<String> currentPhotos = [];
            if (response != null && response['additional_photos'] != null) {
              if (response['additional_photos'] is List) {
                currentPhotos = List<String>.from(
                  response['additional_photos'].map((e) => e.toString()),
                );
              }
            }

            currentPhotos.add(publicUrl);

            await Supabase.instance.client
                .from('kurichiyar_profiles')
                .update({'additional_photos': currentPhotos})
                .eq('id', me.id);

            // Sync additional photos to Cloud Firestore document users/{uid}
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(me.id)
                  .set({'additional_photos': currentPhotos}, SetOptions(merge: true));
            } catch (fErr) {
              debugPrint('Firestore additional photos upload sync note: $fErr');
            }

            final updatedMe = me.copyWith(additionalPhotos: currentPhotos);
            widget.onProfileUpdated(updatedMe);
          } catch (e) {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text(
                    'Validation Error',
                    style: TextStyle(color: Colors.red),
                  ),
                  content: Text(e.toString().replaceAll('Exception: ', '')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
          } finally {
            if (mounted) {
              setState(() {
                _isUploading = false;
              });
            }
          }
        }
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade200,
          border: Border.all(
            color: Colors.grey.shade400,
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(child: Icon(Icons.add_a_photo, color: Colors.grey)),
      ),
    );
  }
}
