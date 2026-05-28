import 'package:flutter/material.dart';

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
  int _charCount = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 20),
        boxShadow: widget.boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
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
                      width: 20,
                      height: 20,
                      color: widget.iconColor ?? Colors.black,
                    )
                  : Icon(
                      widget.icon,
                      size: 20,
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
            maxLines: widget.maxLines ?? 5,
            maxLength: widget.maxLength,
            onChanged: (val) {
              setState(() => _charCount = val.length);
              if (widget.onChanged != null) widget.onChanged!(val);
            },
            validator: widget.validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              counterText: "",
              hintText: widget.hintText,
              hintStyle: const TextStyle(color: Colors.grey,height: 1.2),
              border: InputBorder.none,

            ),
          ),
        ],
      ),
    );
  }
}
