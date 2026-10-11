import 'package:flutter/material.dart';
import '../../../../core/models/models.dart';
import '../../../registration/widgets/safe_dropdown.dart';

class FamilyRestrictedSection extends StatelessWidget {
  final bool hasFamilyRestriction;
  final ValueChanged<bool?> onRestrictionChanged;
  final List<Clan> uniqueClans;
  final TextEditingController mothersTarawadController;
  final List<Clan> selectedRestrictedFamilies;
  final ValueChanged<Clan> onFamilyRemoved;
  final ValueChanged<Clan?> onFamilyAdded;

  const FamilyRestrictedSection({
    super.key,
    required this.hasFamilyRestriction,
    required this.onRestrictionChanged,
    required this.uniqueClans,
    required this.mothersTarawadController,
    required this.selectedRestrictedFamilies,
    required this.onFamilyRemoved,
    required this.onFamilyAdded,
  });

  InputDecoration _buildInputDecoration(String label, IconData icon) {
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'വിവാഹം കഴിക്കാൻ പാടില്ലാത്ത തറവാടുകൾ ഏതൊക്കെയെന്ന് നിങ്ങൾക്ക് അറിയാമോ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => onRestrictionChanged(true),
                    child: Row(
                      children: [
                        Icon(
                          hasFamilyRestriction
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: hasFamilyRestriction
                              ? const Color(0xFFD4AF37)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Text('Yes'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => onRestrictionChanged(false),
                    child: Row(
                      children: [
                        Icon(
                          !hasFamilyRestriction
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: !hasFamilyRestriction
                              ? const Color(0xFFD4AF37)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Text('No'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (hasFamilyRestriction) ...[
              const SizedBox(height: 16),
              SafeDropdown<String>(
                isExpanded: true,
                initialValue:
                    uniqueClans.any(
                      (c) => c.name == mothersTarawadController.text,
                    )
                    ? mothersTarawadController.text
                    : null,
                items: uniqueClans.map((clan) {
                  return DropdownMenuItem<String>(
                    value: clan.name,
                    child: Text(clan.name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    mothersTarawadController.text = val;
                  }
                },
                decoration: _buildInputDecoration(
                  "Mother's Tarawad",
                  Icons.family_restroom,
                ).copyWith(fillColor: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Restricted Families',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: selectedRestrictedFamilies.map((clan) {
                      return Chip(
                        label: Text(clan.name),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => onFamilyRemoved(clan),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SafeDropdown<int>(
                          isExpanded: true,
                          initialValue: null,
                          hint: const Text('Add a family...'),
                          items: uniqueClans
                              .where(
                                (c) => !selectedRestrictedFamilies.any(
                                  (selected) => selected.id == c.id,
                                ),
                              )
                              .map((clan) {
                                return DropdownMenuItem<int>(
                                  value: clan.id,
                                  child: Text(
                                    clan.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              })
                              .toList(),
                          onChanged: (int? selectedId) {
                            if (selectedId != null) {
                              final match = uniqueClans.firstWhere(
                                (c) => c.id == selectedId,
                              );
                              onFamilyAdded(match);
                            }
                          },
                          decoration: _buildInputDecoration(
                            'Add Restricted Tharavadu',
                            Icons.add,
                          ).copyWith(fillColor: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
