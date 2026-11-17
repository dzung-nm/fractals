// Escape radius squared for Mandelbrot and Julia sets.
const escapeRadiusSquared = 256.0;

// kIsWeb is true when the app is compiled to run on the web.
// This is same as the kIsWeb constant in Flutter's foundation library
// but we define it here to avoid importing Flutter in this package.
const bool kIsWeb = identical(0, 0.0);

// Number of smooth-iteration steps in one palette cycle.
const double kColorPeriod = 48.0;
