import 'package:flutter/material.dart';

class PartnerPreferencesSection extends StatelessWidget {
  final TextEditingController prefAgeMinController;
  final TextEditingController prefAgeMaxController;
  final TextEditingController prefEducationController;
  final TextEditingController prefLocationController;
  final TextEditingController prefOccupationController;

  const PartnerPreferencesSection({
    super.key,
    required this.prefAgeMinController,
    required this.prefAgeMaxController,
    required this.prefEducationController,
    required this.prefLocationController,
    required this.prefOccupationController,
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
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'PARTNER PREFERENCES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: prefAgeMinController,
                    keyboardType: TextInputType.number,
                    decoration: _buildInputDecoration(
                      'Min Age',
                      Icons.person_search,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    'to',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: prefAgeMaxController,
                    keyboardType: TextInputType.number,
                    decoration: _buildInputDecoration(
                      'Max Age',
                      Icons.person_search,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: prefEducationController,
              textCapitalization: TextCapitalization.words,
              decoration: _buildInputDecoration(
                'Preferred Education',
                Icons.school,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: prefLocationController,
              textCapitalization: TextCapitalization.words,
              decoration: _buildInputDecoration(
                'Preferred Location',
                Icons.location_on,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: prefOccupationController,
              textCapitalization: TextCapitalization.words,
              decoration: _buildInputDecoration(
                'Preferred Occupation',
                Icons.work,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
