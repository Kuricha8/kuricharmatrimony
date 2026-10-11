import 'package:flutter/material.dart';

class PhysicalDetailsSection extends StatelessWidget {
  final TextEditingController fatherNameController;
  final bool isFatherDeceased;
  final ValueChanged<bool?> onFatherDeceasedChanged;
  final TextEditingController motherNameController;
  final bool isMotherDeceased;
  final ValueChanged<bool?> onMotherDeceasedChanged;
  final TextEditingController houseNameController;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final TextEditingController bloodGroupController;
  final TextEditingController physicalStatusController;

  const PhysicalDetailsSection({
    super.key,
    required this.fatherNameController,
    required this.isFatherDeceased,
    required this.onFatherDeceasedChanged,
    required this.motherNameController,
    required this.isMotherDeceased,
    required this.onMotherDeceasedChanged,
    required this.houseNameController,
    required this.heightController,
    required this.weightController,
    required this.bloodGroupController,
    required this.physicalStatusController,
  });

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFD4AF37)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'FAMILY DETAILS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5C3E00),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: fatherNameController,
          textCapitalization: TextCapitalization.words,
          decoration: _buildInputDecoration('Father\'s Name', Icons.person),
        ),
        Row(
          children: [
            Checkbox(
              value: isFatherDeceased,
              onChanged: onFatherDeceasedChanged,
            ),
            const Text('Late (Deceased)'),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: motherNameController,
          textCapitalization: TextCapitalization.words,
          decoration: _buildInputDecoration('Mother\'s Name', Icons.person),
        ),
        Row(
          children: [
            Checkbox(
              value: isMotherDeceased,
              onChanged: onMotherDeceasedChanged,
            ),
            const Text('Late (Deceased)'),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: houseNameController,
          textCapitalization: TextCapitalization.words,
          decoration: _buildInputDecoration('House Name', Icons.home),
        ),
        const SizedBox(height: 16),

        const Text(
          'PHYSICAL DETAILS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5C3E00),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: heightController,
                decoration: _buildInputDecoration(
                  'Height (e.g. 5\'8")',
                  Icons.height,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: weightController,
                decoration: _buildInputDecoration(
                  'Weight (kg)',
                  Icons.monitor_weight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: bloodGroupController,
                decoration: _buildInputDecoration(
                  'Blood Group',
                  Icons.bloodtype,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: physicalStatusController,
                decoration: _buildInputDecoration(
                  'Physical Status',
                  Icons.fitness_center,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
