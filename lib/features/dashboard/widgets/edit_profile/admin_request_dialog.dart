import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/models.dart';
import '../../../clan_feed/tharavadu_list.dart';

class AdminRequestDialog {
  static void show(
    BuildContext context,
    UserProfile user,
    VoidCallback onRefresh,
    TextEditingController nameController,
    TextEditingController dobController,
    Gender? selectedGender,
    int? selectedFatherClanId,
    int? selectedMotherClanId,
  ) {
    String selectedField = 'Full Name';
    final newValueController = TextEditingController();
    String? selectedClanValue;
    String? selectedGenderValue = 'Male';
    String errorMessage = '';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (bottomCtx, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(bottomCtx).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_reset, color: Color(0xFF000080)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'അഡ്മിൻ മാറ്റത്തിനായി അപേക്ഷിക്കുക',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5C3E00),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(bottomCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'തിരുത്താൻ ആഗ്രഹിക്കുന്ന ലോക്ക് ചെയ്ത ഫീൽഡ് തിരഞ്ഞെടുത്ത് പുതിയ വിവരങ്ങൾ നൽകുക.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedField,
                      decoration: _buildInputDecoration(
                        'തിരുത്തേണ്ട ഫീൽഡ് (Field to Edit)',
                        Icons.list,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Full Name',
                          child: Text(
                            'Full Name (മുഴുവൻ പേര്)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Date of Birth & Age',
                          child: Text(
                            'Date of Birth & Age (ജനന തീയതി & വയസ്സ്)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Gender',
                          child: Text(
                            'Gender (ലിംഗം)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Father\'s Tharavad',
                          child: Text(
                            'Father\'s Tharavad (പിതാവിന്റെ തറവാട്)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Mother\'s Tharavad',
                          child: Text(
                            'Mother\'s Tharavad (മാതാവിന്റെ തറവാട്)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedField = val;
                            newValueController.clear();
                            selectedClanValue = null;
                            errorMessage = '';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    if (selectedField == 'Full Name') ...[
                      TextFormField(
                        controller: newValueController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _buildInputDecoration(
                          'പുതിയ പേര് (Proposed Name)',
                          Icons.person,
                        ),
                        onChanged: (_) =>
                            setModalState(() => errorMessage = ''),
                      ),
                    ] else if (selectedField == 'Gender') ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedGenderValue,
                        decoration: _buildInputDecoration(
                          'പുതിയ ലിംഗം (Proposed Gender)',
                          Icons.wc,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedGenderValue = val;
                              errorMessage = '';
                            });
                          }
                        },
                      ),
                    ] else if (selectedField == 'Date of Birth & Age') ...[
                      InkWell(
                        onTap: () async {
                          setModalState(() => errorMessage = '');
                          final picked = await showDatePicker(
                            context: bottomCtx,
                            initialDate: DateTime(1998, 1, 1),
                            firstDate: DateTime(1940),
                            lastDate: DateTime.now().subtract(
                              const Duration(days: 365 * 18),
                            ),
                          );
                          if (picked != null) {
                            setModalState(() {
                              newValueController.text =
                                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                        child: IgnorePointer(
                          child: TextFormField(
                            controller: newValueController,
                            decoration: _buildInputDecoration(
                              'പുതിയ ജനന തീയതി (Select Proposed DOB)',
                              Icons.calendar_today,
                            ),
                          ),
                        ),
                      ),
                    ] else if (selectedField == 'Father\'s Tharavad' ||
                        selectedField == 'Mother\'s Tharavad') ...[
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue:
                            allClans
                                .map((c) => c.name)
                                .toSet()
                                .contains(selectedClanValue)
                            ? selectedClanValue
                            : null,
                        decoration: _buildInputDecoration(
                          'പുതിയ തറവാട് (Proposed Tharavad)',
                          Icons.family_restroom,
                        ),
                        items: allClans.map((c) => c.name).toSet().toList().map(
                          (name) {
                            final c = allClans.firstWhere(
                              (c) => c.name == name,
                            );
                            return DropdownMenuItem(
                              value: c.name,
                              child: Text(
                                c.displayLabel,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedClanValue = val;
                              errorMessage = '';
                            });
                          }
                        },
                      ),
                    ],

                    const SizedBox(height: 12),

                    if (errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    ElevatedButton.icon(
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      label: Text(
                        isSubmitting
                            ? 'സമർപ്പിക്കുന്നു...'
                            : 'അപേക്ഷ സമർപ്പിക്കുക (Submit Request)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000080),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              String finalVal = newValueController.text.trim();
                              if (selectedField == 'Gender') {
                                finalVal = selectedGenderValue ?? 'Male';
                              } else if (selectedField ==
                                      'Father\'s Tharavad' ||
                                  selectedField == 'Mother\'s Tharavad') {
                                finalVal = selectedClanValue ?? '';
                              }

                              if (finalVal.isEmpty) {
                                setModalState(() {
                                  errorMessage =
                                      'ദയവായി പുതിയ വിവരം നൽകുക. (Please provide the new information)';
                                });
                                return;
                              }

                              String oldValue = '';
                              if (selectedField == 'Full Name')
  { oldValue = nameController.text; }
                              if (selectedField == 'Date of Birth & Age')
  { oldValue = dobController.text; }
                              if (selectedField == 'Gender')
  { oldValue = selectedGender?.name ?? ''; }
                              if (selectedField == 'Father\'s Tharavad') {
                                oldValue =
                                    allClans
                                        .cast<Clan?>()
                                        .firstWhere(
                                          (c) =>
                                              c?.id ==
                                              (selectedFatherClanId ?? 0),
                                          orElse: () => null,
                                        )
                                        ?.displayLabel ??
                                    '';
                              }
                              if (selectedField == 'Mother\'s Tharavad') {
                                oldValue =
                                    allClans
                                        .cast<Clan?>()
                                        .firstWhere(
                                          (c) =>
                                              c?.id ==
                                              (selectedMotherClanId ?? 0),
                                          orElse: () => null,
                                        )
                                        ?.displayLabel ??
                                    '';
                              }

                              setModalState(() => isSubmitting = true);
                              try {
                                final currentUserId =
                                    Supabase
                                        .instance
                                        .client
                                        .auth
                                        .currentUser
                                        ?.id ??
                                    user.id;
                                if (currentUserId.isEmpty) {
                                  setModalState(() {
                                    isSubmitting = false;
                                    errorMessage =
                                        'Error: No user session found.';
                                  });
                                  return;
                                }

                                await Supabase.instance.client
                                    .from('profile_edit_requests')
                                    .insert({
                                      'user_id': currentUserId,
                                      'field_name': selectedField,
                                      'old_value': oldValue,
                                      'new_value': finalVal,
                                      'proposed_value': finalVal,
                                      'status': 'pending',
                                    })
                                    .timeout(const Duration(seconds: 5));

                                if (bottomCtx.mounted) {
                                  Navigator.pop(bottomCtx);
                                  onRefresh();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'നിങ്ങളുടെ തിരുത്തൽ അപേക്ഷ അഡ്മിന് സമർപ്പിച്ചു!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (bottomCtx.mounted) {
                                  setModalState(() {
                                    isSubmitting = false;
                                    errorMessage =
                                        'പരാജയപ്പെട്ടു: നിങ്ങളുടെ ടേബിൾ നിലവിലില്ലായിരിക്കാം. SQL സ്ക്രിപ്റ്റ് റൺ ചെയ്തോ? ($e)';
                                  });
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFD4AF37)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
      ),
    );
  }
}
