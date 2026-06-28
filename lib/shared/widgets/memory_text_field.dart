import 'package:flutter/material.dart';

import '../../app/theme/app_text_styles.dart';

/// A custom, premium styled text field for forms, search inputs, and chats.
/// Maps text input directly to the design system typography and dark tokens.
class MemoryTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final int? maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;

  const MemoryTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
    this.focusNode,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      focusNode: focusNode,
      validator: validator,
      onChanged: onChanged,
      style: AppTextStyles.bodyLarge.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
