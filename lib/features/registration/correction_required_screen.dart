import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class CorrectionRequiredScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const CorrectionRequiredScreen({super.key, required this.profile});

  @override
  State<CorrectionRequiredScreen> createState() =>
      _CorrectionRequiredScreenState();
}

class _CorrectionRequiredScreenState extends State<CorrectionRequiredScreen> {
  final _supabase = Supabase.instance.client;
  bool _isSubmitting = false;

  List<dynamic> _correctionRequests = [];
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _notes = {};

  final Map<String, File> _newImages = {};

  @override
  void initState() {
    super.initState();
    _parseCorrectionRequests();
  }

  void _parseCorrectionRequests() {
    final reqs = widget.profile['correction_requests'];
    if (reqs is List) {
      _correctionRequests = reqs;
    }

    for (var req in _correctionRequests) {
      if (req is Map) {
        final field = req['field']?.toString() ?? '';
        final note = req['note']?.toString() ?? 'Please correct this field.';
        _notes[field] = note;

        // Initialize controllers for text fields
        if (field == 'name' || field == 'full_name') {
          _controllers[field] = TextEditingController(
            text: widget.profile['name'] ?? widget.profile['full_name'],
          );
        } else if (field == 'public_display_number' ||
            field == 'guardian_phone' ||
            field == 'phone') {
          _controllers[field] = TextEditingController(
            text:
                widget.profile['public_display_number'] ??
                widget.profile['guardian_phone'],
          );
        } else if (field == 'id_number') {
          _controllers[field] = TextEditingController(
            text: widget.profile['id_number'],
          );
        } else {
          // generic fallback for text field
          if (!field.contains('photo') &&
              !field.contains('url') &&
              !field.contains('document')) {
            _controllers[field] = TextEditingController(
              text: widget.profile[field]?.toString() ?? '',
            );
          }
        }
      }
    }
  }

  Future<void> _pickImage(String field) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      setState(() {
        _newImages[field] = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitCorrections() async {
    setState(() => _isSubmitting = true);
    final userId = widget.profile['id'];

    try {
      final updates = <String, dynamic>{'verification_status': 'pending'};

      // Update text fields
      for (var entry in _controllers.entries) {
        updates[entry.key] = entry.value.text.trim();
      }

      // Upload new images if picked
      if (_newImages.isNotEmpty) {
        for (var entry in _newImages.entries) {
          final field = entry.key;
          final file = entry.value;

          final ext = file.path.split('.').last;
          final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';

          String bucket = 'identity_documents'; // default for id
          if (field.contains('photo') || field.contains('profile')) {
            bucket = 'profile_photos';
          }

          final path = '$userId/$fileName';

          await _supabase.storage.from(bucket).upload(path, file);
          final url = _supabase.storage.from(bucket).getPublicUrl(path);

          updates[field] = url;
        }
      }

      // Clear correction requests array now that it's submitted
      updates['correction_requests'] = null;

      // Apply updates to DB
      await _supabase
          .from('kurichiyar_profiles')
          .update(updates)
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile updated successfully! Pending admin approval.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      // The Realtime listener in AuthWrapper/PendingVerificationScreen will auto-route since status is now pending.
    } catch (e) {
      debugPrint('Correction upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit corrections: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _getFriendlyFieldName(String field) {
    switch (field) {
      case 'name':
      case 'full_name':
        return 'പൂർണ്ണനാമം (Full Name)';
      case 'id_number':
        return 'തിരിച്ചറിയൽ നമ്പർ (ID Number)';
      case 'public_display_number':
      case 'phone':
      case 'guardian_phone':
        return 'ഫോൺ നമ്പർ (Phone Number)';
      case 'profile_photo_url':
      case 'photo_url':
        return 'പ്രൊഫൈൽ ഫോട്ടോ (Profile Photo)';
      case 'id_document_url':
        return 'തിരിച്ചറിയൽ രേഖ (ID Document Image)';
      default:
        return field.replaceAll('_', ' ').toUpperCase();
    }
  }

  Widget _buildFieldEditor(String field, String note) {
    final isImageField =
        field.contains('photo') ||
        field.contains('document') ||
        field.contains('url');

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getFriendlyFieldName(field),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 8),

          if (isImageField) ...[
            _newImages[field] != null
                ? Image.file(_newImages[field]!, height: 150, fit: BoxFit.cover)
                : widget.profile[field] != null
                ? Image.network(
                    widget.profile[field],
                    height: 150,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.image, size: 80, color: Colors.grey),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pickImage(field),
              icon: const Icon(Icons.upload),
              label: const Text('പുതിയ ഫോട്ടോ അപ്ലോഡ് ചെയ്യുക (Upload New)'),
            ),
          ] else ...[
            TextFormField(
              controller: _controllers[field],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hintText: 'Enter updated ${_getFriendlyFieldName(field)}',
              ),
            ),
          ],

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'അഡ്മിൻ നിർദ്ദേശം: $note',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Strictly block back navigation
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.red.shade600,
          title: const Text(
            'പ്രൊഫൈൽ വിവരങ്ങൾ തിരുത്തുക ⚠️',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          elevation: 0,
        ),
        body: SafeArea(
          child: _correctionRequests.isEmpty
              ? const Center(
                  child: Text(
                    'No corrections required.',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'നിങ്ങൾ നൽകിയ ചില വിവരങ്ങളിൽ തിരുത്തലുകൾ ആവശ്യമുണ്ട്. ദയവായി താഴെ പറയുന്ന ഫീൽഡുകൾ ശരിയാക്കി വീണ്ടും സമർപ്പിക്കുക. അതിനുശേഷം മാത്രമേ ആപ്പ് ഉപയോഗിക്കാൻ സാധിക്കൂ.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 15,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      ..._notes.entries.map(
                        (e) => _buildFieldEditor(e.key, e.value),
                      ),

                      const SizedBox(height: 32),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitCorrections,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'വിവരങ്ങൾ പുതുക്കുക (Update & Submit)',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () async {
                          final nav = Navigator.of(context);
                          await _supabase.auth.signOut();
                          nav.pushNamedAndRemoveUntil(
                            '/login',
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Logout / ലോഗ്ഔട്ട്',
                          style: TextStyle(color: Colors.red),
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
