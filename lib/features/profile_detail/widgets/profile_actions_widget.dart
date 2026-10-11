import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/interest_toggle_button.dart';
import '../../../core/services/call_service.dart';
import '../../../core/utils/mock_data.dart';
import '../../calls/secure_audio_call_screen.dart';

class ProfileActionsWidget extends StatelessWidget {
  final UserProfile profile;
  final UserProfile? me;
  final bool isMutualMatch;
  final String? actionFetchError;
  final int actionRowsFetched;
  final List<String> profileMappingErrors;
  final VoidCallback onRetryFetch;
  final VoidCallback onRequestHouseVisit;
  final VoidCallback onCheckMutualMatchStatus;
  final Function(BuildContext, UserProfile) onContactViaAdmin;
  final Function(BuildContext, String) onOneTimePhotoView;

  const ProfileActionsWidget({
    super.key,
    required this.profile,
    required this.me,
    required this.isMutualMatch,
    required this.actionFetchError,
    required this.actionRowsFetched,
    required this.profileMappingErrors,
    required this.onRetryFetch,
    required this.onRequestHouseVisit,
    required this.onCheckMutualMatchStatus,
    required this.onContactViaAdmin,
    required this.onOneTimePhotoView,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (profile.confidentialPhotoUrl != null &&
            profile.confidentialPhotoUrl!.isNotEmpty &&
            me != null &&
            me!.id != profile.id) ...[
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 20.0),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.red.shade50,
            child: ListTile(
              leading: const Icon(Icons.remove_red_eye, color: Colors.red),
              title: const Text(
                'Confidential Photo (One-Time View)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              subtitle: const Text(
                'This photo can only be viewed once. Screenshots are disabled.',
                style: TextStyle(fontSize: 12),
              ),
              trailing: ElevatedButton(
                onPressed: () =>
                    onOneTimePhotoView(context, profile.confidentialPhotoUrl!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('View Now'),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── PROFILE ACTIONS DEBUG & ERROR BANNER ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (actionFetchError != null || profileMappingErrors.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade400, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Profile Action Error Container',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Error: ${actionFetchError ?? profileMappingErrors.join("; ")}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Rows fetched: $actionRowsFetched',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 11,
                        ),
                      ),
                      if (profileMappingErrors.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Mapping Errors:\n${profileMappingErrors.join("\n")}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: onRetryFetch,
                        icon: const Icon(Icons.refresh, size: 14),
                        label: const Text(
                          'Retry Fetch',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Text(
                    'Loaded 1 profile actions successfully (Rows fetched: $actionRowsFetched)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade900,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ADMIN MEDIATOR MODE: If female profile has it ON, show only Contact via Admin
        if (me != null &&
            me!.id != profile.id &&
            profile.gender == Gender.female &&
            profile.adminOnlyMediator)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
            ),
            child: ElevatedButton.icon(
              onPressed: () => onContactViaAdmin(context, profile),
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('അഡ്മിൻ വഴി ബന്ധപ്പെടുക'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          )
        else if (me != null && me!.id != profile.id) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                if (isMutualMatch)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: onRequestHouseVisit,
                      icon: const Icon(Icons.home_work),
                      label: const Text(
                        'വീട് സന്ദർശിക്കാൻ അനുമതി ചോദിക്കുക (Request House Visit)',
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: const Color(0xFF000080),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                InterestToggleButton(
                  targetProfile: profile,
                  onStateChanged: onCheckMutualMatchStatus,
                ),

                const SizedBox(height: 12),

                // ── MEDIATED SAFE CALL BUTTONS ──
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final caller = me ?? MockData().currentUser;
                          final callerId = caller?.id ?? 'user';
                          final callerName = caller?.name ?? 'User';

                          final callId = await CallService.instance
                              .initiateCallSession(
                                callerId: callerId,
                                callerName: callerName,
                                targetUserId: profile.id,
                                targetUserName: profile.name,
                                callType: 'audio',
                              );

                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SecureAudioCallScreen(
                                  currentUserId: callerId,
                                  targetUserId: profile.id,
                                  targetUserName: profile.name,
                                  callId: callId,
                                  callType: 'audio',
                                  isCaller: true,
                                  maxDurationMinutes: 15,
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text(
                          'ഓഡിയോ കോൾ (Audio Call)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF15803D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final caller = me ?? MockData().currentUser;
                          final callerId = caller?.id ?? 'user';
                          final callerName = caller?.name ?? 'User';

                          final callId = await CallService.instance
                              .initiateCallSession(
                                callerId: callerId,
                                callerName: callerName,
                                targetUserId: profile.id,
                                targetUserName: profile.name,
                                callType: 'video',
                              );

                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SecureAudioCallScreen(
                                  currentUserId: callerId,
                                  targetUserId: profile.id,
                                  targetUserName: profile.name,
                                  callId: callId,
                                  callType: 'video',
                                  isCaller: true,
                                  maxDurationMinutes: 15,
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.videocam, size: 18),
                        label: const Text(
                          'വീഡിയോ കോൾ (Video Call)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
