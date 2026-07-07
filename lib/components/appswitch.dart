import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/utils/constants.dart';

class AppSwitch extends StatefulWidget {
  final bool initialValue;
  final ValueChanged<bool> onToggle;

  const AppSwitch({
    super.key,
    required this.initialValue,
    required this.onToggle,
  });

  @override
  State<AppSwitch> createState() => _AppSwitchState();
}

class _AppSwitchState extends State<AppSwitch> {
  late bool isOn;

  @override
  void initState() {
    super.initState();
    isOn = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isMobile = Breakpoints.isMobile(width);
    final isWideShortPhone = isMobile && width >= 500 && size.height <= 760;
    final borderWidth = isMobile ? 1.w : 1.0;
    final borderRadius = isWideShortPhone
        ? 24.0
        : isMobile
        ? 30.r
        : 30.0;
    final switchWidth = isWideShortPhone
        ? 42.0
        : isMobile
        ? 50.w
        : 50.0;
    final switchHeight = isWideShortPhone
        ? 18.0
        : isMobile
        ? 20.h
        : 22.0;
    final toggleSize = isWideShortPhone
        ? 16.0
        : isMobile
        ? 18.w
        : 20.0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: appToggleColor, width: borderWidth),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: FlutterSwitch(
        value: isOn,
        onToggle: (val) {
          setState(() => isOn = val);
          widget.onToggle(val);
        },
        width: switchWidth,
        height: switchHeight,
        toggleSize: toggleSize,
        padding: 0.5,
        activeColor: appToggleColor,
        inactiveColor: Colors.white,
        toggleColor: Colors.white,
        inactiveToggleColor: appToggleColor,
        borderRadius: borderRadius,
        showOnOff: false,
        toggleBorder: Border.all(color: appToggleColor, width: borderWidth),
      ),
    );
  }
}
