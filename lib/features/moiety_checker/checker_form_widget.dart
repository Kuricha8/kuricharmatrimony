import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/models.dart';
import '../clan_feed/tharavadu_list.dart';

class CheckerFormWidget extends StatefulWidget {
  final void Function(Clan groomClan, Clan brideClan, bool speakerOn)
  onCheckCompatibility;
  final bool? isCompatible;

  const CheckerFormWidget({
    super.key,
    required this.onCheckCompatibility,
    this.isCompatible,
  });

  @override
  State<CheckerFormWidget> createState() => _CheckerFormWidgetState();
}

class _CheckerFormWidgetState extends State<CheckerFormWidget>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  Clan? _groomClan;
  Clan? _brideClan;
  bool _speakerOn = true;
  bool _hasChangedSinceCheck = false;

  // null = not yet answered, true = YES, false = NO
  // (State variable removed as requested)

  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    TharavaduService.instance.subscribeToUpdates();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(
      begin: 2.0,
      end: 12.0,
    ).animate(_pulseController);
  }

  void _showTharavaduSearchDialog({
    required bool isGroom,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return ListenableBuilder(
              listenable: TharavaduService.instance,
              builder: (ctx, _) {
                final Set<int> seenIds = {};
                final liveClans = TharavaduService.allClans.where((c) {
                  if (!c.isActive) return false;
                  if (seenIds.contains(c.id)) return false;
                  seenIds.add(c.id);
                  return true;
                }).toList()
                  ..sort((a, b) => a.displayName.compareTo(b.displayName));

                final filtered = liveClans.where((c) {
                  if (searchQuery.isNotEmpty) {
                    final q = searchQuery.toLowerCase().trim();
                    final disp = c.displayName.toLowerCase();
                    final en = c.nameEn.toLowerCase();
                    return disp.contains(q) ||
                        en.contains(q) ||
                        c.id.toString() == q;
                  }
                  return true;
                }).toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isGroom ? Icons.male : Icons.female,
                          color:
                              isGroom ? Colors.blueAccent : Colors.pinkAccent,
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isGroom
                                ? 'വരന്റെ തറവാട് തിരഞ്ഞെടുക്കുക'
                                : 'വധുവിന്റെ തറവാട് തിരഞ്ഞെടുക്കുക',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText:
                            'തറവാടിന്റെ പേര് തിരയുക (Search Tharavadu)...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.indigo),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () =>
                                    setModalState(() => searchQuery = ''),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) =>
                          setModalState(() => searchQuery = val),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'തറവാടുകൾ കണ്ടെത്തിയില്ല',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: filtered.length,
                            separatorBuilder: (sepCtx, sepIdx) =>
                                Divider(height: 1, color: Colors.grey[200]),
                            itemBuilder: (ctx, i) {
                              final clan = filtered[i];
                              final isSelected = isGroom
                                  ? (_groomClan?.id == clan.id)
                                  : (_brideClan?.id == clan.id);
                              final displayName = clan.displayName;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isGroom) {
                                      _groomClan = clan;
                                    } else {
                                      _brideClan = clan;
                                    }
                                    _hasChangedSinceCheck = true;
                                  });
                                  Navigator.pop(ctx);
                                },
                                child: Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          displayName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: const Color(0xFF1E1E1E),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.visible,
                                          softWrap: true,
                                        ),
                                      ),
                                      if (isSelected)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: Icon(
                                            Icons.check,
                                            color: Color(0xFF1E1E1E),
                                            size: 20,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  void didUpdateWidget(CheckerFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompatible != oldWidget.isCompatible) {
      if (widget.isCompatible != null) {
        setState(() {
          _hasChangedSinceCheck = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleCheck() {
    if (!_formKey.currentState!.validate()) return;
    if (_groomClan == null || _brideClan == null) return;
    widget.onCheckCompatibility(_groomClan!, _brideClan!, _speakerOn);
  }

  void _showAddTharavaduDialog() {
    final nameC = TextEditingController(),
        placeC = TextEditingController(),
        phoneC = TextEditingController(),
        fk = GlobalKey<FormState>();
    bool saving = false;
    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, ss) => AlertDialog(
          title: const Text(
            'ശ്രദ്ധിക്കുക: കുറിച്ച്യ സമുദായത്തിലെ പ്രധാന 57 തറവാടുകളാണ് ലിസ്റ്റിൽ ഉള്ളത്. ഇതിൽ ഉൾപ്പെടാത്ത ശാഖാ തറവാടുകളോ വീട്ടുപേരുകളോ ഉണ്ടെങ്കിൽ ദയവായി താഴെ നൽകുക. വിവരങ്ങൾ പരിശോധിച്ച് പ്രധാന തറവാട്ടുമായി ബന്ധപ്പെടുത്തി അഡ്മിൻ ഉടൻ അപ്ഡേറ്റ് ചെയ്യും.',
            style: TextStyle(fontSize: 14),
          ),
          content: Form(
            key: fk,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameC,
                  decoration: const InputDecoration(
                    labelText: 'വീട്ടുപേര് / തറവാട് പേര്',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  onChanged: (_) => ss(() {}),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: placeC,
                  decoration: const InputDecoration(
                    labelText: 'സ്ഥലം',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  onChanged: (_) => ss(() {}),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneC,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'ഫോൺ നമ്പർ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  onChanged: (_) => ss(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(c),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed:
                  (saving ||
                      nameC.text.trim().isEmpty ||
                      placeC.text.trim().isEmpty ||
                      phoneC.text.trim().isEmpty)
                  ? null
                  : () async {
                      if (!fk.currentState!.validate()) return;
                      ss(() => saving = true);
                      try {
                        await Supabase.instance.client
                            .from('tharavadu_add_requests')
                            .insert({
                              'name': nameC.text.trim(),
                              'place': placeC.text.trim(),
                              'phone': phoneC.text.trim(),
                              'status': 'pending',
                            });
                        if (c.mounted) Navigator.pop(c);
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (successCtx) => AlertDialog(
                              title: const Text(
                                'വിജയിച്ചു (Success)',
                                style: TextStyle(color: Colors.green),
                              ),
                              content: const Text(
                                'നിങ്ങളുടെ തറവാട് വിവരങ്ങൾ വിജയകരമായി സമർപ്പിച്ചു. അഡ്മിൻ പരിശോധിച്ച് അംഗീകരിച്ച ശേഷം അറിയിപ്പ് ലഭിക്കുന്നതാണ്.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(successCtx),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) ss(() => saving = false);
                      }
                    },
              child: saving
                  ? const CircularProgressIndicator()
                  : const Text('Submit / Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshClans() async {
    await TharavaduService.instance.syncClans(forceRefresh: true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('തറവാട് വിവരങ്ങൾ അപ്ഡേറ്റ് ചെയ്തു')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TharavaduService.instance,
      builder: (context, _) {
        final Set<int> seenIds = {};
        final List<Clan> displayClans = allClans.where((c) {
          if (!c.isActive) return false;
          if (seenIds.contains(c.id)) return false;
          seenIds.add(c.id);
          return true;
        }).toList()..sort((a, b) => a.displayName.compareTo(b.displayName));

        final bool showLed =
            widget.isCompatible != null && !_hasChangedSinceCheck;
        final bool isMatch = widget.isCompatible ?? false;

        if (displayClans.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.style_outlined,
                  size: 56,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                const Text(
                  'തറവാടുകൾ ലഭ്യമല്ല',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'തറവാടുകൾ തിരഞ്ഞെടുക്കാൻ ഡാറ്റാബേസിൽ വിവരങ്ങൾ ഉണ്ടായിരിക്കണം',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final Clan? safeGroomClan = _groomClan != null
            ? displayClans.cast<Clan?>().firstWhere(
                (c) => c?.id == _groomClan!.id,
                orElse: () => null,
              )
            : null;

        final Clan? safeBrideClan = _brideClan != null
            ? displayClans.cast<Clan?>().firstWhere(
                (c) => c?.id == _brideClan!.id,
                orElse: () => null,
              )
            : null;

        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final double glowRadius = showLed ? _glowAnimation.value : 0.0;
            final Color ledColor = showLed
                ? (isMatch ? Colors.green : Colors.red)
                : Colors.transparent;

            final Border border = showLed
                ? Border.all(color: ledColor, width: 3)
                : Border.all(color: Colors.grey.shade300, width: 1.5);

            final List<BoxShadow> boxShadow = showLed
                ? [
                    BoxShadow(
                      color: ledColor.withValues(alpha: 0.6),
                      blurRadius: glowRadius,
                      spreadRadius: glowRadius / 3,
                    ),
                  ]
                : [];

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: border,
                boxShadow: [
                  ...boxShadow,
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Speaker toggle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => _speakerOn = !_speakerOn),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _speakerOn
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              color: _speakerOn
                                  ? Colors.pinkAccent
                                  : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _speakerOn
                                  ? 'ശബ്ദം (Voice On)'
                                  : 'ശബ്ദം ഓഫ് (Voice Off)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _speakerOn
                                    ? Colors.pinkAccent
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Groom dropdown ─────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Clan>(
                        isExpanded: true,
                        hint: const Text(
                          'തറവാട് തിരഞ്ഞെടുക്കുക',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        decoration: InputDecoration(
                          labelText: 'വരന്റെ ഗോത്രം (Groom\'s Clan)',
                          prefixIcon: const Icon(
                            Icons.male,
                            color: Colors.blueAccent,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                        ),
                        key: ValueKey('groom_${safeGroomClan?.id}_${safeGroomClan?.displayName}'),
                        initialValue: safeGroomClan,
                        items: displayClans.map((clan) {
                          final displayName = clan.displayName;
                          return DropdownMenuItem<Clan>(
                            value: clan,
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                color: Color(0xFF1E1E1E),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                              softWrap: true,
                            ),
                          );
                        }).toList(),
                        selectedItemBuilder: (BuildContext context) {
                          return displayClans.map((clan) {
                            final displayName = clan.displayName;
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                displayName,
                                style: const TextStyle(
                                  color: Color(0xFF1E1E1E),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                                softWrap: true,
                              ),
                            );
                          }).toList();
                        },
                        onChanged: (Clan? value) {
                          setState(() {
                            _groomClan = value;
                            _hasChangedSinceCheck = true;
                          });
                        },
                        validator: (v) => v == null
                            ? 'ദയവായി വരന്റെ ഗോത്രം തിരഞ്ഞെടുക്കുക'
                            : null,
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.search,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () => _showTharavaduSearchDialog(
                            isGroom: true,
                          ),
                          tooltip: 'വരന്റെ തറവാട് തിരയുക (Search)',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.indigo,
                          ),
                          onPressed: _showAddTharavaduDialog,
                          tooltip: 'Suggest New Tharavadu',
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _refreshClans,
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Bride dropdown ─────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Clan>(
                        isExpanded: true,
                        hint: const Text(
                          'തറവാട് തിരഞ്ഞെടുക്കുക',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        decoration: InputDecoration(
                          labelText: 'വധുവിന്റെ ഗോത്രം (Bride\'s Clan)',
                          prefixIcon: const Icon(
                            Icons.female,
                            color: Colors.pinkAccent,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                        ),
                        key: ValueKey('bride_${safeBrideClan?.id}_${safeBrideClan?.displayName}'),
                        initialValue: safeBrideClan,
                        items: displayClans.map((clan) {
                          final displayName = clan.displayName;
                          return DropdownMenuItem<Clan>(
                            value: clan,
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                color: Color(0xFF1E1E1E),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                              softWrap: true,
                            ),
                          );
                        }).toList(),
                        selectedItemBuilder: (BuildContext context) {
                          return displayClans.map((clan) {
                            final displayName = clan.displayName;
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                displayName,
                                style: const TextStyle(
                                  color: Color(0xFF1E1E1E),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                                softWrap: true,
                              ),
                            );
                          }).toList();
                        },
                        onChanged: (Clan? value) {
                          setState(() {
                            _brideClan = value;
                            _hasChangedSinceCheck = true;
                          });
                        },
                        validator: (v) => v == null
                            ? 'ദയവായി വധുവിന്റെ ഗോത്രം തിരഞ്ഞെടുക്കുക'
                            : null,
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.search,
                            color: Colors.pinkAccent,
                          ),
                          onPressed: () => _showTharavaduSearchDialog(
                            isGroom: false,
                          ),
                          tooltip: 'വധുവിന്റെ തറവാട് തിരയുക (Search)',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.indigo,
                          ),
                          onPressed: _showAddTharavaduDialog,
                          tooltip: 'Suggest New Tharavadu',
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _refreshClans,
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    'നിങ്ങളുടെ തറവാട് ലിസ്റ്റിൽ കാണുന്നില്ലെങ്കിൽ, അടുത്തുള്ള + ഐക്കൺ അമർത്തി തറവാടിന്റെ പേരും സ്ഥലവും രേഖപ്പെടുത്തുക. അഡ്മിൻ പരിശോധനയ്ക്ക് ശേഷം ഇത് ലിസ്റ്റിൽ ഉൾപ്പെടുത്തുന്നതാണ്.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Builder(
                  builder: (context) {
                    final bool canSubmit =
                        safeGroomClan != null && safeBrideClan != null;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: canSubmit
                            ? const LinearGradient(
                                colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.grey.shade300,
                                  Colors.grey.shade400,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: canSubmit
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1E3C72,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: ElevatedButton(
                        onPressed: canSubmit ? _handleCheck : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.compare_arrows_rounded,
                              color: canSubmit
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Check Compatibility (പൊരുത്തം പരിശോധിക്കുക)',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: canSubmit
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // _buildYesNoQuestion removed as requested
}
