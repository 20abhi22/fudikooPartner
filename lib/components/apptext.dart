import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/translator_service.dart';

class AppText extends StatefulWidget {

  final String text;
  final double size;
  final FontWeight fontWeight;
  final FontStyle? fontStyle;
  final Color? color;
  final bool? isCentered;
  final double? lineSpacing;
  final bool? softWrap;
  final int? maxLines;
  final TextOverflow? overflow;


  const AppText({
    super.key,
    required this.text,
    required this.size,
    required this.fontWeight,
    this.fontStyle,
    this.color,
    this.isCentered,
    this.lineSpacing, 
    this.softWrap,
    this.maxLines,
    this.overflow,
  });

  @override
  State<AppText> createState() => _AppTextState();
}

class _AppTextState extends State<AppText> {
  String _translated = '';

  @override
  void initState() {
    super.initState();
    _translate();
  }

  @override
  void didUpdateWidget(AppText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // re-translate if language changed
    if (oldWidget.text != widget.text) _translate();
  }

   Future<void> _translate() async {
    final result = await TranslatorService.translate(widget.text);
    if (mounted) setState(() => _translated = result);
  }
  @override
  Widget build(BuildContext context) {
    
    return Text(

      _translated.isEmpty ? widget.text : _translated,
      textAlign: widget.isCentered ?? false ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontStyle: widget.fontStyle ?? FontStyle.normal,
        fontSize: widget.size.sp,
        fontWeight: widget.fontWeight,
        color: widget.color ??appTextColor,
        height: widget.lineSpacing ?? 1.2,
      ),
      softWrap: widget.softWrap ?? (widget.maxLines != null),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}