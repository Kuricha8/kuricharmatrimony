import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import '../../core/services/photo_quality_validator_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CorrectionScreen extends StatefulWidget {
  final UserProfile profile;

  const CorrectionScreen({super.key, required this.profile});

  @override
  State<CorrectionScreen> createState() => _CorrectionScreenState();
}

class _CorrectionScreenState extends State<CorrectionScreen> {
  final _responseController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _newIdDocument;
  File? _newProfilePhoto;
  bool _isSubmitting = false;
  Future<void> _pickImage(bool isProfilePhoto) async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      if (isProfilePhoto) {
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
      }

      setState(() {
        if (isProfilePhoto) {
          _newProfilePhoto = file;
        } else {
          _newIdDocument = file;
        }
      });
    }
  }

  void _resubmitProfile() {
    if (_responseController.text.trim().isEmpty &&
        _newIdDocument == null &&
        _newProfilePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide an explanation or upload a new document/photo.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Mock API Call to update profile
    Future.delayed(const Duration(seconds: 2), () {
      final mockData = MockData();
      mockData.resubmitProfile(widget.profile.id);

      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile resubmitted successfully! Admin will review shortly.',
            ),
          ),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Profile Correction Required',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Rejection Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your profile was rejected',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.profile.rejectionReason ??
                            'No specific reason provided.',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Correction Input Field
                const Text(
                  'Reason for Correction / Write your response:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _responseController,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText:
                        'Explain the mismatch or clarify your data here...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.orangeAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Re-upload mechanisms
                const Text(
                  'Update Documents or Photos (Optional):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(false),
                        icon: const Icon(
                          Icons.badge,
                          color: Colors.orangeAccent,
                        ),
                        label: Text(
                          _newIdDocument != null
                              ? 'ID Selected'
                              : 'Re-upload ID',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(true),
                        icon: const Icon(
                          Icons.portrait,
                          color: Colors.orangeAccent,
                        ),
                        label: Text(
                          _newProfilePhoto != null
                              ? 'Photo Selected'
                              : 'Re-upload Photo',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Resubmit Button
                _isSubmitting
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.orangeAccent,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _resubmitProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Resubmit Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
