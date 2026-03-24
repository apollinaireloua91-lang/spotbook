import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SpotbookTextField extends StatefulWidget {
  const SpotbookTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final bool autofocus;

  @override
  State<SpotbookTextField> createState() => _SpotbookTextFieldState();
}

class _SpotbookTextFieldState extends State<SpotbookTextField>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final AnimationController _borderController;
  late final Animation<Color?> _borderColor;
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _borderColor = ColorTween(
      begin: AppColors.border,
      end: AppColors.blanc,
    ).animate(_borderController);

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _borderController.forward();
      } else {
        _borderController.reverse();
      }
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    _borderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _borderColor,
      builder: (context, _) {
        final hasError = widget.errorText != null;
        final borderColor = hasError ? AppColors.error : (_borderColor.value ?? AppColors.border);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null) ...[
              Text(
                widget.label!,
                style: const TextStyle(
                  color: AppColors.grisClair,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                obscureText: _obscure,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                enabled: widget.enabled,
                maxLines: widget.obscureText ? 1 : widget.maxLines,
                maxLength: widget.maxLength,
                autofocus: widget.autofocus,
                style: const TextStyle(
                  color: AppColors.blanc,
                  fontSize: 16,
                ),
                cursorColor: AppColors.blanc,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: const TextStyle(
                    color: AppColors.gris,
                    fontSize: 16,
                  ),
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(widget.prefixIcon, color: AppColors.gris, size: 20)
                      : null,
                  suffixIcon: widget.obscureText
                      ? GestureDetector(
                          onTap: () => setState(() => _obscure = !_obscure),
                          child: Icon(
                            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.gris,
                            size: 20,
                          ),
                        )
                      : widget.suffixIcon,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  counterText: '',
                ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 6),
              Text(
                widget.errorText!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
