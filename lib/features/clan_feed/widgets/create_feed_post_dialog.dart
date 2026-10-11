import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/mock_data.dart';
import '../../../widgets/tharavadu/tharavadu_media_service.dart';
import '../../../core/services/guest_permission_service.dart';

class CreateFeedPostDialog extends StatefulWidget {
  const CreateFeedPostDialog({super.key});

  @override
  State<CreateFeedPostDialog> createState() => _CreateFeedPostDialogState();
}

class _CreateFeedPostDialogState extends State<CreateFeedPostDialog> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  Uint8List? _imageBytes;
  XFile? _pickedXFile;
  String _selectedVisibility = 'public';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (GuestPermissionService.isGuest) {
      GuestPermissionService.showUploadRestrictedDialog(context);
      return;
    }
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _pickedXFile = pickedFile;
          _imageBytes = bytes;
          try {
            _selectedImage = File(pickedFile.path);
          } catch (_) {
            _selectedImage = null;
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _submitPost() async {
    if (GuestPermissionService.isGuest) {
      GuestPermissionService.showUploadRestrictedDialog(context);
      return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty && _imageBytes == null && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ദയവായി കുറച്ചു വിവരങ്ങൾ എഴുതുക അല്ലെങ്കിൽ ഒരു ചിത്രം തിരഞ്ഞെടുക്കുക.',
          ),
        ),
      );
      return;
    }

    final user = MockData().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ലോഗിൻ വിവരങ്ങൾ ലഭ്യമല്ല. ദയവായി ലോഗിൻ ചെയ്യുക.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? uploadedMediaUrl;
      if (_imageBytes != null) {
        final ext = _pickedXFile?.name.split('.').last ?? 'jpg';
        uploadedMediaUrl = await TharavaduMediaService.instance.uploadMediaBytes(
          bytes: _imageBytes!,
          fileExt: ext,
          userId: user.id,
          bucket: 'feed_media',
        );
      } else if (_selectedImage != null) {
        uploadedMediaUrl = await TharavaduMediaService.instance.uploadMediaFile(
          file: _selectedImage!,
          userId: user.id,
          bucket: 'feed_media',
        );
      }

      final myTharavaduId = user.tharavaduId != 0
          ? user.tharavaduId
          : user.motherClanId;

      final postPayload = {
        'clan_id': myTharavaduId,
        'tharavadu_id': myTharavaduId.toString(),
        'author_id': user.id,
        'user_id': user.id,
        'sender_name': user.name,
        'sender_photo': user.photoUrl,
        'text': text,
        'content': text,
        'media_url': uploadedMediaUrl,
        'media_type': uploadedMediaUrl != null ? 'photo' : 'text',
        'message_type': uploadedMediaUrl != null ? 'IMAGE' : 'TEXT',
        'is_video': false,
        'is_tharavadu_tag': false,
        'visibility': _selectedVisibility,
        'privacy_level': _selectedVisibility == 'members_only'
            ? 'THARAVADU_ONLY'
            : (_selectedVisibility == 'guest_only' ? 'MEMBERS_ONLY' : 'PUBLIC'),
        'created_at': DateTime.now().toIso8601String(),
      };

      bool inserted = false;
      try {
        await _supabase.from('tharavadu_feed_posts').insert(postPayload);
        inserted = true;
      } catch (e) {
        debugPrint('Error inserting into tharavadu_feed_posts: $e');
      }

      if (!inserted) {
        try {
          await _supabase.from('tharavadu_posts').insert(postPayload);
          inserted = true;
        } catch (e) {
          debugPrint('Error inserting into tharavadu_posts: $e');
        }
      }

      if (!inserted) {
        try {
          await _supabase.from('clan_posts').insert(postPayload);
          inserted = true;
        } catch (e) {
          debugPrint('Error inserting into clan_posts: $e');
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('വിജയകരമായി പോസ്റ്റ് ചെയ്തു!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('പോസ്റ്റ് ചെയ്യാൻ കഴിഞ്ഞില്ല: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'തറവാട് പോസ്റ്റ് നിർമ്മിക്കുക',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),

              // Visibility Selection
              const Text(
                'ആരൊക്കെ കാണണം? (Visibility)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedVisibility,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'public',
                        child: Text('എല്ലാവർക്കും കാണാം (Public)'),
                      ),
                      DropdownMenuItem(
                        value: 'members_only',
                        child: Text('തറവാട്ടുകാർക്ക് മാത്രം (Members Only)'),
                      ),
                      DropdownMenuItem(
                        value: 'guest_only',
                        child: Text('ഗെസ്റ്റ് മോഡ് (Guest Mode)'),
                      ),
                    ],
                    onChanged: _isSubmitting
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() => _selectedVisibility = val);
                            }
                          },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Post Text Composer
              TextField(
                controller: _textController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'നിങ്ങളുടെ തറവാട് അപ്‌ഡേറ്റുകളും അറിയിപ്പുകളും ഇവിടെ എഴുതുക...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF000080)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Image Picker Area
              if (_imageBytes != null || _selectedImage != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _imageBytes != null
                          ? Image.memory(
                              _imageBytes!,
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              _selectedImage!,
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedImage = null;
                        _imageBytes = null;
                        _pickedXFile = null;
                      }),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                          color: Color(0xFF000080),
                        ),
                        label: const Text(
                          'ഗാലറി (Gallery)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF000080),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _pickImage(ImageSource.camera),
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                          size: 18,
                          color: Color(0xFF000080),
                        ),
                        label: const Text(
                          'ക്യാമറ (Camera)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF000080),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // Submit / Cancel Actions
              if (_isSubmitting)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFF000080)),
                      SizedBox(height: 10),
                      Text(
                        'പോസ്റ്റ് അപ്‌ലോഡ് ചെയ്യുന്നു...',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'റദ്ദാക്കുക (Cancel)',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF000080),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _submitPost,
                        child: const Text(
                          'പോസ്റ്റ് ചെയ്യുക',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
