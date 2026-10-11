import 'package:flutter/material.dart';

class MatchingEmptyState extends StatelessWidget {
  final bool isFiltered;

  const MatchingEmptyState({super.key, this.isFiltered = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFiltered ? Icons.filter_alt_off_rounded : Icons.people_outline_rounded,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'ഗോൾഡ് ട്രസ്റ്റ് മുദ്രയുള്ള പ്രൊഫൈലുകൾ ലഭ്യമല്ല.'
                  : 'ഇപ്പോൾ പൊരുത്തമുള്ള പ്രൊഫൈലുകൾ ഒന്നും ലഭ്യമല്ല.',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
