import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:fractals_gen/color_palette.dart';
import 'package:fractals_gen/julia.dart' as julia;
import 'package:fractals_gen/mandelbrot.dart' as mandelbrot;
import 'package:fractals_gen/common.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'image_painter.dart';

enum FractalType {
  mandelbrot('Mandelbrot'),
  julia('Julia');

  final String label;

  const FractalType(this.label);
}

class FractalWidget extends StatefulWidget {
  final int width;
  final int height;
  final ColorPalette palette;
  final FractalType fractalType;

  const FractalWidget({
    super.key,
    required this.width,
    required this.height,
    required this.palette,
    required this.fractalType,
  });

  @override
  State<FractalWidget> createState() => _FractalWidgetState();
}

typedef FractalWidgetState = _FractalWidgetState;

class _FractalWidgetState extends State<FractalWidget> {
  ui.Image? _image;
  bool _isSavingImage = false;

  Duration? _lastComputeDuration;
  Duration? _lastRenderDuration;
  int _completedRenderCount = 0;

  int _renderRequestId = 0;
  Timer? _wheelRenderTimer;
  static const Duration _wheelRenderDebounce = Duration(milliseconds: 120);

  double _centerX = -0.75;
  double _centerY = 0.0;

  static const double _minSpanY = 0.0001;
  static const double _maxSpanY = 5.0;
  static const double _baseSpanY = 2.5;

  double _zoom = 1.0;

  double get _spanY => _baseSpanY / _zoom;
  double get _spanX => _spanY * widget.width / widget.height;
  int get _maxIter =>
      (120 + 40 * (math.log(_zoom) / math.ln2)).round().clamp(80, 800).toInt();

  double _scaleStartSpanY = _baseSpanY;
  double _gestureScale = 1.0;

  Offset _gestureStartFocalPoint = Offset.zero;
  Offset _gestureFocalPoint = Offset.zero;
  Offset _doubleTapPosition = Offset.zero;

