import 'package:flutter/material.dart';

enum ParentStatus { alive, late }

class ParentDetailsForm extends StatelessWidget {
  final TextEditingController fatherNameController;
  final TextEditingController motherNameController;
  final ParentStatus? fatherStatus;
  final ParentStatus? motherStatus;
  final ValueChanged<ParentStatus?> onFatherStatusChanged;
  final ValueChanged<ParentStatus?> onMotherStatusChanged;

  const ParentDetailsForm({
    super.key,
    required this.fatherNameController,
    required this.motherNameController,
    required this.fatherStatus,
    required this.motherStatus,
    required this.onFatherStatusChanged,
    required this.onMotherStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Parent Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Father's Details
        TextFormField(
          controller: fatherNameController,
          decoration: const InputDecoration(
            labelText: 'Father\'s Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Please enter father\'s name'
              : null,
        ),
        const SizedBox(height: 8),
        RadioGroup<ParentStatus?>(
          groupValue: fatherStatus,
          onChanged: onFatherStatusChanged,
          child: Row(
            children: [
              const Text('Father\'s Status:'),
              Expanded(
                child: RadioListTile<ParentStatus>(
                  title: const Text('Alive'),
                  value: ParentStatus.alive,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<ParentStatus>(
                  title: const Text('Late'),
                  value: ParentStatus.late,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Mother's Details
        TextFormField(
          controller: motherNameController,
          decoration: const InputDecoration(
            labelText: 'Mother\'s Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Please enter mother\'s name'
              : null,
        ),
        const SizedBox(height: 8),
        RadioGroup<ParentStatus?>(
          groupValue: motherStatus,
          onChanged: onMotherStatusChanged,
          child: Row(
            children: [
              const Text('Mother\'s Status:'),
              Expanded(
                child: RadioListTile<ParentStatus>(
                  title: const Text('Alive'),
                  value: ParentStatus.alive,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<ParentStatus>(
                  title: const Text('Late'),
                  value: ParentStatus.late,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
