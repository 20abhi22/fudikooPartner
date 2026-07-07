import 'package:flutter/material.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';

class DescriptionTextArea extends StatefulWidget {
  final String hintText;
  final int maxLength;
  final IconData icon;
  final void Function(String)? onChanged;
  final Color? iconColor;
  final int? maxLines;
  final TextEditingController? controller;
  final String? iconImagePath;
  final String? Function(String?)? validator;
  final List<BoxShadow>? boxShadow;
  final Color? backgroundColor;
  final double? borderRadius;

  const DescriptionTextArea({
    super.key,
    required this.hintText,
    this.maxLength = 450,
    this.icon = Icons.list,
    this.onChanged,
    this.iconColor,
    this.controller,
    this.maxLines,
    this.iconImagePath,
    this.validator,
    this.boxShadow,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  State<DescriptionTextArea> createState() => _DescriptionTextAreaState();
}

class _DescriptionTextAreaState extends State<DescriptionTextArea> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWideShortPhone = Breakpoints.isWideShortPhone(size);
    final padding = isWideShortPhone ? 12.0 : 16.0;
    final iconSize = isWideShortPhone ? 18.0 : 20.0;
    final maxLines = widget.maxLines ?? (isWideShortPhone ? 3 : 5);
    final hintFontSize = isWideShortPhone ? 13.0 : null;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(
          widget.borderRadius ?? (isWideShortPhone ? 14 : 20),
        ),
        boxShadow:
            widget.boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 0),
              ),
            ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              widget.iconImagePath != null
                  ? Image.asset(
                      widget.iconImagePath!,
                      width: iconSize,
                      height: iconSize,
                      color: widget.iconColor ?? Colors.black,
                    )
                  : Icon(
                      widget.icon,
                      size: iconSize,
                      color: widget.iconColor ?? Colors.black,
                    ),
              // const Spacer(),
              // Text(
              //   '$_charCount/${widget.maxLength}',
              //   style: const TextStyle(color: Colors.grey, fontSize: 12),
              // ),
            ],
          ),
          const SizedBox(width: 8),
          TextFormField(
            controller: widget.controller,
            maxLines: maxLines,
            maxLength: widget.maxLength,
            onChanged: (val) {
              if (widget.onChanged != null) widget.onChanged!(val);
            },
            validator: widget.validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              counterText: "",
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Colors.grey,
                height: 1.2,
                fontSize: hintFontSize,
              ),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}
