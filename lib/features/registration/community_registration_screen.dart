import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/haptic_helper.dart';
import '../../core/widgets/universal_tharavadu_dropdown.dart';

class CommunityRegistrationScreen extends StatefulWidget {
  final String cashfreeOrderId;

  const CommunityRegistrationScreen({super.key, required this.cashfreeOrderId});

  @override
  State<CommunityRegistrationScreen> createState() =>
      _CommunityRegistrationScreenState();
}

class _CommunityRegistrationScreenState
    extends State<CommunityRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  String? selectedGender;
  String? selectedMaritalStatus;
  String? selectedSelfClan; // അമ്മയുടെ തറവാട് (Maternal)
  String? selectedFatherClan; // അച്ഛന്റെ തറവാട് (Paternal)
  bool _isSubmitting = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  DateTime? _selectedDob;


  @override
  void dispose() {
    _nameController.dispose();
    _houseController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedSelfClan == null || selectedFatherClan == null) {
      AppToast.showError(
        context,
        'സ്വന്തം തറവാടും അച്ഛന്റെ തറവാടും തിരഞ്ഞെടുക്കുക.',
      );
      return;
    }
    if (selectedSelfClan == selectedFatherClan) {
      AppToast.showWarning(
        context,
        'അമ്മയുടെയും അച്ഛന്റെയും തറവാട് ഒരേപോലെയാകാൻ പാടില്ല.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticHelper.mediumImpact();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id ?? 'usr_${DateTime.now().millisecondsSinceEpoch}';

      // Insert into users_core
      await Supabase.instance.client.from('users_core').upsert({
        'id': userId,
        'phone_number': _phoneController.text.isNotEmpty
            ? _phoneController.text.trim()
            : (user?.phone ?? '9000000000'),
        'full_name': _nameController.text.trim(),
        'gender': selectedGender ?? 'male',
        'dob': (_selectedDob ?? DateTime(1995, 1, 1)).toIso8601String().split(
          'T',
        )[0],
        'marital_status': selectedMaritalStatus ?? 'unmarried',
        'is_community_member': true,
        'is_lifetime_paid': true,
        'payment_id': widget.cashfreeOrderId,
        'is_approved': false, // Admin pending
      });

      // Insert into admin_verifications queue
      await Supabase.instance.client.from('admin_verifications').upsert({
        'user_id': userId,
        'is_verified': false,
      });

      // Auto-sync directly to Firestore collection ft_members (Family Tree module)
      try {
        final fbUid = FirebaseAuth.instance.currentUser?.uid ?? userId;
        await FirebaseFirestore.instance.collection('ft_members').doc(fbUid).set({
          'uid': fbUid,
          'full_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'gender': selectedGender ?? 'male',
          'dob': (_selectedDob ?? DateTime(1995, 1, 1)).toIso8601String().split('T')[0],
          'house_name': _houseController.text.trim(),
          'panthi_tharavadu': selectedSelfClan ?? '',
          'bandhu_tharavadu': selectedFatherClan ?? '',
          'approval_status': 'pending',
          'source': 'matrimony_auto_sync',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (fsErr) {
        debugPrint('ft_members auto-sync note: $fsErr');
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      HapticHelper.success();
      AppToast.showSuccess(
        context,
        'രജിസ്ട്രേഷൻ വിജയകരമായി അഡ്മിൻ പാനലിലേക്ക് അയച്ചു!',
        'Pending Approval',
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      HapticHelper.error();
      AppToast.showError(context, 'സമർപ്പണം പരാജയപ്പെട്ടു: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              "അംഗത്വ രജിസ്ട്രേഷൻ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF1E3A8A), // Public Hub Blue
            elevation: 0,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // 1. ഫോട്ടോ സെലക്ടർ
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF1E3A8A),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. അടിസ്ഥാന വിവരങ്ങൾ
                  _buildSectionCard(
                    title: "വ്യക്തിഗത വിവരങ്ങൾ",
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "പൂർണ്ണ പേര്",
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'പേര് നൽകുക' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "മൊബൈൽ നമ്പർ",
                          prefixIcon: Icon(Icons.phone_android),
                        ),
                        validator: (val) => val == null || val.length < 10
                            ? 'സാധുവായ ഫോൺ നമ്പർ നൽകുക'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "ലിംഗഭേദം",
                          prefixIcon: Icon(Icons.wc_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "male",
                            child: Text("പുരുഷൻ"),
                          ),
                          DropdownMenuItem(
                            value: "female",
                            child: Text("സ്ത്രീ"),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => selectedGender = val),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "വിവാഹാവസ്ഥ",
                          prefixIcon: Icon(Icons.favorite_outline),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "unmarried",
                            child: Text("അവിവാഹിതൻ / അവിവാഹിത"),
                          ),
                          DropdownMenuItem(
                            value: "married",
                            child: Text("വിവാഹിതൻ / വിവാഹിത"),
                          ),
                          DropdownMenuItem(
                            value: "divorced",
                            child: Text("വിവാഹബന്ധം വേർപെടുത്തിയ വ്യക്തി"),
                          ),
                          DropdownMenuItem(
                            value: "widowed",
                            child: Text("വിധവ / വിധവൻ"),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => selectedMaritalStatus = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. തറവാട് & വംശാവലി (ഓട്ടോ റിലേഷൻ കണക്ഷന് വേണ്ടത്)
                  _buildSectionCard(
                    title: "കുടുംബം & തറവാട് വിവരങ്ങൾ",
                    children: [
                      UniversalTharavaduDropdown(
                        label: "സ്വന്തം തറവാട് (അമ്മയുടെ ശാഖ)",
                        prefixIcon: const Icon(Icons.account_tree_outlined),
                        selectedValue: selectedSelfClan,
                        onChanged: (val) =>
                            setState(() => selectedSelfClan = val),
                      ),
                      const SizedBox(height: 12),
                      UniversalTharavaduDropdown(
                        label: "അച്ഛന്റെ തറവാട്",
                        prefixIcon: const Icon(Icons.family_restroom_outlined),
                        selectedValue: selectedFatherClan,
                        onChanged: (val) =>
                            setState(() => selectedFatherClan = val),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _houseController,
                        decoration: const InputDecoration(
                          labelText: "വീട്ടുപേര്",
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? 'വീട്ടുപേര് നൽകുക'
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 4. സബ്മിറ്റ് ബട്ടൺ
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submitRegistration,
                    child: Text(
                      _isSubmitting
                          ? "സബ്മിറ്റ് ചെയ്യുന്നു..."
                          : "രജിസ്ട്രേഷൻ പൂർത്തിയാക്കുക",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
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

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
}
