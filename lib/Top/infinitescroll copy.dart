import 'package:flutter/material.dart';

// =====================================================
// 無限横スクロール Slider
// =====================================================
class InfiniteScrollSlider extends StatefulWidget {
  final List<Map<String, String>> items;
  final double height;

  const InfiniteScrollSlider({
    super.key,
    required this.items,
    this.height = 260,
  });

  @override
  State<InfiniteScrollSlider> createState() => _InfiniteScrollSliderState();
}

class _InfiniteScrollSliderState extends State<InfiniteScrollSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 80),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildRow() {
  // 2行に分けるため、itemsを半分に分割
  final half = (widget.items.length / 2).ceil();
  final firstRow = widget.items.sublist(0, half);
  final secondRow = widget.items.sublist(half);

  Widget buildItem(Map<String, String> item) {
    return Padding(
      padding: const EdgeInsets.only(right: 15, bottom: 10),
      child: Container(
        width: 260,
        height: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                item["image"]!,
                height: 160,
                width: 260,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item["title"]!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item["nickname"]!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  return Row(
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: firstRow.map(buildItem).toList(),
      ),
      const SizedBox(width: 15),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: secondRow.map(buildItem).toList(),
      ),
    ],
  );
}


  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: widget.height,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final double offset = -screenWidth * _controller.value;

            return Transform.translate(
              offset: Offset(offset, 0),
              child: Row(
                children: [
                  _buildRow(),
                  _buildRow(), // 2回並べて無限化
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
