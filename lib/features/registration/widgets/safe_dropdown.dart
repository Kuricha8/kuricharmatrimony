import 'package:flutter/material.dart';

class SafeDropdown<T> extends StatelessWidget {
  final T? value;
  final T? initialValue;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration? decoration;
  final FormFieldValidator<T>? validator;
  final Widget? hint;
  final bool isExpanded;
  final Widget? icon;

  const SafeDropdown({
    super.key,
    this.value,
    this.initialValue,
    required this.items,
    this.onChanged,
    this.decoration,
    this.validator,
    this.hint,
    this.isExpanded = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Deduplicate items to prevent duplicate value assertion errors
    final List<DropdownMenuItem<T>>? sanitizedItems;
    if (items != null) {
      final seenValues = <dynamic>{};
      final list = <DropdownMenuItem<T>>[];
      for (final item in items!) {
        if (seenValues.add(item.value)) {
          list.add(item);
        }
      }
      sanitizedItems = list;
    } else {
      sanitizedItems = null;
    }

    // Check if the provided value/initialValue exists in the items list
    T? effectiveValue = value ?? initialValue;
    bool valueExists = false;

    if (sanitizedItems != null && effectiveValue != null) {
      valueExists = sanitizedItems.any((item) => item.value == effectiveValue);
    }

    return DropdownButtonFormField<T>(
      initialValue: valueExists ? effectiveValue : null,
      items: sanitizedItems,
      onChanged: onChanged,
      decoration: decoration,
      validator: validator,
      hint: hint,
      isExpanded: isExpanded,
      icon: icon,
    );
  }
}
