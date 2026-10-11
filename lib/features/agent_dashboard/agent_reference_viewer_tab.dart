import 'package:flutter/material.dart';
import '../registration/registration_wizard.dart';

class AgentReferenceViewerTab extends StatefulWidget {
  const AgentReferenceViewerTab({super.key});

  @override
  State<AgentReferenceViewerTab> createState() =>
      _AgentReferenceViewerTabState();
}

class _AgentReferenceViewerTabState extends State<AgentReferenceViewerTab> {
  final TextEditingController _searchController = TextEditingController();
  int? _matchedStep;
  String _errorMessage = '';

  void _handleSearch(String query) {
    final cleanQuery = query.trim().toUpperCase();
    if (cleanQuery.isEmpty) {
      setState(() {
        _matchedStep = null;
        _errorMessage = '';
      });
      return;
    }

    // Regex to match p-10x or P-10x where x is 1-9
    final regex = RegExp(r'^P-10([1-9])$');
    final match = regex.firstMatch(cleanQuery);

    if (match != null) {
      final stepDigit = int.parse(match.group(1)!);
      // Steps are 0-indexed internally (0 to 8)
      setState(() {
        _matchedStep = stepDigit - 1;
        _errorMessage = '';
      });
    } else {
      setState(() {
        _matchedStep = null;
        _errorMessage =
            'Invalid Page Code. Please enter a valid code (e.g., P-101 to P-109).';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Header
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Agent Reference Viewer',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000080), // Premium Dark Blue
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter a Page Code provided by the user to instantly preview the exact screen they are on.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _searchController,
                onSubmitted: _handleSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'e.g., P-104',
                  prefixIcon: const Icon(
                    Icons.screen_search_desktop,
                    color: Color(0xFF000080),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Color(0xFF000080)),
                    onPressed: () => _handleSearch(_searchController.text),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF000080)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF000080),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),

        // Interactive Preview Container
        Expanded(
          child: Container(
            color: Colors.grey.shade100,
            child: _matchedStep == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.dashboard_customize_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Page Loaded',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter a valid code above to begin',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : RegistrationWizard(
                    key: ValueKey(
                      'preview_$_matchedStep',
                    ), // Force recreation when step changes
                    initialStep: _matchedStep,
                    isPreviewMode: true,
                  ),
          ),
        ),
      ],
    );
  }
}
