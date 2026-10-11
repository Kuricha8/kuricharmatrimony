import 'package:flutter/material.dart';
import '../../../../core/models/story_model.dart';

class StoryCreationStudio extends StatelessWidget {
  final StoryType initialStoryType;

  const StoryCreationStudio({super.key, required this.initialStoryType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Tharavadu Status')),
      body: Center(
        child: Text(
          'Story Creation Studio (${initialStoryType.name})',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
