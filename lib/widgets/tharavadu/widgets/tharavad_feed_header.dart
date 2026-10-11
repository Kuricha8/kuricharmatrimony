import 'package:flutter/material.dart';

class TharavadFeedHeader extends StatelessWidget {
  final bool canPost;

  const TharavadFeedHeader({super.key, required this.canPost});

  @override
  Widget build(BuildContext context) {
    if (canPost) return const SizedBox.shrink();

    return Container(
      color: Colors.orange.shade100,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.visibility_outlined,
            color: Colors.orange.shade800,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'വ്യൂവർ മോഡ് (Read-only) - നിങ്ങൾ ഈ തറവാട്ടിലെ അംഗമല്ല.',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
