import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

/// A wrapper widget that ensures dropdown menu width matches the button width
/// Uses DropdownButton2 which supports width constraint via dropdownStyleData
class ConstrainedDropdownButtonFormField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration decoration;
  final FormFieldValidator<T>? validator;
  final bool isExpanded;
  final double? menuMaxHeight;

  const ConstrainedDropdownButtonFormField({
    Key? key,
    required this.value,
    required this.items,
    this.onChanged,
    required this.decoration,
    this.validator,
    this.isExpanded = true,
    this.menuMaxHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get the available width to constrain the menu
        final availableWidth = constraints.maxWidth;
        
        return DropdownButtonFormField2<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: decoration,
          validator: validator,
          isExpanded: isExpanded,
          dropdownStyleData: DropdownStyleData(
            maxHeight: menuMaxHeight ?? 300,
            width: availableWidth, // This constrains the menu width to match the button
          ),
          alignment: AlignmentDirectional.centerStart,
        );
      },
    );
  }
}
