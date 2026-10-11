import 'package:flutter/material.dart';
import '../../../../core/models/models.dart';
import 'admin_request_dialog.dart';

class PersonalDetailsSection extends StatelessWidget {
  final UserProfile user;
  final TextEditingController nameController;
  final TextEditingController dobController;
  final TextEditingController ageController;
  final Gender? selectedGender;
  final int? selectedFatherClanId;
  final int? selectedMotherClanId;
  final List<Clan> uniqueClans;
  final VoidCallback onRefresh;
  final TextEditingController emailController;
  final TextEditingController bioController;
  final TextEditingController locationController;
  final TextEditingController educationController;
  final TextEditingController occupationController;
  final TextEditingController phoneController;
  final TextEditingController publicDisplayNumberController;

  const PersonalDetailsSection({
    super.key,
    required this.user,
    required this.nameController,
    required this.dobController,
    required this.ageController,
    required this.selectedGender,
    required this.selectedFatherClanId,
    required this.selectedMotherClanId,
    required this.uniqueClans,
    required this.onRefresh,
    required this.emailController,
    required this.bioController,
    required this.locationController,
    required this.educationController,
    required this.occupationController,
    required this.phoneController,
    required this.publicDisplayNumberController,
  });

  InputDecoration _buildInputDecoration(
    String label,
    IconData icon, {
    bool isReadOnly = false,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: isReadOnly ? Colors.grey.shade400 : const Color(0xFFD4AF37),
      ),
      filled: true,
      fillColor: isReadOnly ? Colors.grey.shade100 : Colors.white,
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
    final profile = user.toMap();
    final fatherTharavad =
        profile['father_tharavadu'] ??
        profile['father_clan'] ??
        profile['father_tharavad'] ??
        '';
    final motherTharavad =
        profile['mother_tharavadu'] ??
        profile['mother_clan'] ??
        profile['mother_tharavad'] ??
        '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'LOCKED CRITICAL DETAILS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5C3E00),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock, size: 12, color: Color(0xFF5C3E00)),
                  SizedBox(width: 4),
                  Text(
                    'REQUIRES ADMIN APPROVAL',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5C3E00),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Locked Full Name Field
        TextFormField(
          controller: nameController,
          readOnly: true,
          decoration: _buildInputDecoration(
            'Full Name (Locked)',
            Icons.lock,
            isReadOnly: true,
          ),
        ),
        const SizedBox(height: 12),

        // Locked Date of Birth & Age
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: dobController,
                readOnly: true,
                decoration: _buildInputDecoration(
                  'Date of Birth (Locked)',
                  Icons.lock,
                  isReadOnly: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: ageController,
                readOnly: true,
                decoration: _buildInputDecoration(
                  'Age (Locked)',
                  Icons.lock,
                  isReadOnly: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Locked Gender Dropdown
        DropdownButtonFormField<Gender>(
          initialValue: selectedGender,
          decoration: _buildInputDecoration(
            'Gender (Locked)',
            Icons.lock,
            isReadOnly: true,
          ),
          items: const [
            DropdownMenuItem(value: Gender.male, child: Text('Male')),
            DropdownMenuItem(value: Gender.female, child: Text('Female')),
          ],
          onChanged: null,
        ),

        const SizedBox(height: 16),
        // Locked Father's & Mother's Tharavad UI widgets
        InputDecorator(
          decoration: _buildInputDecoration(
            'Father\'s Tharavad (Locked)',
            Icons.lock,
            isReadOnly: true,
          ),
          child: Text(
            fatherTharavad.isNotEmpty ? fatherTharavad : 'ലഭ്യമല്ല',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),

        InputDecorator(
          decoration: _buildInputDecoration(
            'Mother\'s Tharavad (Locked)',
            Icons.lock,
            isReadOnly: true,
          ),
          child: Text(
            motherTharavad.isNotEmpty ? motherTharavad : 'ലഭ്യമല്ല',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),

        // Lock Note & Request Change to Admin Button
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade400),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_clock, color: Color(0xFF5C3E00), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ലോക്ക് ചെയ്ത ഫീൽഡ്. തിരുത്താൻ അഡ്മിൻ അനുമതി ആവശ്യമാണ്. (LOCKED FIELD. REQUIRES ADMIN APPROVAL TO EDIT.)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF5C3E00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => AdminRequestDialog.show(
            context,
            user,
            onRefresh,
            nameController,
            dobController,
            selectedGender,
            selectedFatherClanId,
            selectedMotherClanId,
          ),
          icon: const Icon(
            Icons.mark_email_unread_outlined,
            color: Colors.white,
          ),
          label: const Text(
            'അഡ്മിൻ മാറ്റത്തിനായി അപേക്ഷിക്കുക (Request Change to Admin)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF000080),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          'EDITABLE PERSONAL DETAILS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5C3E00),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _buildInputDecoration('Email Address', Icons.email),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: bioController,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: _buildInputDecoration(
            'Bio / About Me',
            Icons.description,
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'LOCATION & CONTACT INFO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5C3E00),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: locationController,
          textCapitalization: TextCapitalization.words,
          decoration: _buildInputDecoration(
            'Location (District/City)',
            Icons.location_on,
          ),
          validator: (val) =>
              val == null || val.trim().isEmpty ? 'Location is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: educationController,
          textCapitalization: TextCapitalization.words,
          decoration: _buildInputDecoration('Education Level', Icons.school),
          validator: (val) => val == null || val.trim().isEmpty
              ? 'Education is required'
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: occupationController,
          textCapitalization: TextCapitalization.words,
          decoration: _buildInputDecoration('Occupation', Icons.work),
          validator: (val) => val == null || val.trim().isEmpty
              ? 'Occupation is required'
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: _buildInputDecoration('Guardian Phone', Icons.phone),
          validator: (val) => val == null || val.trim().isEmpty
              ? 'Phone number is required'
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: publicDisplayNumberController,
          keyboardType: TextInputType.phone,
          decoration: _buildInputDecoration(
            'Public Display Number',
            Icons.phone_android,
          ),
        ),
      ],
    );
  }
}
