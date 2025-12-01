import 'package:flutter/material.dart';

class ReviewImageGallery extends StatelessWidget {
  final List<String> images;

  const ReviewImageGallery({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use a fixed height or aspect ratio container
        // For simplicity, let's use a height that feels good, e.g., 200 or 250
        // Or we can use AspectRatio.
        // The user request showed a rectangular region.

        return SizedBox(
          height: 250,
          width: constraints.maxWidth,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildLayout(context),
          ),
        );
      },
    );
  }

  Widget _buildLayout(BuildContext context) {
    int count = images.length;
    if (count == 1) {
      return _buildImage(context, images[0], 0, isFull: true);
    } else if (count == 2) {
      return Row(
        children: [
          Expanded(child: _buildImage(context, images[0], 0)),
          const SizedBox(width: 2),
          Expanded(child: _buildImage(context, images[1], 1)),
        ],
      );
    } else {
      // 3 or more
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: _buildImage(context, images[0], 0),
          ),
          const SizedBox(width: 2),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(child: _buildImage(context, images[1], 1)),
                const SizedBox(height: 2),
                Expanded(
                  child: count > 3
                      ? _buildMoreOverlay(context, images[2], 2, count - 3)
                      : _buildImage(context, images[2], 2),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildImage(BuildContext context, String url, int index,
      {bool isFull = false}) {
    return GestureDetector(
      onTap: () => _openFullScreen(context, index),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.grey[900],
            child: const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white24),
            ),
          );
        },
        errorBuilder: (ctx, err, stack) => Container(
          color: Colors.grey[900],
          child: const Icon(Icons.broken_image, color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildMoreOverlay(
      BuildContext context, String url, int index, int moreCount) {
    return GestureDetector(
      onTap: () => _openFullScreen(context, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) =>
                Container(color: Colors.grey[900]),
          ),
          Container(
            color: Colors.black54,
            child: Center(
              child: Text(
                '+$moreCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullScreen(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _FullScreenGallery(images: images, initialIndex: initialIndex),
      ),
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenGallery({required this.images, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
