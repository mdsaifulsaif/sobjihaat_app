import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable Web-Styled Text Input Field for SobjiHaat
/// Provides a consistent, clean border, subtle background, and proper focus styles.
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final bool isRequired;
  final String? hintText;
  final Widget? prefixIcon;
  final IconData? icon;
  final Widget? suffixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool enabled;
  final FocusNode? focusNode;
  final int maxLines;
  final int minLines;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.isRequired = false,
    this.hintText,
    this.prefixIcon,
    this.icon,
    this.suffixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.focusNode,
    this.maxLines = 1,
    this.minLines = 1,
    this.fillColor,
    this.contentPadding,
    this.style,
    this.hintStyle,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final hasAsterisk = widget.isRequired || (widget.label != null && widget.label!.contains('*'));
    final displayLabel = widget.label?.replaceAll('*', '').trim();

    final Widget? effectivePrefix = widget.icon != null
        ? Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              widget.icon,
              size: 18,
              color: const Color(0xFF64748B),
            ),
          )
        : widget.prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: widget.prefixIcon,
              )
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (displayLabel != null && displayLabel.isNotEmpty) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                  letterSpacing: 0.1,
                ),
              ),
              if (hasAsterisk) ...[
                const SizedBox(width: 3),
                const Text(
                  '*',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          obscureText: widget.isPassword ? _obscureText : false,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          minLines: widget.minLines,
          style: widget.style ??
              const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hintText,
            hintStyle: widget.hintStyle ??
                const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF94A3B8),
                ),
            prefixIcon: effectivePrefix,
            prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 42),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : widget.suffixIcon,
            filled: true,
            fillColor: widget.fillColor ?? const Color(0xFFF8FAFC),
            contentPadding: widget.contentPadding ??
                EdgeInsets.symmetric(
                  horizontal: effectivePrefix != null ? 10 : 14,
                  vertical: widget.maxLines > 1 ? 12 : 12,
                ),
            // Clean web-style single borders (removes any double border issues)
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
