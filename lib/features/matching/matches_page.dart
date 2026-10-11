import 'package:flutter/material.dart';
import '../../core/utils/mock_data.dart';
import 'controllers/matching_controller.dart';
import 'widgets/match_profile_card.dart';
import 'widgets/matching_filter_bar.dart';
import 'widgets/matching_empty_state.dart';
import 'widgets/lineage_checker_card.dart';
import 'widgets/unapproved_matches_view.dart';

export 'widgets/compatibility_checker_widget.dart';

class MatchesScreen extends StatefulWidget {
  final bool showAppBar;
  const MatchesScreen({super.key, this.showAppBar = true});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  late final MatchingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MatchingController()..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = MockData().currentUser;
    if (me == null) {
      return const Scaffold(body: Center(child: Text('Please log in to view matches.')));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: widget.showAppBar ? AppBar(
        title: const Text('Find Partner', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white,
      ) : null,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight, end: Alignment.bottomLeft,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(children: [
                const LineageCheckerCard(),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      if (!_controller.isApprovedStatus(me)) {
                        return UnapprovedMatchesView(controller: _controller);
                      }
                      if (_controller.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final matches = _controller.matches;
                      return Column(children: [
                        MatchingFilterBar(controller: _controller),
                        if (matches.isEmpty)
                          MatchingEmptyState(isFiltered: _controller.goldTrustOnly)
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: matches.length,
                              itemBuilder: (ctx, idx) => MatchProfileCard(profile: matches[idx], controller: _controller),
                            ),
                          ),
                      ]);
                    },
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
