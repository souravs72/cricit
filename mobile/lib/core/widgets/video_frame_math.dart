import 'dart:math' as math;
import 'dart:ui' show Size;

/// YouTube draws its own chrome (title bar, channel avatar, "Shorts" logo,
/// copy-link icon) inside the embedded player frame. We cannot switch it off,
/// so in cover mode the frame is rendered this much larger than needed and
/// clipped to the viewport, which crops that chrome out of sight.
const double kYouTubeChromeCropScale = 1.18;

const double _fallbackRatio = 9 / 16;

/// Pure sizing for the embedded player frame inside a [viewport].
///
/// * `cover: true`  -> smallest frame of [ratio] that covers the viewport,
///   enlarged by [kYouTubeChromeCropScale] (edge-to-edge reel, no bars).
/// * `cover: false` -> largest frame of [ratio] that fits inside the viewport.
///
/// The caller centres the frame and clips it to the viewport.
Size computeVideoFrame(Size viewport, double ratio, {required bool cover}) {
  if (!viewport.width.isFinite ||
      !viewport.height.isFinite ||
      viewport.width <= 0 ||
      viewport.height <= 0) {
    return Size.zero;
  }
  final r = (ratio.isFinite && ratio > 0) ? ratio : _fallbackRatio;

  if (cover) {
    final height =
        math.max(viewport.height, viewport.width / r) * kYouTubeChromeCropScale;
    return Size(height * r, height);
  }

  final width = math.min(viewport.width, viewport.height * r);
  return Size(width, width / r);
}
