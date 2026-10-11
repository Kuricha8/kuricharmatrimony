import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../clan_feed/tharavadu_list.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const ProfileCompletionScreen({super.key, required this.initialData});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Track which fields are missing
  late bool _needsHeight;
  late bool _needsEducation;
  late bool _needsOccupation;
  late bool _needsFatherClan;
  late bool _needsMotherClan;
  late bool _needsLegal;

  // Controllers & State
  final _heightController = TextEditingController();
  final _educationController = TextEditingController();
  final _occupationController = TextEditingController();
  String? _selectedFatherClan;
  String? _selectedMotherClan;

  bool _legalConsent1 = false;
  bool _legalConsent2 = false;
  bool _legalConsent3 = false;
  bool _legalConsent4 = false;

  List<Map<String, dynamic>> _clans = [];

  @override
  void initState() {
    super.initState();
    TharavaduService.instance.addListener(_onClansUpdated);
    TharavaduService.instance.syncClans(); // Fetch latest from DB
    _checkMissingFields();
  }

  void _onClansUpdated() {
    if (mounted) {
      setState(() {
        final all = allClans;
        _clans = all
            .map((c) => {'id': c.id, 'name': c.name, 'group_name': c.groupName})
            .toList();
      });
    }
  }

  void _checkMissingFields() {
    final data = widget.initialData;
    _needsHeight = data['height_cm'] == null;
    _needsEducation =
        data['highest_education'] == null ||
        data['highest_education'].toString().isEmpty;
    _needsOccupation =
        data['occupation'] == null || data['occupation'].toString().isEmpty;
    _needsFatherClan = data['father_clan_id'] == null;
    _needsMotherClan = data['mother_clan_id'] == null;
    _needsLegal = data['legal_consent_accepted'] != true;

    if (_needsFatherClan || _needsMotherClan) {
      _fetchClans();
    }
  }

  Future<void> _fetchClans() async {
    // Initial fetch from TharavaduService
    _onClansUpdated();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_needsLegal &&
        (!_legalConsent1 ||
            !_legalConsent2 ||
            !_legalConsent3 ||
            !_legalConsent4)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept all legal declarations to proceed.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updates = <String, dynamic>{
        'status': 'pending', // Re-evaluate by admin if previously incomplete
      };

      if (_needsHeight) {
        updates['height_cm'] = int.tryParse(_heightController.text.trim());
      }
      if (_needsEducation) {
        updates['highest_education'] = _educationController.text.trim();
      }
      if (_needsOccupation) {
        updates['occupation'] = _occupationController.text.trim();
      }
      if (_needsFatherClan) {
        updates['father_clan_id'] = _selectedFatherClan;
      }
      if (_needsMotherClan) {
        updates['mother_clan_id'] = _selectedMotherClan;
      }
      if (_needsLegal) {
        updates['legal_consent_accepted'] = true;
      }

      final profileId = widget.initialData['id']?.toString() ?? '';
      if (profileId.isNotEmpty) {
        try {
          updates['updated_at'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance
              .collection('users')
              .doc(profileId)
              .set(updates, SetOptions(merge: true));
          await FirebaseFirestore.instance
              .collection('profiles')
              .doc(profileId)
              .set(updates, SetOptions(merge: true));
        } catch (fsErr) {
          debugPrint('Firestore profile update notice: $fsErr');
        }
      }

      try {
        await Supabase.instance.client
            .from('kurichiyar_profiles')
            .update(updates)
            .eq('id', profileId);
      } catch (sbErr) {
        debugPrint('Supabase profile update notice: $sbErr');
      }

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    TharavaduService.instance.removeListener(_onClansUpdated);
    _heightController.dispose();
    _educationController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If no missing fields were detected (fallback), allow bypass
    if (!_needsHeight &&
        !_needsEducation &&
        !_needsOccupation &&
        !_needsFatherClan &&
        !_needsMotherClan &&
        !_needsLegal) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile Completion')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/dashboard', (route) => false),
            child: const Text('Proceed to Dashboard'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F3),
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false, // Guard screen, no back button
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your profile is marked as incomplete. Please fill out the missing fields below to proceed.',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_needsHeight) ...[
                TextFormField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Height (in cm)'),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
              ],

              if (_needsEducation) ...[
                TextFormField(
                  controller: _educationController,
                  decoration: _inputDecoration('Highest Education'),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
              ],

              if (_needsOccupation) ...[
                TextFormField(
                  controller: _occupationController,
                  decoration: _inputDecoration('Occupation'),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
              ],

              if (_needsFatherClan && _clans.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Father\'s Tharavadu'),
                  items: _clans
                      .map(
                        (c) => DropdownMenuItem(
                          value: c['id'].toString(),
                          child: Text(c['name']),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedFatherClan = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
              ],

              if (_needsMotherClan && _clans.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Mother\'s Tharavadu'),
                  items: _clans
                      .map(
                        (c) => DropdownMenuItem(
                          value: c['id'].toString(),
                          child: Text(c['name']),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedMotherClan = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
              ],

              if (_needsLegal) ...[
                const Text(
                  'Legal Declarations',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _buildLegalCheckbox(
                  'I certify that all details provided (Age, Education, Occupation, Marital Status) are 100% accurate and true.\n(ഈ പ്രൊഫൈലിൽ ഞാൻ നൽകിയിരിക്കുന്ന എല്ലാ വിവരങ്ങളും 100% സത്യസന്ധവും കൃത്യവുമാണെന്ന് ഞാൻ സാക്ഷ്യപ്പെടുത്തുന്നു.)',
                  _legalConsent1,
                  (val) => setState(() => _legalConsent1 = val ?? false),
                ),
                _buildLegalCheckbox(
                  'I agree that verifying the background of profiles found through this app is my sole responsibility.\n(ഈ ആപ്പ് വഴി കണ്ടെത്തുന്ന ആലോചനകളുടെ പശ്ചാത്തലം നേരിട്ട് അന്വേഷിച്ച് ബോധ്യപ്പെടേണ്ടത് എന്റെ മാത്രം ഉത്തരവാദിത്തമാണെന്ന് ഞാൻ സമ്മതിക്കുന്നു.)',
                  _legalConsent2,
                  (val) => setState(() => _legalConsent2 = val ?? false),
                ),
                _buildLegalCheckbox(
                  'I promise not to misuse or misappropriate any data or phone numbers of other members.\n(മറ്റ് അംഗങ്ങളുടെ വിവരങ്ങളോ ഫോൺ നമ്പറോ ഞാൻ ദുരുപയോഗം ചെയ്യുകയോ ദുരുദ്ദേശത്തോടെ ഉപയോഗിക്കുകയോ ഇല്ല എന്ന് ഉറപ്പുനൽകുന്നു.)',
                  _legalConsent3,
                  (val) => setState(() => _legalConsent3 = val ?? false),
                ),
                _buildLegalCheckbox(
                  'I explicitly accept and bind myself to the full Terms & Conditions and Privacy Policy of Kurichiyar Matrimony.\n(കുറിച്ചിയർ മാട്രിമോണിയുടെ ഔദ്യോഗിക നിയമ വ്യവസ്ഥകളും സ്വകാര്യതാ നയങ്ങളും ഞാൻ പൂർണ്ണമായി വായിച്ചു മനസ്സിലാക്കി അംഗീകരിക്കുന്നു.)',
                  _legalConsent4,
                  (val) => setState(() => _legalConsent4 = val ?? false),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Update & Proceed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildLegalCheckbox(
    String title,
    bool value,
    void Function(bool?) onChanged,
  ) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontSize: 13)),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: const Color(0xFF000080),
    );
  }
}
