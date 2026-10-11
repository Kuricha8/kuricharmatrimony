import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import '../../core/widgets/auth_wrapper.dart';
import '../../core/services/photo_quality_validator_service.dart';
import '../dashboard/dashboard_shell.dart';

class ForcePhotoUploadScreen extends StatefulWidget {
  final UserProfile? profile;

  const ForcePhotoUploadScreen({super.key, this.profile});

  @override
  State<ForcePhotoUploadScreen> createState() => _ForcePhotoUploadScreenState();
}

class _ForcePhotoUploadScreenState extends State<ForcePhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;

  File? _selectedImage;
  Uint8List? _imageBytes;
  XFile? _pickedXFile;
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );

      if (picked != null) {
        final file = File(picked.path);
        final validation = await PhotoQualityValidatorService.instance
            .validateProfilePhoto(file, isFullLength: false);
        if (!validation.isValid) {
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  validation.errorMessageMl ??
                      PhotoQualityValidatorService.kFaceNotClearMsg,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.red.shade800,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedXFile = picked;
          _imageBytes = bytes;
          _selectedImage = file;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ഫോട്ടോ തിരഞ്ഞെടുക്കുന്നതിൽ പിശക്: $e')),
        );
      }
    }
  }

  Future<void> _uploadAndContinue() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ദയവായി ഒരു പ്രൊഫൈൽ ഫോട്ടോ തിരഞ്ഞെടുക്കുക (Please select a profile photo)',
          ),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = _supabase.auth.currentUser;
      final userId =
          user?.id ?? widget.profile?.id ?? MockData().currentUser?.id;

      if (userId == null || userId.isEmpty) {
        throw Exception('User session not found.');
      }

      final fileExt = _pickedXFile?.name.split('.').last ??
          (_selectedImage != null ? _selectedImage!.path.split('.').last : 'jpg');
      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      String uploadedUrl =
          _selectedImage?.path ?? ''; // Default to local path as fallback

      // Try uploading to Supabase Storage
      try {
        if (_imageBytes != null) {
          await _supabase.storage.from('profiles').uploadBinary(
                fileName,
                _imageBytes!,
                fileOptions: const FileOptions(upsert: true),
              );
        } else if (_selectedImage != null) {
          await _supabase.storage
              .from('profiles')
              .upload(
                fileName,
                _selectedImage!,
                fileOptions: const FileOptions(upsert: true),
              );
        }
        uploadedUrl = _supabase.storage.from('profiles').getPublicUrl(fileName);
      } catch (storageErr) {
        debugPrint('Supabase storage upload fallback note: $storageErr');
      }

      // Update Supabase profile database table
      try {
        await _supabase
            .from('kurichiyar_profiles')
            .update({
              'profile_photo_url': uploadedUrl,
              'photo_url': uploadedUrl,
            })
            .eq('id', userId);
      } catch (dbErr) {
        debugPrint('Supabase profile table update note: $dbErr');
      }

      // Update local MockData singleton & current user state
      final currentMap =
          widget.profile?.toMap() ??
          MockData().currentUser?.toMap() ??
          {'id': userId};
      currentMap['id'] = userId;
      currentMap['profile_photo_url'] = uploadedUrl;
      currentMap['photo_url'] = uploadedUrl;
      MockData().syncProfileData(UserProfile.fromMap(currentMap));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'പ്രൊഫൈൽ ഫോട്ടോ വിജയകരമായി അപ്‌ലോഡ് ചെയ്തു! (Profile photo updated!)',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Redirect to AuthWrapper / DashboardShell cleanly
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const AuthWrapper(child: DashboardShell()),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Force photo upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'പ്രൊഫൈൽ ഫോട്ടോ (Mandatory Photo)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'പ്രൊഫൈൽ ഫോട്ടോ നിർബന്ധമാണ്\nProfile Photo is Mandatory to access Kurichiyar Matrimony',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'ആപ്പ് ഉപയോഗിച്ച് മുന്നോട്ട് പോകുന്നതിന് നിങ്ങളുടെ ഒരു വ്യക്തമായ പ്രൊഫൈൽ ഫോട്ടോ അപ്‌ലോഡ് ചെയ്യുക.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload a clear profile photo of yourself to unlock full app access.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 75,
                      backgroundColor: const Color(
                        0xFF000080,
                      ).withValues(alpha: 0.1),
                      backgroundImage: _imageBytes != null
                          ? MemoryImage(_imageBytes!)
                          : (_selectedImage != null
                              ? FileImage(_selectedImage!)
                              : null),
                      child:
                          _imageBytes == null &&
                          _selectedImage == null &&
                              (widget.profile?.photoUrl == null ||
                                  widget.profile!.photoUrl.isEmpty ||
                                  !widget.profile!.photoUrl.startsWith('http'))
                          ? const Icon(
                              Icons.person,
                              size: 80,
                              color: Color(0xFF000080),
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF000080),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('ക്യാമറ (Camera)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF000080),
                      side: const BorderSide(color: Color(0xFF000080)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('ഗാലറി (Gallery)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF000080),
                      side: const BorderSide(color: Color(0xFF000080)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000080),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'അപ്‌ലോഡ് ചെയ്ത് തുടരുക (Upload & Continue)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _signOut,
                child: const Text(
                  'മറ്റൊരു അക്കൗണ്ടിലേക്ക് മാറുക (Sign Out)',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
