import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class Sprite extends LeafRenderObjectWidget {
  const Sprite({
    super.key,
    required this.data,
    this.size = 24,
  });

  final double size;
  final SpriteData data;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return _Render(
      image: SpriteData.image,
      source: data.resolve(size, pixelRatio),
      sizeValue: size,
    )..resolveImage(context);
  }

  @override
  // ignore: library_private_types_in_public_api
  void updateRenderObject(BuildContext context, _Render renderObject) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    renderObject
      ..imageProvider = SpriteData.image
      ..source = data.resolve(size, pixelRatio)
      ..sizeValue = size
      ..resolveImage(context);
  }
}

class _Render extends RenderBox {
  _Render({
    required ImageProvider image,
    required Rect source,
    required double sizeValue,
  })  : _source = source,
        _imageProvider = image,
        _sizeValue = sizeValue;

  ImageProvider _imageProvider;
  Rect _source;
  double _sizeValue;

  set sizeValue(double value) {
    if (_sizeValue == value) return;
    _sizeValue = value;
    markNeedsLayout();
  }

  set source(Rect value) {
    if (_source == value) return;
    _source = value;
    markNeedsPaint();
  }

  set imageProvider(ImageProvider value) {
    if (_imageProvider == value) return;
    _imageProvider = value;
    markNeedsPaint();
  }

  ui.Image? _image;
  ImageStream? _imageStream;
  ImageStreamListener? _listener;

  void resolveImage(BuildContext context) {
    final ImageStream newStream = _imageProvider.resolve(
      createLocalImageConfiguration(context),
    );

    if (_imageStream?.key == newStream.key) return;

    _imageStream?.removeListener(_listener!);

    _listener =
        ImageStreamListener((ImageInfo imageInfo, bool synchronousCall) {
      _image = imageInfo.image;
      markNeedsPaint();
    });

    _imageStream = newStream;
    _imageStream!.addListener(_listener!);
  }

  @override
  void detach() {
    _imageStream?.removeListener(_listener!);
    super.detach();
  }

  @override
  void performLayout() {
    size = constraints.constrain(Size.square(_sizeValue));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_image == null) return;

    final canvas = context.canvas;

    final dst = offset & size;
    canvas.drawImageRect(_image!, _source, dst, Paint());
  }
}

abstract class Sprites {
  static const flag = SpriteData(0, 'flag');

  static const values = [
    flag,
  ];
}

class SpriteData {
  const SpriteData(this.id, this.name);
  final int id;
  final String name;

  // This image is shared between all sprites.
  static ImageProvider image = const AssetImage('images/icons.png');

  Rect resolve(double size, double pixelRatio) {
    var index = id * 2;
    var resolvedSize = 24.0;
    switch (size) {
      case >= 32:
        resolvedSize = 32.0;
        index += 12;
    }
    switch (pixelRatio) {
      case >= 3:
        index += 25;
        resolvedSize *= 3;
    }
    return Rect.fromLTWH(
      _pos[index].toDouble(),
      _pos[index + 1].toDouble(),
      resolvedSize,
      resolvedSize,
    );
  }

  /// All positions are stored consecutively in a list.
  static const _pos = [
    // @1x
    // 24
    0, 0,
    // 32
    0, 24,
    // @2x
    // 24
    0, 0,
    // 32
    0, 32,
  ];
}
