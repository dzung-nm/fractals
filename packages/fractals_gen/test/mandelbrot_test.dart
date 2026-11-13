import 'package:fractals_gen/mandelbrot.dart';
import 'package:test/test.dart';

void main() {
  group('generatePixelsIsolate', () {
    test('returns one opaque RGBA pixel per requested image pixel', () {
      final params = MandelbrotParams(
        width: 3,
        height: 2,
        centerX: 0,
        centerY: 0,
        spanX: 3,
        spanY: 2,
        maxIter: 20,
        paletteIndex: 0,
      );

      final pixels = generatePixelsIsolate(params, 0, 2);

      expect(pixels, hasLength(3 * 2 * 4));

      for (var i = 3; i < pixels.length; i += 4) {
        expect(pixels[i], 255);
      }
    });

    test('renders a point inside the main cardioid as opaque black', () {
      final params = MandelbrotParams(
        width: 1,
        height: 1,
        centerX: 0,
        centerY: 0,
        spanX: 0.1,
        spanY: 0.1,
        maxIter: 50,
        paletteIndex: 0,
      );

      final pixels = generatePixelsIsolate(params, 0, 1);

      expect(pixels, orderedEquals([0, 0, 0, 255]));
    });

    test('renders a point inside the period-2 bulb as opaque black', () {
      final params = MandelbrotParams(
        width: 1,
        height: 1,
        centerX: -1,
        centerY: 0,
        spanX: 0.1,
        spanY: 0.1,
        maxIter: 50,
        paletteIndex: 0,
      );

      final pixels = generatePixelsIsolate(params, 0, 1);

      expect(pixels, orderedEquals([0, 0, 0, 255]));
    });

    test('colors an escaping point and keeps alpha opaque', () {
      final params = MandelbrotParams(
        width: 1,
        height: 1,
        centerX: 2,
        centerY: 0,
        spanX: 0.1,
        spanY: 0.1,
        maxIter: 50,
        paletteIndex: 0,
      );

      final pixels = generatePixelsIsolate(params, 0, 1);

      expect(pixels, hasLength(4));
      expect(pixels.sublist(0, 3), isNot(orderedEquals([0, 0, 0])));
      expect(pixels[3], 255);
    });

    test('generates only the requested rows with local buffer offsets', () {
      final params = MandelbrotParams(
        width: 1,
        height: 3,
        centerX: 2,
        centerY: 0,
        spanX: 0.1,
        spanY: 3,
        maxIter: 50,
        paletteIndex: 0,
      );

      final allRows = generatePixelsIsolate(params, 0, 3);
      final lastRow = generatePixelsIsolate(params, 2, 3);

      expect(lastRow, hasLength(4));
      expect(lastRow, orderedEquals(allRows.sublist(8, 12)));
    });
  });

  test('generateImage', () async {
    final image = await generateImage(
      MandelbrotParams(
        width: 2,
        height: 2,
        centerX: 0,
        centerY: 0,
        spanX: 3,
        spanY: 3,
        maxIter: 20,
        paletteIndex: 1,
      ),
    );

    expect(image.pixels, hasLength(2 * 2 * 4));

    for (var i = 3; i < image.pixels.length; i += 4) {
      expect(image.pixels[i], 255);
    }

    expect(image.computeTime, isA<Duration>());

    expect(image.computeTime.inMicroseconds, greaterThanOrEqualTo(0));
  });
}
