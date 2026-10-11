import 'package:flutter/material.dart';
import '../services/legal_service.dart';

// ---------------------------------------------------------------------------
// Kurichiyar Matrimony — Central Malayalam Legal String Asset Database
// All visible legal/policy UI text injected as raw Unicode constants.
// ---------------------------------------------------------------------------

// ── Terms & Conditions ──────────────────────────────────────────────────────

const kTcMenuLabel = 'പ്രയോഗ നിബന്ധനകൾ';

const kTcSections = [
  LegalSection(
    heading: '1. അംഗത്വം',
    body:
        'ഈ App-ൽ സേവനങ്ങൾ കുറിച്യ സമുദായത്തിലെ '
        'അംഗങ്ങൾക്ക് മാത്രമായി പരിമിതപ്പെടുത്തിയിരിക്കുന്നു. '
        'രജിസ്റ്റർ ചെയ്യുമ്പോൾ നൽകുന്ന വിവരങ്ങൾ '
        'സത്യസന്ധമായിരിക്കണം.',
  ),
  LegalSection(
    heading: '2. വരിസംഖ്യയും ഫീസും',
    body:
        'App-ൽ Premium Features ഉപയോഗിക്കുന്നതിനായി '
        'ഈടാക്കുന്ന വരിസംഖ്യയും, അതോടൊപ്പം വരുന്ന '
        'Processing Fee-ഉം (Convenience Fee) ഉപയോക്താവ് '
        'പൂർണ്ണ സമ്മതത്തോടെ അടക്കുന്നതാണ്.',
  ),
  LegalSection(
    heading: '3. പെരുമാറ്റ ചട്ടം',
    body:
        'തറവാടു Status Feed-ൽ മറ്റ് വ്യക്തികളെ '
        'അഹിഷേകിക്കുന്ന രീതിയിലുള്ള എഴുത്തുകൾ, ചിത്രങ്ങൾ, '
        'അല്ലെങ്കിൽ വിഡിയോകൾ Post ചെയ്യാൻ പാടില്ല. '
        'നിയമ വിരുദ്ധമായ ഉൾഡാക്കങ്ങൾ Post ചെയ്‌താൽ '
        'Profile യാതൊരുവിധ മുൻ‌നരിയിപ്പും കൂടാതെ '
        'റദ്ദ് ആക്കുന്നതാണ്.',
  ),
  LegalSection(
    heading: '4. ഉത്തരകവിത്വം',
    body:
        'ഉബയോക്താക്കൾ Upload ചെയ്യുന്ന Media Files-ന്റെ '
        'പൂർണ്ണ ഉത്തരവദിത്വം അവർക്ക് മാത്രമായിരിക്കും.',
  ),
];

// ── Privacy Policy ───────────────────────────────────────────────────────────

const kPrivacyMenuLabel = 'സ്വകാര്യതാ നയം';

const kPrivacySections = [
  LegalSection(
    heading: '1. വിവര ശേഖരണം',
    body:
        'ഉബയോക്താവിന്റെ പേര്, Phone Number, തറവാട് '
        'വിവരങ്ങൾ, Profile ചിത്രങ്ങൾ എന്നിവ സുരക്ഷിതമായ '
        'Database-ൽ മാത്രമേ സൂക്ഷിക്കുകയുള്ളൂ.',
  ),
  LegalSection(
    heading: '2. അജ്ഞാതത്വം (Anonymity)',
    body:
        'തറവാടു Status Feed-ൽ നിങ്ങളുടെ പേരോ Phone '
        'Numbero മറ്റ് ഉബയോക്താക്കൾക്ക് ദൃശ്യമാകില്ല. '
        'അവിടെ നിങ്ങളുടെ തറവാടിന്റെ പൊതുവായ Icon '
        'മാത്രമേ കാണിക്കൂ.',
  ),
  LegalSection(
    heading: '3. Data സുരക്ഷ',
    body:
        'നിങ്ങളുടെ അനുവദം ഇല്ലാതെ Phone Numbero '
        'മറ്റ് വ്യക്തിഗതം വിവരങ്ങൾ മൂന്നാമതൊരു '
        'കക്ഷിക്ക് കൈമാറ്റം ആകില്ല.',
  ),
  LegalSection(
    heading: '4. കാലവധി',
    body:
        'നിങ്ങൾ Post ചെയ്യുന്ന Statuses 48 '
        'മണിക്കൂറിനുള്ളിൽ Database-ൽ നിന്നും '
        'പൂർണ്ണമായി ഇല്ലാതാക്കപ്പെടും.',
  ),
];

