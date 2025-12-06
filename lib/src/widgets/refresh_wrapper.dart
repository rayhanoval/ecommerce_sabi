import 'package:flutter/material.dart';

typedef RefreshCallbackAsync = Future<void> Function();

class RefreshWrapper extends StatelessWidget {
  final Widget child;
  final RefreshCallbackAsync onRefresh;
  final EdgeInsetsGeometry? padding;

  const RefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            width: double.infinity,
            child: child,
          ),
        ),
      ),
    );
  }
}