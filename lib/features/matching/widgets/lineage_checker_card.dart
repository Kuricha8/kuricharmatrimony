import 'package:flutter/material.dart';
import 'compatibility_checker_widget.dart';

class LineageCheckerCard extends StatelessWidget {
  const LineageCheckerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      elevation: 4,
      color: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: const ExpansionTile(
          iconColor: Colors.pinkAccent,
          collapsedIconColor: Colors.white70,
          leading: Icon(Icons.favorite, color: Colors.pinkAccent),
          title: Text(
            'Lineage Compatibility Checker',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          subtitle: Text(
            'Check if two Tharavadus can marry',
            style: TextStyle(color: Colors.white70),
          ),
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: CompatibilityCheckerWidget(),
            ),
          ],
        ),
      ),
    );
  }
}