// ── Refund Policy ────────────────────────────────────────────────────────────

const kRefundMenuLabel = 'റിഫണ്ട് നയം';

const kRefundSections = [
  LegalSection(
    heading: '1. സേവന വരിസംഖ്യ',
    body:
        'App-ൽ വിജയകരമായി അടച്ച Subscription തുക '
        'യാതൊരു കാരണത്താലും തിരിക്ക് നൽകുന്നതല്ല '
        '(Non-refundable).',
  ),
  LegalSection(
    heading: '2. പരാജരപ്പെട്ട Payments',
    body:
        'Payment നടത്തുമ്പോൾ തുക Bank-ൽ നിന്നും '
        'കുറയുകയും App-ൽ Plan Active ആകാതിരിക്കുകയും '
        'ചെയ്‌താൽ, പ്രസ്‌തുത തുക Razorpay '
        'നിയമങ്ങൾക്കനുസരിച്ച് 5–7 പ്രവൃത്തി '
        'ദിനങ്ങൾക്കുള്ളിൽ നിങ്ങളുടെ Account-ലേക്ക് '
        'തിരിക്ക് എത്തുന്നതാണ്.',
  ),
];

// ── Grievance officer ────────────────────────────────────────────────────────

const kGrievanceMenuLabel = 'പരാതി പരിഹാര ഉദ്യോഗസ്ഥൻ';

const kGrievanceDescription =
    'ഏതെങ്കിലും പ്രശ്‌നത്തിനോ പരാതിക്കോ, '
    'ദയവായി ഞങ്ങളുടെ അഡ്‌മിൻ ടീമിനെ '
    'ഇ-മെയിൽ വഴി ബന്ധപ്പെടുക. '
    '24 മണിക്കൂറിനുള്ളിൽ മറുപടി ലഭിക്കും.';

// ---------------------------------------------------------------------------
// Internal model
// ---------------------------------------------------------------------------
class LegalSection {
  final String heading;
  final String body;
  const LegalSection({required this.heading, required this.body});
}

// ---------------------------------------------------------------------------
// LegalPolicyPage — reusable scrollable legal document viewer
// ---------------------------------------------------------------------------
class LegalPolicyPage extends StatefulWidget {
  final String title;
  final String documentType;

  const LegalPolicyPage({
    super.key,
    required this.title,
    required this.documentType,
  });

  @override
  State<LegalPolicyPage> createState() => _LegalPolicyPageState();
}

class _LegalPolicyPageState extends State<LegalPolicyPage> {
  final _legalService = LegalService();
  late Future<List<LegalSection>> _sectionsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Default to 'ml' if locale not set, since the app is Malayalam first
    final langCode = Localizations.localeOf(context).languageCode;
    _sectionsFuture = _legalService.fetchLegalSections(
      widget.documentType,
      langCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<LegalSection>>(
        future: _sectionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final local = _legalService.getLocalFallback(widget.documentType);
            if (local.isNotEmpty) return _buildListView(local);
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final sections = snapshot.data ?? [];
          if (sections.isEmpty) {
            final local = _legalService.getLocalFallback(widget.documentType);
            if (local.isNotEmpty) return _buildListView(local);
            return const Center(child: Text('No information available.'));
          }

          return _buildListView(sections);
        },
      ),
    );
  }

  Widget _buildListView(List<LegalSection> sections) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sections.length,
      itemBuilder: (context, i) {
        final s = sections[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.heading,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF000080),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.body,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: Colors.black87,
                ),
              ),
              if (i < sections.length - 1) const Divider(height: 32),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Helper: push any legal page
// ---------------------------------------------------------------------------
void openTermsPage(BuildContext context) => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) =>
        const LegalPolicyPage(title: kTcMenuLabel, documentType: 'terms'),
  ),
);

void openPrivacyPage(BuildContext context) => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const LegalPolicyPage(
      title: kPrivacyMenuLabel,
      documentType: 'privacy',
    ),
  ),
);

void openRefundPage(BuildContext context) => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) =>
        const LegalPolicyPage(title: kRefundMenuLabel, documentType: 'refund'),
  ),
);
