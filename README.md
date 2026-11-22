# Fractals

A cross-platform Flutter application for exploring Mandelbrot and Julia sets. The app renders fractals in real time, supports zooming and pan-like navigation, provides several color palettes, and can export the current view as a PNG image.

This repository contains:

- `apps/fractals`: the Flutter desktop, mobile, and web application
- `packages/fractals_gen`: the Dart fractal-generation library

## Features

- Mandelbrot and Julia set rendering
- Interactive zoom with pinch gestures and mouse-wheel input
- Adjustable maximum iteration counts
- Configurable Julia set real and imaginary components
- Inferno, Ocean, and Aurora color palettes
- Optional performance HUD
- PNG image export
- Parallel rendering for native and web platforms

## Prerequisites

- Flutter SDK with Dart 3.13 or newer
- Melos for managing the workspace

Install Melos globally if it is not already available:

```bash
dart pub global activate melos
```

## Getting Started

From the repository root, install workspace dependencies:

```bash
dart pub get
```

Run the application on macOS:

```bash
melos run dev
```

You can also run the app directly:

```bash
cd apps/fractals
flutter run -d macos
```

To list other available devices:

```bash
flutter devices
```

Then start the app with a device ID:

```bash
flutter run -d <device-id>
```

## Controls

Open the menu from the button in the upper-left corner to:

- switch between Mandelbrot and Julia fractals
- edit the Julia set constant
- change the maximum iteration count
- select a color palette
- show or hide the performance HUD
- reset the view
- save the current image

### Navigation

- **Zoom:** pinch on touch devices or scroll the mouse wheel
- **Reset:** use the Reset action in the menu
- **Save:** use the Save Image action in the menu

## Fractal Library

The `fractals_gen` package exposes Mandelbrot and Julia generators, color palettes, and platform-specific parallel runners.

It can also be run from the command line to generate sample images:

```bash
cd packages/fractals_gen
dart run bin/mandelbrot.dart
dart run bin/julia.dart
```

Generated images are written to the package's `data` directory.

## Development

Format all workspace packages:

```bash
melos run format
```

Analyze all workspace packages:

```bash
melos run analyze
```

Run tests in packages that contain a `test` directory:

```bash
melos run test
```

The app tests cover menu interactions, palette selection, iteration controls, Julia parameters, performance display, action buttons, and image rendering behavior.
