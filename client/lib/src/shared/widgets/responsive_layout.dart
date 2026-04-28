import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;
  final double breakpoint;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
    this.breakpoint = 900,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return mobile;
        }

        return desktop;
      },
    );
  }
}