  double _scaleAnchorX = 0.0;
  double _scaleAnchorY = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.fractalType == FractalType.julia) {
      _centerX = 0.0;
    }
    _renderFractal();
  }

  @override
  void didUpdateWidget(covariant FractalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width != widget.width ||
        oldWidget.height != widget.height ||
        oldWidget.palette != widget.palette ||
        oldWidget.fractalType != widget.fractalType) {
      _cancelPendingWheelRender();
      _renderFractal();
    }
  }

  void _cancelPendingWheelRender() {
    _wheelRenderTimer?.cancel();
    _wheelRenderTimer = null;
    _renderRequestId++;
  }

  void _scheduleWheelRender() {
    _wheelRenderTimer?.cancel();
    final requestId = ++_renderRequestId;
    _wheelRenderTimer = Timer(_wheelRenderDebounce, () {
      _wheelRenderTimer = null;
      if (!mounted || requestId != _renderRequestId) return;
      _renderFractal();
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _cancelPendingWheelRender();
    _scaleStartSpanY = _spanY;
    _gestureScale = 1.0;
    _gestureStartFocalPoint = details.localFocalPoint;
    _gestureFocalPoint = details.localFocalPoint;

    final unitsPerPixel = _scaleStartSpanY / widget.height;
    _scaleAnchorX =
        _centerX +
        (details.localFocalPoint.dx - widget.width / 2) * unitsPerPixel;
    _scaleAnchorY =
        _centerY +
        (details.localFocalPoint.dy - widget.height / 2) * unitsPerPixel;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _gestureScale = details.scale;
      _gestureFocalPoint = details.localFocalPoint;
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    final newSpanY = (_scaleStartSpanY / _gestureScale)
        .clamp(_minSpanY, _maxSpanY)
        .toDouble();
    final unitsPerPixel = newSpanY / widget.height;

    setState(() {
      _centerX =
          _scaleAnchorX -
          (_gestureFocalPoint.dx - widget.width / 2) * unitsPerPixel;
      _centerY =
          _scaleAnchorY -
          (_gestureFocalPoint.dy - widget.height / 2) * unitsPerPixel;
      _zoom = _baseSpanY / newSpanY;
    });
    _renderFractal();
  }

  void _zoomAt(Offset focalPoint, double zoomFactor) {
    final currentSpanY = _spanY;
    final newSpanY = (currentSpanY / zoomFactor)
        .clamp(_minSpanY, _maxSpanY)
        .toDouble();
    final oldUnitsPerPixel = currentSpanY / widget.height;
    final newUnitsPerPixel = newSpanY / widget.height;

    final anchorX =
        _centerX + (focalPoint.dx - widget.width / 2) * oldUnitsPerPixel;
    final anchorY =
        _centerY + (focalPoint.dy - widget.height / 2) * oldUnitsPerPixel;

    setState(() {
      _centerX =
          anchorX - (focalPoint.dx - widget.width / 2) * newUnitsPerPixel;
      _centerY =
          anchorY - (focalPoint.dy - widget.height / 2) * newUnitsPerPixel;
      _zoom = _baseSpanY / newSpanY;
    });
    _scheduleWheelRender();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final zoomFactor = math.exp(-event.scrollDelta.dy * 0.0015);
    _zoomAt(event.localPosition, zoomFactor);
  }

  Future<void> saveToImage() => _saveToImage();

  Future<void> _saveToImage() async {
    final image = _image;
    if (image == null || _isSavingImage) return;
    setState(() => _isSavingImage = true);

    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Could not encode the Mandelbrot image as PNG.');
      }

      final pngBytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      final savedPath = await FileSaver.instance.saveAs(
        name: 'mandelbrot',
        bytes: pngBytes,
        fileExtension: 'png',
        mimeType: MimeType.png,
        dialogTitle: 'Save Mandelbrot image',
      );

      if (!mounted) return;
      final message = savedPath == null
          ? 'Image save canceled.'
          : 'Image saved: $savedPath';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save image: $error')));
    } finally {
      if (mounted) setState(() => _isSavingImage = false);
    }
  }

  Future<void> _renderFractal() async {
    final stopwatch = Stopwatch()..start();

    final width = widget.width;
    final height = widget.height;
    final maxIter = _maxIter;
    final centerX = _centerX;
    final centerY = _centerY;
    final spanX = _spanX;
    final spanY = _spanY;

    final requestId = ++_renderRequestId;
    final paletteIndex = widget.palette.index;

    final FractalImage fractalImage;

    if (widget.fractalType == FractalType.julia) {
      fractalImage = await julia.generateImage(
        julia.JuliaParams(
          width: width,
          height: height,
          centerX: centerX,
          centerY: centerY,
          spanX: spanX,
          spanY: spanY,
          maxIter: maxIter,
          paletteIndex: paletteIndex,
          juliaCRe: -0.5125,
          juliaCIm: 0.5213,
        ),
      );
    } else {
      fractalImage = await mandelbrot.generateImage(
        mandelbrot.MandelbrotParams(
          width: width,
          height: height,
          centerX: centerX,
          centerY: centerY,
          spanX: spanX,
          spanY: spanY,
          maxIter: maxIter,
          paletteIndex: paletteIndex,
        ),
      );
    }

    if (!mounted || requestId != _renderRequestId) return;

    final buffer = await ui.ImmutableBuffer.fromUint8List(fractalImage.pixels);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();

    if (!mounted || requestId != _renderRequestId) {
      frame.image.dispose();
      return;
    }

    stopwatch.stop();

    final oldImage = _image;
    setState(() {
      _image = frame.image;
      _lastComputeDuration = fractalImage.computeTime;
      _lastRenderDuration = stopwatch.elapsed;
      _completedRenderCount++;
      _gestureScale = 1.0;
      _gestureStartFocalPoint = Offset.zero;
      _gestureFocalPoint = Offset.zero;
    });

    if (oldImage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldImage.dispose();
      });
    }

    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
  }

  @override
  void dispose() {
    _wheelRenderTimer?.cancel();
    _image?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '—';
    return '${(duration.inMicroseconds / 1000).toStringAsFixed(1)} ms';
  }

  Widget _buildPerformanceHud() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.40),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Compute:  ${_formatDuration(_lastComputeDuration)}'),
              Text('Render:   ${_formatDuration(_lastRenderDuration)}'),
              Text('Size:     ${widget.width} × ${widget.height} px'),
              Text('maxIter:  $_maxIter'),
              Text('Renders:  $_completedRenderCount'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        onDoubleTapDown: (details) {
          _doubleTapPosition = details.localPosition;
        },
        onDoubleTap: () => _zoomAt(_doubleTapPosition, 2.0),
        child: SizedBox(
          width: widget.width.toDouble(),
          height: widget.height.toDouble(),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRect(
                  child: _image == null
                      ? const Center(child: CircularProgressIndicator())
                      : Transform.translate(
                          offset: Offset(
                            _gestureFocalPoint.dx -
                                _gestureStartFocalPoint.dx * _gestureScale,
                            _gestureFocalPoint.dy -
                                _gestureStartFocalPoint.dy * _gestureScale,
                          ),
                          child: Transform.scale(
                            scale: _gestureScale,
                            alignment: Alignment.topLeft,
                            child: CustomPaint(
                              size: Size(
                                widget.width.toDouble(),
                                widget.height.toDouble(),
                              ),
                              painter: ImagePainter(_image!),
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IgnorePointer(child: _buildPerformanceHud()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
