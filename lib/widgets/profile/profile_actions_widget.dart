import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/models.dart';
import '../../features/clan_feed/tharavadu_list.dart';
import '../../core/utils/legal_strings.dart';
import '../../core/widgets/app_footer.dart';

class ProfileActionsWidget extends StatefulWidget {
  final UserProfile me;
  final String grievanceEmail;
  final VoidCallback onLoggedOut;
  final Function(UserProfile) onProfileUpdated;

  const ProfileActionsWidget({
    super.key,
    required this.me,
    required this.grievanceEmail,
    required this.onLoggedOut,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileActionsWidget> createState() => _ProfileActionsWidgetState();
}

class _ProfileActionsWidgetState extends State<ProfileActionsWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Direct Message Privacy Toggle Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Allow Direct Messages from Matches',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'പൊരുത്തപ്പെടുന്നവരിൽ നിന്നുള്ള നേരിട്ടുള്ള സന്ദേശങ്ങൾ അനുവദിക്കുക',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.me.allowDirectMessages,
                  onChanged: (bool value) async {
                    await Supabase.instance.client
                        .from('kurichiyar_profiles')
                        .update({'allow_direct_messages': value})
                        .eq('id', widget.me.id);
                    final updatedMe = widget.me.copyWith(
                      allowDirectMessages: value,
                    );
                    widget.onProfileUpdated(updatedMe);
                  },
                  activeThumbColor: const Color(0xFF000080),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Profile Visitors (Traffic) Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.remove_red_eye_outlined,
                            size: 18,
                            color: Color(0xFF000080),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'പ്രൊഫൈൽ സന്ദർശകർ (Recent Visitors)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF000080).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.me.visitors.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.me.visitors.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Center(
                      child: Text(
                        'സന്ദർശകർ ആരും ലഭ്യമല്ല.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.me.visitors.length,
                      itemBuilder: (context, index) {
                        final visitor = widget.me.visitors[index];
                        final clan = getClanById(visitor.visitorClanId);
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage:
                                    visitor.visitorPhotoUrl.startsWith('http')
                                    ? NetworkImage(visitor.visitorPhotoUrl)
                                    : const AssetImage(
                                            'assets/images/default_avatar.png',
                                          )
                                          as ImageProvider,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                visitor.visitorName.split(' ')[0],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                clan?.tharavadName ?? 'Tharavadu',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Policy Links Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.gavel, color: Color(0xFF000080)),
                title: const Text(
                  'പ്രയോഗ നിബന്ധനകൾ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => openTermsPage(context),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(
                  Icons.privacy_tip_outlined,
                  color: Color(0xFF000080),
                ),
                title: const Text(
                  'സ്വകാര്യതാ നയം',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => openPrivacyPage(context),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(
                  Icons.currency_rupee,
                  color: Color(0xFF000080),
                ),
                title: const Text(
                  'റിഫണ്ട് നയം',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => openRefundPage(context),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.support_agent, color: Colors.red),
                title: const Text(
                  'പരാതി പരിഹാര ഉദ്യോഗസ്ഥൻ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                subtitle: Text(
                  kGrievanceDescription,
                  style: const TextStyle(fontSize: 11, height: 1.4),
                ),
                trailing: const Icon(
                  Icons.email_outlined,
                  color: Colors.red,
                  size: 18,
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ഇ-മെയിൽ: ${widget.grievanceEmail}'),
                      backgroundColor: Colors.red.shade700,
                      action: SnackBarAction(
                        label: 'Copy',
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Boost Profile Button Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (widget.me.isVip) {
                      Supabase.instance.client.from('clan_posts').insert({
                        'author_id': widget.me.id,
                        'content': 'Check out my matrimonial profile!',
                        'clan_id': widget.me.fatherClanId,
                        'post_type': 'promotion',
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '🎉 VIP Boost Active: Profile promoted to top of Feed!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '🔒 Premium Plan required to boost your profile.',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    widget.me.isVip ? Icons.bolt : Icons.lock,
                    color: widget.me.isVip ? Colors.amber : Colors.white70,
                  ),
                  label: Text(
                    widget.me.isVip
                        ? 'Boost Profile to top of Feed'
                        : 'Boost Profile (Premium Only)',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.me.isVip
                        ? const Color(0xFF000080)
                        : Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Log Out Button
        OutlinedButton.icon(
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();
            widget.onLoggedOut();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Log Out Profile'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 24),
        const AppFooter(),
        const SizedBox(height: 24),
      ],
    );
  }
}
