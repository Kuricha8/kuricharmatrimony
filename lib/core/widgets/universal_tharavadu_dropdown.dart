import 'package:flutter/material.dart';
import '../services/tharavadu_master_service.dart';

class UniversalTharavaduDropdown extends StatelessWidget {
  final String label;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final String? hintText;

  const UniversalTharavaduDropdown({
    super.key,
    required this.label,
    required this.selectedValue,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: TharavaduMasterService.liveTharavaduListStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: LinearProgressIndicator(),
          );
        }

        final list = snapshot.data!;
        // നിലവിലെ വാല്യൂ ലിസ്റ്റിൽ ഉണ്ടോ എന്ന് ഉറപ്പുവരുത്തുന്നു
        final isValidValue =
            selectedValue != null && list.contains(selectedValue);

        return DropdownButtonFormField<String>(
          initialValue: isValidValue ? selectedValue : null,
          isExpanded: true,
          hint: hintText != null ? Text(hintText!) : null,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            prefixIcon: prefixIcon,
          ),
          items: list.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        );
      },
    );
  }
}
