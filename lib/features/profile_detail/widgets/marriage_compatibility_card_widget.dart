import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/models.dart';
import '../../../core/services/clan_matching_engine.dart';
import '../../../core/services/kinship_service.dart';
import '../../../core/widgets/kinship_compatibility_badge.dart';
import '../../clan_feed/tharavadu_list.dart';
import '../../clan_feed/tharavadu_details_page.dart';

class MarriageCompatibilityCardWidget extends StatefulWidget {
  final UserProfile profile;
  final UserProfile? me;

  const MarriageCompatibilityCardWidget({
    super.key,
    required this.profile,
    this.me,
  });

  @override
  State<MarriageCompatibilityCardWidget> createState() =>
      _MarriageCompatibilityCardWidgetState();
}

class _MarriageCompatibilityCardWidgetState
    extends State<MarriageCompatibilityCardWidget> {
  List<Clan> _compatibleClans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompatibleClans();
  }

  Future<void> _fetchCompatibleClans() async {
    final candidateTharavadu =
        widget.profile.motherTharavadu ??
        widget.profile.fatherTharavadu ??
        widget.profile.tharavaduName;
    final int candidateClanId = widget.profile.tharavaduId;

    List<Clan> resolvedClans = [];

    // 1. Try SQL RPC function get_compatible_tharavadus
    try {
      if (candidateClanId != 0) {
        final rpcRes = await Supabase.instance.client.rpc(
          'get_compatible_tharavadus',
          params: {'tharavadu_id': candidateClanId},
        );

        if (rpcRes is List && rpcRes.isNotEmpty) {
          for (final item in rpcRes) {
            final int id = item['id'] is int
                ? item['id'] as int
                : int.tryParse(item['id'].toString()) ?? 0;
            final clan =
                getClanById(id) ??
                getClanByName(item['name']?.toString() ?? '');
            if (clan != null && !resolvedClans.any((c) => c.id == clan.id)) {
              resolvedClans.add(clan);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('get_compatible_tharavadus RPC note: $e');
    }

    // 2. Fallback to ClanMatchingEngine Exogamy Rules (PANDI <-> BANDHU)
    if (resolvedClans.isEmpty) {
      final candidateMoiety = ClanMatchingEngine.instance.getMoietyForClan(
        candidateClanId != 0 ? candidateClanId : candidateTharavadu,
      );
      final targetMoiety = candidateMoiety == 'PANDI'
          ? 'BANDHU'
          : (candidateMoiety == 'BANDHU' ? 'PANDI' : 'ALL');

      for (final clan in TharavaduService.allClans) {
        if (candidateClanId != 0 && clan.id == candidateClanId) continue;
        if (widget.profile.motherClanId > 0 &&
            clan.id == widget.profile.motherClanId) {
          continue;
        }
        if (widget.profile.fatherClanId > 0 &&
            clan.id == widget.profile.fatherClanId) {
          continue;
        }
        if (targetMoiety == 'ALL') {
          resolvedClans.add(clan);
        } else {
          final m = ClanMatchingEngine.instance.getMoietyForClan(clan);
          if (m == targetMoiety) {
            resolvedClans.add(clan);
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _compatibleClans = resolvedClans;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    final kinshipResult = widget.me != null
        ? KinshipService.instance.checkMoietyCompatibility(
            widget.me,
            widget.profile,
          )
        : null;

    if (_compatibleClans.isEmpty && kinshipResult == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF000080).withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kinshipResult != null) ...[
            KinshipCompatibilityBadge(result: kinshipResult, isCompact: false),
            const SizedBox(height: 18),
          ],
          if (_compatibleClans.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.favorite, color: Colors.pink, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'വിവാഹബന്ധം അനുവദനീയമായ തറവാടുകൾ',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Eligible Compatible Clans for Marriage',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Text(
                    '${_compatibleClans.length} തറവാടുകൾ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _compatibleClans.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final clan = _compatibleClans[index];
                final displayName = clan.displayName;

                return InkWell(
                  onTap: () {
                    final targetClan = getClanById(clan.id) ?? clan;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => TharavaduDetailsPage(
                          clan: targetClan,
                          currentUser: widget.me,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 135,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF000080).withValues(alpha: 0.05),
                          const Color(0xFF000080).withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF000080).withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(
                            0xFF000080,
                          ).withValues(alpha: 0.1),
                          backgroundImage:
                              clan.imageUrl != null &&
                                  clan.imageUrl!.startsWith('http')
                              ? NetworkImage(clan.imageUrl!)
                              : null,
                          child:
                              clan.imageUrl == null ||
                                  !clan.imageUrl!.startsWith('http')
                              ? Text(
                                  displayName.isNotEmpty ? displayName[0] : 'ത',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF000080),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
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
  }
}
