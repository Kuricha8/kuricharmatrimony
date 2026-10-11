import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import 'tharavadu_list.dart';
import 'tharavadu_details_page.dart';

class TharavaduDirectoryPage extends StatefulWidget {
  const TharavaduDirectoryPage({super.key});

  @override
  State<TharavaduDirectoryPage> createState() => _TharavaduDirectoryPageState();
}

class _TharavaduDirectoryPageState extends State<TharavaduDirectoryPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    TharavaduService.instance.loadCachedClans();
    TharavaduService.instance.subscribeToUpdates();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Clan> get _filteredClans {
    final query = _searchQuery;
    final activeClans = allClans.where((c) => c.isActive).toList();
    activeClans.sort((a, b) => a.name.compareTo(b.name));

    if (query.isEmpty) return activeClans;
    return activeClans.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.nameMl.toLowerCase().contains(query) ||
          c.nameEn.toLowerCase().contains(query) ||
          (c.subName.isNotEmpty && c.subName.toLowerCase().contains(query)) ||
          c.displayName.toLowerCase().contains(query) ||
          c.groupName.toLowerCase().contains(query) ||
          ((query.contains('ചായമൽ') || query.contains('ചയിമ്മൽ')) &&
              c.nameMl.contains('പുച്ചിയേരി'));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F3),
      appBar: AppBar(
        title: const Text(
          'Tharavadu Directory',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF000080),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() {
                      _searchQuery = val.toLowerCase().trim();
                    });
                  }
                });
              },
              decoration: InputDecoration(
                hintText: 'Search Tharavadu...',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: TharavaduService.instance,
              builder: (context, _) {
                final clansToShow = _filteredClans;
                if (clansToShow.isEmpty) {
                  return const Center(child: Text('No tharavads found.'));
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      TharavaduService.instance.syncClans(forceRefresh: true),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: clansToShow.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: Colors.grey[200]),
                    itemBuilder: (context, index) {
                      final clan = clansToShow[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TharavaduDetailsPage(
                                clan: clan,
                                currentUser: MockData().currentUser,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          child: Text(
                            clan.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E1E1E),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.visible,
                            softWrap: true,
                          ),
                        ),
                      );
                    },
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
