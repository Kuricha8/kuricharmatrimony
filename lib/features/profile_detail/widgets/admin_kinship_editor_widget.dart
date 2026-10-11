import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/models.dart';

import '../../../../core/kurichiyar_clan_engine.dart';
import '../../clan_feed/tharavadu_list.dart';
import '../../../../core/services/firebase_firestore_service.dart';

class AdminKinshipEditorWidget extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onUpdated;

  const AdminKinshipEditorWidget({
    super.key,
    required this.profile,
    required this.onUpdated,
  });

  @override
  State<AdminKinshipEditorWidget> createState() =>
      _AdminKinshipEditorWidgetState();
}

class _AdminKinshipEditorWidgetState extends State<AdminKinshipEditorWidget> {
  int? _motherClanId;
  int? _fatherClanId;
  bool _allowScreenshot = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _motherClanId = widget.profile.motherClanId > 0
        ? widget.profile.motherClanId
        : null;
    _fatherClanId = widget.profile.fatherClanId > 0
        ? widget.profile.fatherClanId
        : null;
    _allowScreenshot = widget.profile.allowScreenshot;
  }

  Future<void> _saveAndRecalculate() async {
    if (_motherClanId == null || _fatherClanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both Mother and Father Tharavadu'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final motherClan = getClanById(_motherClanId!);
      final fatherClan = getClanById(_fatherClanId!);

      final motherMoiety = motherClan != null
          ? KurichiyarClanEngine.getMoiety(motherClan.name)
          : 'unknown';
      final fatherMoiety = fatherClan != null
          ? KurichiyarClanEngine.getMoiety(fatherClan.name)
          : 'unknown';

      // Check Kinship forbidden Panthi overlap
      final bool isKinshipIncompatible =
          (motherMoiety.toLowerCase() == fatherMoiety.toLowerCase());
      final String kinshipStatus = isKinshipIncompatible
          ? 'incompatible'
          : 'compatible';

      // Assign room
      String assignedRoom = 'room_1';
      final isRemarriage = widget.profile.maritalStatus != MaritalStatus.first;

      if (isRemarriage && isKinshipIncompatible) {
        assignedRoom = 'room_4';
      } else if (!isRemarriage && isKinshipIncompatible) {
        assignedRoom = 'room_3';
      } else if (isRemarriage && !isKinshipIncompatible) {
        assignedRoom = 'room_2';
      } else if (!isRemarriage && !isKinshipIncompatible) {
        assignedRoom = 'room_1';
      }

      // Update Firestore
      final Map<String, dynamic> updateData = {
        'mother_tharavadu_id': _motherClanId.toString(),
        'father_tharavadu_id': _fatherClanId.toString(),
        'assigned_room': assignedRoom,
        'kinship_status': kinshipStatus,
        'allowScreenshot': _allowScreenshot,
        'allow_screenshot': _allowScreenshot,
        'screenshot_blocked': !_allowScreenshot,
      };

      await FirestoreService().saveUserProfile(widget.profile.id, updateData);

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.profile.id)
            .set({
              'allowScreenshot': _allowScreenshot,
              'allow_screenshot': _allowScreenshot,
              'screenshot_blocked': !_allowScreenshot,
            }, SetOptions(merge: true));
      } catch (_) {}

      try {
        await Supabase.instance.client
            .from('kurichiyar_profiles')
            .update({'allow_screenshot': _allowScreenshot})
            .eq('id', widget.profile.id);
      } catch (_) {}

      // Optionally, cancel/flag pending match deals or open chats if incompatible
      if (isKinshipIncompatible) {
        // Find match deals involving this user and bundle updates in a single atomic WriteBatch
        final deals = await FirebaseFirestore.instance
            .collection('match_deals')
            .where('status', isEqualTo: 'AWAITING_PAYMENT')
            .limit(20)
            .get(const GetOptions(source: Source.serverAndCache));
        final batch = FirebaseFirestore.instance.batch();
        bool hasBatchUpdates = false;

        for (var doc in deals.docs) {
          final data = doc.data();
          if (data['from_user'] == widget.profile.id ||
              data['to_user'] == widget.profile.id) {
            batch.update(doc.reference, {
              'status': 'CANCELLED_KINSHIP_INVALID',
              'updated_at': FieldValue.serverTimestamp(),
            });
            hasBatchUpdates = true;
          }
        }

        if (hasBatchUpdates) {
          await batch.commit();
        }
      }

      // Also update Supabase for consistency if necessary
      await Supabase.instance.client
          .from('kurichiyar_profiles')
          .update({
            'mother_clan_id': _motherClanId,
            'father_clan_id': _fatherClanId,
            'mother_tharavadu': motherClan?.name,
            'father_tharavadu': fatherClan?.name,
            'assigned_room': assignedRoom,
            'kinship_status': kinshipStatus,
          })
          .eq('id', widget.profile.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kinship & Rooms updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating: \$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.orange.shade50,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Admin: Kinship Correction',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _motherClanId,
              decoration: const InputDecoration(
                labelText: "Mother's Tharavadu",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: allClans.where((c) => c.isActive && c.id != 9999).map((c) {
                return DropdownMenuItem<int>(
                  value: c.id,
                  child: Text(c.displayLabel, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _motherClanId = val);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _fatherClanId,
              decoration: const InputDecoration(
                labelText: "Father's Tharavadu",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: allClans.where((c) => c.isActive && c.id != 9999).map((c) {
                return DropdownMenuItem<int>(
                  value: c.id,
                  child: Text(c.displayLabel, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _fatherClanId = val);
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(
                Icons.screenshot_outlined,
                color: Colors.deepOrange,
              ),
              title: const Text(
                'Allow Screenshot',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: const Text(
                'Allow authenticated members to take screenshots of this profile (Guests are ALWAYS blocked)',
                style: TextStyle(fontSize: 12),
              ),
              value: _allowScreenshot,
              onChanged: (val) {
                setState(() => _allowScreenshot = val);
              },
              activeThumbColor: Colors.deepOrange,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _isSaving
                      ? 'Processing...'
                      : 'Save & Re-calculate Kinship & Rooms',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _isSaving ? null : _saveAndRecalculate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
