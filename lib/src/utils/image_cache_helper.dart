import 'package:flutter/widgets.dart';

class ImageCacheHelper {
  /// Evict specific network image by URL
  static Future<void> evictImageByUrl(String url) async {
    try {
      final provider = NetworkImage(url);
      await provider.evict();
      // also try to clear from global imageCache
      PaintingBinding.instance.imageCache.evict(provider, includeLive: true);
    } catch (e) {
      // ignore
    }
  }

  /// Clear entire image cache (use sparingly)
  static void clearGlobalCache() {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (e) {
      // ignore
    }
  }
}
