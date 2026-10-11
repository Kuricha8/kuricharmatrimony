import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Malayalam Report Reason Labels — injected as native Unicode string assets
// ---------------------------------------------------------------------------
const _kReportTitle = 'പ്രൊഫൈൽ / പോസ്‌റ്റ് പരാതി';
const _kReportSubtitle = 'ലംഘനത്തിന്റെ കാരണം തിരഞ്ഞെടുക്കുക';
const _kReportSuccess =
    'പരാതി സ്വീകരിച്ചു. അഡ്‌മിൻ 24 മണിക്കൂറിനുള്ളിൽ അവലോകനം ചെയ്യും.';
const _kReportError = 'പരാതി സമർപ്പിക്കാൻ കഴിഞ്ഞില്ല. വീണ്ടും ശ്രമിക്കുക.';
const _kReportCancel = 'റദ്ദാക്കുക';
const _kReportSubmit = 'പരാതി സമർപ്പിക്കുക';
const _kReportButtonLabel = 'പരാതിപ്പെടുക'; // Button on every status card
const _kReportDetails = 'അധിക വിശദാംശങ്ങൾ (ഓപ്ഷണൽ)';
const _kReportDetailsHint = 'ഇവിടെ ടൈപ്പ് ചെയ്യുക...';

/// Violation reason options — displayed in Malayalam, stored in English key
const List<Map<String, String>> kReportReasons = [
  {'key': 'abusive_content', 'label': 'അഹിംസാത്മകമല്ലാത്ത / അശ്ലീല ഉൾഡാക്കം'},
  {'key': 'harassment', 'label': 'ഉപദ്രവം അല്ലെങ്കിൽ ഭീഷണി'},
  {'key': 'fake_profile', 'label': 'വ്യാജ പ്രൊഫൈൽ / തട്ടിപ്പ്'},
  {'key': 'illegal_content', 'label': 'നിയമ വിരുദ്ധ ഉൾഡാക്കം'},
  {'key': 'misinformation', 'label': 'തെറ്റായ വിവരം'},
  {'key': 'spam', 'label': 'സ്‌പാം'},
  {'key': 'other', 'label': 'മറ്റുള്ളവ'},
];

// ---------------------------------------------------------------------------
// ReportService — writes flag to Supabase post_reports table
// ---------------------------------------------------------------------------
class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Writes a discrete report record to Supabase.
  /// Falls back to local mock log if Supabase is unavailable.
  Future<bool> reportPost({
    required String postId,
    required String reporterProfileId,
    required String reasonKey,
    String? details,
  }) async {
    final payload = {
      'post_id': postId,
      'reporter_id': reporterProfileId,
      'reason': reasonKey,
      'details': details ?? '',
      'status': 'pending', // admin screening state
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      final client = _supabase;
      if (client != null) {
        await client.from('post_reports').insert(payload);
      } else {
        debugPrint('[ReportService] Log: $payload');
      }
      return true;
    } catch (e) {
      debugPrint('[ReportService] Error: $e');
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// ReportPostSheet — modal shown when "പരാതിപ്പെടുക" is tapped
// ---------------------------------------------------------------------------
class ReportPostSheet extends StatefulWidget {
  final String postId;
  final String reporterProfileId;

  const ReportPostSheet({
    super.key,
    required this.postId,
    required this.reporterProfileId,
  });

  @override
  State<ReportPostSheet> createState() => _ReportPostSheetState();
}

class _ReportPostSheetState extends State<ReportPostSheet> {
  String? _selectedReasonKey;
  final _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReasonKey == null) return;
    setState(() => _isSubmitting = true);

    final success = await ReportService.instance.reportPost(
      postId: widget.postId,
      reporterProfileId: widget.reporterProfileId,
      reasonKey: _selectedReasonKey!,
      details: _detailsController.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? _kReportSuccess : _kReportError),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                const Icon(Icons.flag_outlined, color: Colors.red, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    _kReportTitle,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              _kReportSubtitle,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Reason radio list — uses RadioGroup ancestor (Flutter 3.32+)
            RadioGroup<String>(
              groupValue: _selectedReasonKey ?? '',
              onChanged: (val) => setState(() => _selectedReasonKey = val),
              child: Column(
                children: kReportReasons
                    .map(
                      (r) => RadioListTile<String>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: r['key']!,
                        title: Text(
                          r['label']!,
                          style: const TextStyle(fontSize: 14),
                        ),
                        activeColor: Colors.red.shade700,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Optional details field
            TextField(
              controller: _detailsController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: _kReportDetails,
                hintText: _kReportDetailsHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(_kReportCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_selectedReasonKey != null && !_isSubmitting)
                        ? _submit
                        : null,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, size: 16),
                    label: const Text(_kReportSubmit),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper: show the report sheet from any context
// ---------------------------------------------------------------------------
void showReportSheet(
  BuildContext context, {
  required String postId,
  required String reporterProfileId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        ReportPostSheet(postId: postId, reporterProfileId: reporterProfileId),
  );
}

// ---------------------------------------------------------------------------
// Quick-action button widget — attach to every status card
// ---------------------------------------------------------------------------
Widget buildReportButton(
  BuildContext context, {
  required String postId,
  required String reporterProfileId,
}) {
  return TextButton.icon(
    onPressed: () => showReportSheet(
      context,
      postId: postId,
      reporterProfileId: reporterProfileId,
    ),
    icon: const Icon(Icons.flag_outlined, size: 14, color: Colors.red),
    label: const Text(
      _kReportButtonLabel,
      style: TextStyle(fontSize: 12, color: Colors.red),
    ),
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );
}
