import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import '../../core/services/rewarded_ad_service.dart';
import 'checker_widget.dart';
export 'checker_widget.dart';

class MoietyCheckerScreen extends StatefulWidget {
  final bool isGuest;
  const MoietyCheckerScreen({super.key, this.isGuest = false});

  @override
  State<MoietyCheckerScreen> createState() => _MoietyCheckerScreenState();
}

class _MoietyCheckerScreenState extends State<MoietyCheckerScreen> {
  int _expandedFaqIndex = -1;
  List<UserProfile> _allMemberProfiles = [];
  bool _isLoadingProfiles = true;
  int _bonusPoints = 0;

  final List<Map<String, String>> _recentChecks = [
    {
      'pair': 'നെല്ലരി തറവാട് (പന്തി) ↔ തോട്ടോളി തറവാട് (ബന്ധു)',
      'result': 'അനുയോജ്യം (Compatible)',
      'status': 'pass',
    },
    {
      'pair': 'ചാത്തോത്ത് തറവാട് (പന്തി) ↔ മരടിയൻ തറവാട് (പന്തി)',
      'result': 'അനുയോജ്യമല്ല (Same Moiety)',
      'status': 'fail',
    },
    {
      'pair': 'വടകര തറവാട് (ബന്ധു) ↔ നെല്ലരി തറവാട് (പന്തി)',
      'result': 'അനുയോജ്യം (Compatible)',
      'status': 'pass',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchMemberProfiles();
    RewardedAdService.instance.loadAd();
  }

  Future<void> _fetchMemberProfiles() async {
    try {
      final res = await Supabase.instance.client
          .from('kurichiyar_profiles')
          .select('*')
          .eq('is_profile_hidden', false)
          .order('id', ascending: false)
          .limit(100);

      List<UserProfile> profiles = (res as List).map((row) {
        return UserProfile.fromMap(row as Map<String, dynamic>);
      }).toList();

      if (profiles.isEmpty) {
        profiles = MockData().profiles;
      }

      if (mounted) {
        setState(() {
          _allMemberProfiles = profiles;
          _isLoadingProfiles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allMemberProfiles = MockData().profiles;
          _isLoadingProfiles = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'പൊരുത്തം പരിശോധന (Moiety Checker)',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A) Daily Family/Tharavadu Proverb Card
                  _buildDailyProverbCard(),
                  const SizedBox(height: 20),

                  // D) Community News / Announcement Banner Slider
                  _buildCommunityBannerSlider(),
                  const SizedBox(height: 20),

                  // Main interactive checker widget with All 4 Lineage Options
                  CheckerWidget(isGuest: widget.isGuest),
                  const SizedBox(height: 24),

                  // Collapsible User Profiles Section (Old & New Registered Profiles)
                  _buildCollapsibleProfilesSection(),
                  const SizedBox(height: 24),

                  // Google AdMob Video Ads Container (Fill empty space)
                  _buildVideoAdContainer(),
                  const SizedBox(height: 24),

                  // B) Trending / Recently Checked Matches Section
                  _buildRecentMatchesSection(),
                  const SizedBox(height: 24),

                  // C) Quick Guide & Interactive FAQ Accordion Box
                  _buildFaqAccordion(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsibleProfilesSection() {
    final profilesToDisplay = _allMemberProfiles.isEmpty
        ? MockData().profiles
        : _allMemberProfiles;
    final newProfiles = profilesToDisplay.take(3).toList();
    final oldProfiles = profilesToDisplay.skip(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: ExpansionTile(
        iconColor: Colors.amber,
        collapsedIconColor: Colors.white70,
        leading: const Icon(Icons.people_alt_outlined, color: Colors.amber),
        title: const Text(
          'അംഗങ്ങളുടെ പ്രൊഫൈലുകൾ (Member Profiles)',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: const Text(
          'പഴയതും പുതിയതുമായ പ്രൊഫൈലുകൾ കാണാൻ വികസിപ്പിക്കുക',
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoadingProfiles)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  )
                else ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.fiber_new,
                          color: Colors.greenAccent,
                          size: 22,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'പുതിയ പ്രൊഫൈലുകൾ (New Registered Profiles)',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...newProfiles.map((p) => _buildProfileItem(p, isNew: true)),

                  const Divider(color: Colors.white24, height: 20),

                  // Old Member Profiles Section
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(Icons.verified, color: Colors.amber, size: 18),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'പഴയ പ്രൊഫൈലുകൾ (Established Member Profiles)',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...oldProfiles.map((p) => _buildProfileItem(p, isNew: false)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(UserProfile profile, {required bool isNew}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: profile.photoUrl.isNotEmpty
                ? NetworkImage(profile.photoUrl)
                : null,
            child: profile.photoUrl.isEmpty
                ? Text(
                    profile.name.isNotEmpty ? profile.name[0] : 'U',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${profile.name}, ${profile.age}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isNew
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isNew ? 'NEW' : 'VERIFIED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isNew ? Colors.greenAccent : Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Gender: ${profile.gender.name.toUpperCase()}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProverbCard() {
    return ListenableBuilder(
      listenable: MockData(),
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5C3E00), Color(0xFF8B6B1B)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.amber,
                radius: 22,
                child: Icon(
                  Icons.format_quote_rounded,
                  color: Color(0xFF5C3E00),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ഇന്നത്തെ തറവാട് ചൊല്ല് (Daily Family Proverb)',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      MockData().dailyProverb,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommunityBannerSlider() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: PageView(
        physics: const BouncingScrollPhysics(),
        children: [
          _buildBannerSlide(
            icon: Icons.campaign,
            title: 'സമുദായ വാർത്തകൾ (Community News)',
            subtitle:
                'കുറിച്ച്യർ മഹാസഭയുടെ വാർഷിക പൊതുയോഗം ഈ മാസം 25-ന് നടക്കും.',
            badgeColor: Colors.amber,
          ),
          _buildBannerSlide(
            icon: Icons.stars,
            title: 'പ്രത്യേക അറിയിപ്പ് (Announcement)',
            subtitle:
                '57 തറവാടുകളിലെയും അംഗങ്ങൾക്കായി ഇല്ലപ്പൊരുത്ത സഹായി പൂർണ്ണ സജ്ജമാണ്.',
            badgeColor: Colors.cyanAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSlide({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: badgeColor.withValues(alpha: 0.2),
            child: Icon(icon, color: badgeColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoAdContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ADMOB VIDEO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'സ്പോൺസേർഡ് വീഡിയോ പരസ്യം (Video Ad)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.play_circle_fill,
                      color: Colors.pinkAccent,
                      size: 52,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Loading Google AdMob Rewarded Video Ad...',
                          ),
                          backgroundColor: Colors.pinkAccent,
                        ),
                      );
                      RewardedAdService.instance.showAdIfAvailable(
                        onRewardEarned: () {
                          if (mounted) {
                            setState(() {
                              _bonusPoints += 50;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '🎉 Congratulations! 50 bonus match points granted successfully!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        onAdFailed: () {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ad is not available yet. Please try again in a moment.',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Watch AdMob Video for Reward Points\nPoints Earned: $_bonusPoints',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMatchesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.greenAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Trending / Recent Match Checks',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._recentChecks.map((item) {
            final isPass = item['status'] == 'pass';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isPass ? Icons.check_circle : Icons.cancel,
                    color: isPass ? Colors.greenAccent : Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['pair']!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  Text(
                    item['result']!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPass ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFaqAccordion() {
    final faqs = [
      {
        'q': 'എന്താണ് പന്തിയും (Pandi) ബന്ധുവും (Bandhu)?',
        'a':
            'കുറിച്ച്യർ സമുദായത്തിലെ 57 തറവാടുകൾ പന്തി, ബന്ധു എന്നീ രണ്ട് പ്രധാന ഇല്ലങ്ങളായി തിരിച്ചിരിക്കുന്നു. ഒരു ഇല്ലത്തിലെ അംഗം മറ്റേ ഇല്ലത്തിലെ അംഗത്തെ മാത്രമേ വിവാഹം കഴിക്കാൻ പാടുള്ളൂ (Exogamy Rule).',
      },
      {
        'q':
            'വരന്റെയും വധുവിന്റെയും അമ്മയുടെയും അച്ഛന്റെയും തറവാടുകൾ പരിശോധിക്കേണ്ടതുണ്ടോ?',
        'a':
            'അതെ, പൂർണ്ണ പൊരുത്ത കൃത്യതയ്ക്കായി അമ്മയുടെ തറവാടുകൾ വ്യത്യസ്ത ഇല്ലങ്ങളിൽ നിന്നുള്ളവരായിരിക്കണം. കൂടാതെ അച്ഛന്റെ തറവാടും പാരമ്പര്യമായി പരിശോധിക്കപ്പെടുന്നു.',
      },
      {
        'q': 'ഒരേ ഇല്ലക്കാർ തമ്മിൽ വിവാഹം കഴിച്ചാൽ എന്ത് സംഭവിക്കും?',
        'a':
            'പരമ്പരാഗത നിയമപ്രകാരം ഒരേ ഇല്ലക്കാർ (Pandi ↔ Pandi / Bandhu ↔ Bandhu) സഹോദരസ്ഥാനത്തുള്ളവരായതിനാൽ വിവാഹം അനുവദനീയമല്ല.',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Quick Guide & FAQ Box',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...faqs.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isExpanded = _expandedFaqIndex == idx;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ExpansionTile(
                key: Key('faq_$idx'),
                initiallyExpanded: isExpanded,
                onExpansionChanged: (exp) {
                  setState(() {
                    _expandedFaqIndex = exp ? idx : -1;
                  });
                },
                iconColor: Colors.amber,
                collapsedIconColor: Colors.white70,
                title: Text(
                  item['q']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      item['a']!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
