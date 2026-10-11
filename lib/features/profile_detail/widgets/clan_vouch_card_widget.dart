import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/models.dart';
import '../../../core/services/clan_vouch_service.dart';

class ClanVouchCardWidget extends StatefulWidget {
  final UserProfile profile;
  final UserProfile? me;
  final VoidCallback onVouchSubmitted;

  const ClanVouchCardWidget({
    super.key,
    required this.profile,
    required this.me,
    required this.onVouchSubmitted,
  });

  @override
  State<ClanVouchCardWidget> createState() => _ClanVouchCardWidgetState();
}

class _ClanVouchCardWidgetState extends State<ClanVouchCardWidget>
    with SingleTickerProviderStateMixin {
  bool _hasVouched = false;
  bool _isLoading = false;
  bool _isChecking = true;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _checkVouchStatus();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkVouchStatus() async {
    if (widget.me == null) {
      if (mounted) setState(() => _isChecking = false);
      return;
    }

    final hasVouched = await ClanVouchService.instance.hasUserVouched(
      widget.profile.id,
      widget.me!.id,
    );

    if (mounted) {
      setState(() {
        _hasVouched = hasVouched;
        _isChecking = false;
      });
      if (hasVouched) {
        _animController.forward();
      }
    }
  }

  bool _isSameTharavadu() {
    if (widget.me == null) return false;
    final me = widget.me!;
    final profile = widget.profile;

    if (me.id == profile.id) return false; // Can't vouch for oneself

    // Check by tharavadu ID or clean normalized tharavadu name
    if (me.tharavaduId != 0 &&
        profile.tharavaduId != 0 &&
        me.tharavaduId == profile.tharavaduId) {
      return true;
    }

    final myClan = me.tharavaduName.toLowerCase().trim();
    final profileClan = profile.tharavaduName.toLowerCase().trim();

    return myClan.isNotEmpty &&
        profileClan.isNotEmpty &&
        (myClan == profileClan);
  }

  Future<void> _submitVouch() async {
    if (widget.me == null) return;
    setState(() => _isLoading = true);

    HapticFeedback.heavyImpact();

    final success = await ClanVouchService.instance.submitVouch(
      targetProfileId: widget.profile.id,
      currentUser: widget.me!,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasVouched = success;
      });

      if (success) {
        _animController.forward(from: 0.0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.verified, color: Colors.amber, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.me!.isElder
                        ? '🎉 മൂപ്പൻ സാക്ഷ്യപത്രം വിജയകരമായി സമർപ്പിച്ചു!'
                        : '🎉 തറവാട്ട് സാക്ഷ്യപത്രം വിജയകരമായി രേഖപ്പെടുത്തി!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF000080),
            duration: const Duration(seconds: 3),
          ),
        );
        widget.onVouchSubmitted();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSameTharavadu() || _isChecking) {
      return const SizedBox.shrink();
    }

    final isElder = widget.me?.isElder == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _hasVouched
              ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]
              : [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _hasVouched ? Colors.green.shade400 : Colors.amber.shade600,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (_hasVouched ? Colors.green : Colors.amber).withValues(
              alpha: 0.15,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _hasVouched
                      ? Colors.green.shade700
                      : const Color(0xFF5C3E00),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _hasVouched ? Icons.verified : Icons.history_edu_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasVouched
                          ? 'തറവാട്ട് വിശ്വാസമുദ്ര സാക്ഷ്യം'
                          : '📜 തറവാട്ട് തലത്തിൽ സാക്ഷ്യപ്പെടുത്തുക (Clan Vouch)',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: _hasVouched
                            ? Colors.green.shade900
                            : const Color(0xFF5C3E00),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _hasVouched
                          ? 'നിങ്ങൾ ഈ തറവാട് അംഗത്തെ സാക്ഷ്യപ്പെടുത്തിയിട്ടുണ്ട്'
                          : '${widget.profile.tharavaduName} തറവാട്ടിലെ അംഗമെന്ന നിലയിൽ സാക്ഷ്യപ്പെടുത്താം',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _hasVouched
                            ? Colors.green.shade800
                            : Colors.brown.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_hasVouched)
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isElder
                          ? '✅ മൂപ്പൻ സാക്ഷ്യപത്രം സാധുവാണ് (Elder Vouched)'
                          : '✅ തറവാട് അംഗം സാക്ഷ്യപ്പെടുത്തി (Member Vouched)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isElder
                      ? const Color(0xFFB8860B)
                      : const Color(0xFF000080),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: _isLoading ? null : _submitVouch,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isElder ? Icons.workspace_premium : Icons.how_to_reg,
                        size: 18,
                      ),
                label: Text(
                  _isLoading
                      ? 'സാക്ഷ്യപ്പെടുത്തുന്നു...'
                      : (isElder
                            ? '👑 മൂപ്പൻ സാക്ഷ്യപത്രം നൽകുക (Elder Vouch)'
                            : '🤝 തറവാട്ട് സാക്ഷ്യപത്രം നൽകുക (Vouch)'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
