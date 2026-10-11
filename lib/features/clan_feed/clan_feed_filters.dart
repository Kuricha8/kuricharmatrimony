import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/models.dart';

class ClanFeedFilters extends StatelessWidget {
  final List<Clan> allClans;
  final int? selectedFilterClanId;
  final ValueChanged<int?> onFilterSelected;
  final ValueChanged<Clan>? onClanLongPress;

  const ClanFeedFilters({
    super.key,
    required this.allClans,
    required this.selectedFilterClanId,
    required this.onFilterSelected,
    this.onClanLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Icon(Icons.hub_outlined, size: 15, color: Color(0xFF000080)),
              SizedBox(width: 6),
              Text(
                'തറവാടുകൾ പ്രകാരം ഫിൽട്ടർ ചെയ്യുക:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF5C3E00),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 86,
          child: allClans.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: allClans.length,
                  itemBuilder: (context, index) {
                    final clan = allClans[index];
                    final isSelected = selectedFilterClanId == clan.id;
                    final isPandi = clan.type == 'PANDI';
                    final color = isPandi ? Colors.teal : Colors.indigo;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          if (selectedFilterClanId == clan.id) {
                            onFilterSelected(null);
                          } else {
                            onFilterSelected(clan.id);
                          }
                        },
                        onLongPress: onClanLongPress != null
                            ? () => onClanLongPress!(clan)
                            : null,
                        child: Column(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Colors.amber
                                    : color.withValues(alpha: 0.15),
                                border: isSelected
                                    ? Border.all(color: Colors.amber, width: 2)
                                    : null,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child:
                                  clan.imageUrl != null &&
                                      clan.imageUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: clan.imageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Icon(
                                        isPandi
                                            ? Icons.shield_outlined
                                            : Icons.diversity_3_outlined,
                                        color: isSelected
                                            ? Colors.white
                                            : color,
                                        size: 20,
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Icon(
                                            isPandi
                                                ? Icons.shield_outlined
                                                : Icons.diversity_3_outlined,
                                            color: isSelected
                                                ? Colors.white
                                                : color,
                                            size: 20,
                                          ),
                                    )
                                  : Icon(
                                      isPandi
                                          ? Icons.shield_outlined
                                          : Icons.diversity_3_outlined,
                                      color: isSelected ? Colors.white : color,
                                      size: 20,
                                    ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 60,
                              child: Text(
                                clan.nameMl.isNotEmpty
                                    ? clan.nameMl
                                    : clan.name,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.amber.shade900
                                      : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
    );
  }
}
