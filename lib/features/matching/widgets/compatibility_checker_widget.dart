import 'package:flutter/material.dart';
import '../../clan_feed/tharavadu_list.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/universal_tharavadu_dropdown.dart';

class CompatibilityCheckerWidget extends StatefulWidget {
  const CompatibilityCheckerWidget({super.key});

  @override
  State<CompatibilityCheckerWidget> createState() =>
      _CompatibilityCheckerWidgetState();
}

class _CompatibilityCheckerWidgetState
    extends State<CompatibilityCheckerWidget> {
  String? _myTharavadu;
  String? _partnerTharavadu;
  String? _compatibilityResult;
  bool? _isCompatible;

  @override
  void initState() {
    super.initState();
    TharavaduService.instance.syncClans();
  }

  void _checkCompatibility() {
    if (_myTharavadu == null || _partnerTharavadu == null) return;

    final myClan = getClanByName(_myTharavadu!);
    final partnerClan = getClanByName(_partnerTharavadu!);

    if (myClan == null || partnerClan == null) {
      setState(() {
        _isCompatible = false;
        _compatibilityResult =
            'തറവാട് വിവരം കണ്ടെത്താനായില്ല. വീണ്ടും ശ്രമിക്കുക.';
      });
      return;
    }

    final bool compatible = myClan.groupName != partnerClan.groupName;
    final String message = compatible
        ? 'പൊരുത്തം ഉണ്ട്! (Yes Match ✅)'
        : 'തറവാട് പൊരുത്തമില്ല! ഒരേ മാതൃഗോത്രത്തിൽ പെട്ടവർ തമ്മിലുള്ള വിവാഹം സമുദായ ആചാരങ്ങൾക്ക് വിരുദ്ധമാണ്.';

    setState(() {
      _isCompatible = compatible;
      _compatibilityResult = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UniversalTharavaduDropdown(
          label: AppLocalizations.of(context)!.yourTharavadu,
          selectedValue: _myTharavadu,
          onChanged: (val) => setState(() {
            _myTharavadu = val;
            _compatibilityResult = null;
          }),
        ),
        const SizedBox(height: 12),
        UniversalTharavaduDropdown(
          label: AppLocalizations.of(context)!.partnerTharavadu,
          selectedValue: _partnerTharavadu,
          onChanged: (val) => setState(() {
            _partnerTharavadu = val;
            _compatibilityResult = null;
          }),
        ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: (_myTharavadu != null && _partnerTharavadu != null)
                  ? _checkCompatibility
                  : null,
              icon: const Icon(Icons.compare_arrows),
              label: const Text('Check Compatibility'),
            ),
            if (_compatibilityResult != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _isCompatible == true ? Icons.check_circle : Icons.error,
                      color: _isCompatible == true ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _compatibilityResult!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1E1E1E),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
  }
}
