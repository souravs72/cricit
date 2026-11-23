import 'package:cricit/core/widgets/video_frame_math.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const shortRatio = 9 / 16;

  group('computeVideoFrame', () {
    test('cover frame always covers the viewport on tall phones', () {
      const viewport = Size(360, 780); // ~20:9 viewport
      final frame = computeVideoFrame(viewport, shortRatio, cover: true);
      expect(frame.width, greaterThanOrEqualTo(viewport.width));
      expect(frame.height, greaterThanOrEqualTo(viewport.height));
      expect(frame.width / frame.height, closeTo(shortRatio, 0.001));
    });

    test('cover frame always covers the viewport on short/wide phones', () {
      const viewport = Size(411, 560); // small phone with big chrome
      final frame = computeVideoFrame(viewport, shortRatio, cover: true);
      expect(frame.width, greaterThanOrEqualTo(viewport.width));
      expect(frame.height, greaterThanOrEqualTo(viewport.height));
    });

    test('cover frame is oversized so YouTube header/footer chrome is cropped',
        () {
      const viewport = Size(360, 640); // exactly 9:16
      final frame = computeVideoFrame(viewport, shortRatio, cover: true);
      expect(frame.height, greaterThan(viewport.height * 1.1));
    });

    test('fit frame is fully contained in the viewport', () {
      const viewport = Size(360, 780);
      final frame = computeVideoFrame(viewport, shortRatio, cover: false);
      expect(frame.width, lessThanOrEqualTo(viewport.width));
      expect(frame.height, lessThanOrEqualTo(viewport.height));
      expect(frame.width / frame.height, closeTo(shortRatio, 0.001));
    });

    test('fit frame for a landscape video is limited by width', () {
      const viewport = Size(360, 780);
      final frame = computeVideoFrame(viewport, 16 / 9, cover: false);
      expect(frame.width, closeTo(360, 0.001));
      expect(frame.height, closeTo(360 * 9 / 16, 0.001));
    });

    test('degenerate viewport returns Size.zero', () {
      expect(computeVideoFrame(Size.zero, shortRatio, cover: true), Size.zero);
      expect(
        computeVideoFrame(const Size(300, 0), shortRatio, cover: false),
        Size.zero,
      );
    });

    test('invalid ratio falls back to 9:16', () {
      const viewport = Size(360, 640);
      final frame = computeVideoFrame(viewport, 0, cover: false);
      expect(frame.width / frame.height, closeTo(9 / 16, 0.001));
    });
  });
}
