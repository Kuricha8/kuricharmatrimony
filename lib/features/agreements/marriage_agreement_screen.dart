import 'package:flutter/material.dart';

class MarriageAgreementScreen extends StatefulWidget {
  final String groomName;
  final String brideName;
  final VoidCallback onProceedToPay;

  const MarriageAgreementScreen({
    super.key,
    required this.groomName,
    required this.brideName,
    required this.onProceedToPay,
  }) : super();

  @override
  State<MarriageAgreementScreen> createState() =>
      _MarriageAgreementScreenState();
}

class _MarriageAgreementScreenState extends State<MarriageAgreementScreen> {
  bool _isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('വിവാഹ പ്രതിബദ്ധതാ കരാർ'),
        centerTitle: true,
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF000080).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.handshake,
                    color: Color(0xFF000080),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${widget.groomName} & ${widget.brideName} തമ്മിലുള്ള വിവാഹ ഉറപ്പ് കരാർ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000080),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'നിബന്ധനകളും വ്യവസ്ഥകളും (Terms & Conditions)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildClause(
              '1. പ്രതിബദ്ധതാ ഡെപ്പോസിറ്റ് (Escrow Pool)',
              'വിവാഹ ആലോചന സ്ഥിരീകരിച്ച ശേഷം ഇരുപക്ഷവും തുല്യ തുക (₹7,000 വീതം = ആകെ ₹14,000) പ്ലാറ്റ്‌ഫോം എസ്ക്രോ വാലറ്റിൽ നിക്ഷേപിക്കേണ്ടതാണ്.',
            ),
            _buildClause(
              '2. വിവാഹം നടക്കുമ്പോൾ',
              'വിവാഹം വിജയകരമായി നടന്നു കഴിഞ്ഞാൽ നിക്ഷേപ തുക പ്ലാറ്റ്‌ഫോം ചാർജ്ജ് കിഴിച്ച് ഇരുവർക്കും തിരികെ ലഭിക്കുകയോ തീർപ്പാക്കുകയോ ചെയ്യും.',
            ),
            _buildClause(
              '3. വിവാഹത്തിൽ നിന്നുള്ള അന്യായ പിന്മാറ്റം',
              'കാരണങ്ങളില്ലാതെ ഒരു പക്ഷം മാത്രം വിവാഹത്തിൽ നിന്ന് ഏകപക്ഷീയമായി പിന്മാറിയാൽ, മറുപക്ഷത്തിന്റെ നഷ്ടപരിഹാരത്തിനും മാനസിക പിന്തുണയ്ക്കും ഈ തുക ഉപയോഗിക്കുന്നതാണ്.',
            ),
            _buildClause(
              '4. അഡ്മിൻ തർക്ക പരിഹാരം (Dispute Resolution)',
              'എന്തെങ്കിലും തർക്കങ്ങളുണ്ടായാൽ കുറിച്യർ മാട്രിമോണി അഡ്മിൻ ബോർഡിന്റെയും കാരണവന്മാരുടെയും മധ്യസ്ഥതയിൽ ചർച്ച ചെയ്തു അന്തിമ തീരുമാനം എടുക്കുന്നതാണ്.',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _isAgreed,
                activeColor: const Color(0xFF000080),
                onChanged: (val) => setState(() => _isAgreed = val ?? false),
                title: const Text(
                  'ഞങ്ങൾ മുകളിൽ പറഞ്ഞ എല്ലാ വ്യവസ്ഥകളും വായിച്ചു മനസ്സിലാക്കി പൂർണ്ണ സമ്മതത്തോടെ അംഗീകരിക്കുന്നു.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isAgreed ? widget.onProceedToPay : null,
                icon: const Icon(Icons.payment),
                label: const Text(
                  'തുടർന്നു പണം അടയ്ക്കുക (Proceed to Escrow Pay)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildClause(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF000080),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
