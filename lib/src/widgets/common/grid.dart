import 'package:flutter/material.dart';

typedef GridItemBuilder<T> = Widget Function(BuildContext context, T item, int index);

class GenericGrid<T> extends StatelessWidget {
  final List<T> items;
  final GridItemBuilder<T> itemBuilder;
  final int? columns;
  final bool responsive;
  final double minItemWidth;
  final double spacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final void Function(T item, int index)? onItemTap;

  const GenericGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.columns,
    this.responsive = false,
    this.minItemWidth = 160,
    this.spacing = 8.0,
    this.childAspectRatio = 0.7,
    this.padding = const EdgeInsets.all(8.0),
    this.shrinkWrap = false,
    this.physics,
    this.onItemTap,
  }) : assert(columns == null || columns > 0);

  int _calculateColumns(double maxWidth) {
    if (columns != null) return columns!;
    if (!responsive) return 2;
    final int calculated = (maxWidth / minItemWidth).floor();
    return calculated.clamp(1, 12);
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: padding,
        child: Center(child: Text('No items', style: TextStyle(color: Colors.white))),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = _calculateColumns(constraints.maxWidth);
      return GridView.builder(
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics ?? (shrinkWrap ? const NeverScrollableScrollPhysics() : null),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          final child = itemBuilder(context, item, index);
          if (onItemTap != null) {
            return GestureDetector(
              onTap: () => onItemTap!(item, index),
              child: child,
            );
          } else {
            return child;
          }
        },
      );
    });
  }
}
