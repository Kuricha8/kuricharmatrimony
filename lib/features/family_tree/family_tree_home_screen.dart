import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/widgets/ad_banner_widget.dart';
import '../clan_feed/tharavadu_list.dart';
import 'family_tree_constants.dart';

class FamilyTreeHomeScreen extends StatefulWidget {
  final Map<String, dynamic> memberData;
  const FamilyTreeHomeScreen({super.key, required this.memberData});

  @override
  State<FamilyTreeHomeScreen> createState() => _FamilyTreeHomeScreenState();
}

class _FamilyTreeHomeScreenState extends State<FamilyTreeHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final memberData = widget.memberData;
    final status = memberData['approval_status'] ?? 'pending';
    final isVerified = status == 'verified';
    final name = memberData['full_name'] ?? 'കുടുംബാംഗം';
    final nickname = memberData['nickname']?.toString().trim() ?? '';
    final panthi = memberData['panthi_tharavadu'] ?? '';
    final bandhu = memberData['bandhu_tharavadu'] ?? '';
    final houseName = memberData['house_name'] ?? '';
    final photoUrl = memberData['profile_photo'];
    final phone = memberData['phone'] ?? '';
    final isSingleChild = memberData['is_single_child'] ?? false;
    final siblingPhone = memberData['sibling_phone'];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text(
          'കുടുംബമാല',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF000080),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── MEMBER HEADER CARD ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF000080), Color(0xFF1E3A8A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white24,
                    backgroundImage: photoUrl != null &&
                            photoUrl.toString().isNotEmpty
                        ? NetworkImage(photoUrl.toString())
                        : null,
                    child: photoUrl == null || photoUrl.toString().isEmpty
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (nickname.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade400,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  nickname,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            InkWell(
                              onTap: () => _showEditNicknameDialog(
                                context,
                                memberData['uid']?.toString() ??
                                    getEffectiveUserId(),
                                nickname,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(
                                  nickname.isEmpty
                                      ? Icons.add_circle_outline
                                      : Icons.edit_outlined,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (houseName.isNotEmpty)
                          Text(
                            houseName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isVerified
                                ? Colors.green.withAlpha(200)
                                : Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isVerified
                                ? '✓ അപ്രൂവ് ചെയ്ത അംഗം'
                                : 'പരിശോധനയിലാണ് (Pending)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── STATUS SECTION ───
            if (!isVerified) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.hourglass_top_rounded,
                              color: Colors.amber.shade800,
                              size: 26,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'രജിസ്ട്രേഷൻ പരിശോധനയിലാണ്',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'നിങ്ങൾ നൽകിയ കുടുംബ വിവരങ്ങൾ കുറിച്ച്യർ സമുദായ രേഖകളുമായി പരിശോധിച്ച് ഉറപ്പുവരുത്തുകയാണ്. അപ്രൂവ് ആയ ശേഷം നിങ്ങളുടെ പൂർണ്ണ കുടുംബമാല ഫാമിലി ട്രീ ഇവിടെ ലഭ്യമാകും.',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                        const Divider(height: 24),
                        _buildStepItem(
                          stepNumber: '1',
                          title: 'വിവരങ്ങൾ സമർപ്പിച്ചു',
                          subtitle: 'രജിസ്ട്രേഷൻ പൂർത്തിയായി',
                          isDone: true,
                        ),
                        const SizedBox(height: 12),
                        _buildStepItem(
                          stepNumber: '2',
                          title: isSingleChild
                              ? 'സമുദായ പരിശോധന'
                              : 'കൂടപ്പിറപ്പിന്റെ സ്ഥിരീകരണം',
                          subtitle: isSingleChild
                              ? 'അഡ്മിൻ പരിശോധനയിൽ'
                              : 'കൂടപ്പിറപ്പിന്റെ ഫോണിലേക്ക് അറിയിപ്പ് അയച്ചിട്ടുണ്ട് ($siblingPhone)',
                          isDone: false,
                          isActive: true,
                        ),
                        const SizedBox(height: 12),
                        _buildStepItem(
                          stepNumber: '3',
                          title: 'കുടുംബമാല ആക്റ്റീവ് ആകുന്നു',
                          subtitle: 'സമ്പൂർണ്ണ ഫാമിലി ട്രീ ചാർട്ട് ലഭ്യമാകും',
                          isDone: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              // ─── VERIFIED: FULL FAMILY TREE VISUALIZATION ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'കുടുംബ ശാഖകൾ (Lineage Roots)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000080),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // PANTHI / MOTHER'S ROOT
                        Expanded(
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.purple.shade100,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.purple.shade50,
                                        child: const Icon(
                                          Icons.female,
                                          size: 16,
                                          color: Colors.purple,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'പന്തി (അമ്മ)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    panthi.isNotEmpty
                                        ? (getClanByName(panthi)?.displayName ?? panthi)
                                        : 'രേഖപ്പെടുത്തിയിട്ടില്ല',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // BANDHU / FATHER'S ROOT
                        Expanded(
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.shade100,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.blue.shade50,
                                        child: const Icon(
                                          Icons.male,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'ബന്ധു (അച്ഛൻ)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    bandhu.isNotEmpty
                                        ? (getClanByName(bandhu)?.displayName ?? bandhu)
                                        : 'രേഖപ്പെടുത്തിയിട്ടില്ല',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.account_tree_outlined,
                              size: 48,
                              color: Color(0xFF000080),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'കുടുംബമാല ഫാമിലി ട്രീ ചാർട്ട്',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$name ($houseName)\nപന്തി: $panthi | ബന്ധു: $bandhu',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: Colors.green.shade700,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'സ്ഥിരീകരിച്ച കുടുംബ വിവരങ്ങൾ',
                                    style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ─── QUICK INFO CARD ───
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 1,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF000080),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          phone.isNotEmpty
                            ? 'രജിസ്റ്റർ ചെയ്ത നമ്പർ: $phone'
                            : 'കുറിച്ച്യർ ഗോത്ര പാരമ്പര്യ കുടുംബമാല ഡാറ്റാബേസ്',
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        child: SizedBox(
          height: 55,
          child: AdBannerWidget(),
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required String stepNumber,
    required String title,
    required String subtitle,
    bool isDone = false,
    bool isActive = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isDone
              ? Colors.green
              : isActive
                  ? Colors.amber.shade800
                  : Colors.grey.shade300,
          child: isDone
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text(
                  stepNumber,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : Colors.grey.shade700,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDone || isActive ? Colors.black87 : Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditNicknameDialog(
    BuildContext context,
    String? uid,
    String currentNickname,
  ) {
    final controller = TextEditingController(text: currentNickname);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('വിളിപ്പേര് മാറ്റുക'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'വിളിപ്പേര് (Nickname)',
            hintText: 'ഉദാ: ചിന്നൻ, രാമു',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('റദ്ദാക്കുക'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF000080),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newNickname = controller.text.trim();
              Navigator.pop(ctx);
              if (uid != null && uid.isNotEmpty) {
                try {
                  await FirebaseFirestore.instance
                      .collection('ft_members')
                      .doc(uid)
                      .update({'nickname': newNickname});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('വിളിപ്പേര് വിജയകരമായി അപ്‌ഡേറ്റ് ചെയ്തു'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('സേവ് ചെയ്യുക'),
          ),
        ],
      ),
    );
  }
}
