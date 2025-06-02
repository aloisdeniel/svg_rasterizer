import 'dart:convert';
import 'dart:io';
import 'dart:math' show max;
import 'dart:ui' as ui;
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:recase/recase.dart';
import 'package:svg_rasterizer/spritesheet/action.dart';
import 'package:vector_graphics/src/listener.dart';

import 'state.dart';

Stream<AppState> update(
  BuildContext context,
  AppState initial,
  AppAction action,
) async* {
  if (initial is CompletedState) {
    switch (action) {
      case ExitAction():
        yield NotStartedState(
          name: initial.name,
          files: initial.files,
          sizes: initial.sizes,
          pixelRatios: initial.pixelRatios,
        );
        return;
      case DownloadAction():
        try {
          final encoder = ZipEncoder();
          final bytes = encoder.encode(initial.archive);

          print('Exported size: ${bytes.length} bytes');
          await FilePicker.platform.saveFile(
            dialogTitle: 'Save spritesheet',
            fileName: '${initial.name}.zip',
            type: FileType.custom,
            allowedExtensions: ['.zip'],
            bytes: Uint8List.fromList(bytes),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Fault: $e');
          }
        }
        return;
      case PickFilesAction():
      case GenerateAction():
        return;
    }
  }
  if (initial is NotStartedState) {
    switch (action) {
      case DownloadAction():
      case ExitAction():
        return;
      case PickFilesAction():
        final files = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['svg'],
          allowMultiple: true,
        );

        if (files != null) {
          yield NotStartedState(
            name: initial.name,
            files: [
              ...initial.files,
              ...files.files,
            ],
            sizes: initial.sizes,
            pixelRatios: initial.pixelRatios,
          );
        }

        return;
      case GenerateAction():
        yield RenderingState(
          name: initial.name,
          files: initial.files,
          sizes: initial.sizes,
          pixelRatios: initial.pixelRatios,
        );
        await Future.delayed(const Duration(milliseconds: 200));
        try {
          final fileName = ReCase(initial.name).snakeCase;
          final archive = Archive();
          final results = <double, Spritesheet>{};
          for (var pixelRatio in initial.pixelRatios) {
            final result = await rasterizeSheet(
              context,
              files: initial.files,
              sizeVariants: initial.sizes,
              pixelRatio: pixelRatio,
            );
            if (result != null) {
              results[pixelRatio] = result;
              final dir = pixelRatio == 1.0
                  ? ''
                  : ('${pixelRatio.toStringAsFixed(1)}x/');
              archive.add(
                ArchiveFile.bytes(
                  'assets/images/$dir$fileName.png',
                  result.bytes.buffer.asInt8List(),
                ),
              );
            }
          }
          final compiled = CompiledSpritesheet.fromSpritesheets(
            results.values.toList(),
          );
          // Dart
          final dartCode = dartTemplate('assets/icons.png', compiled);
          archive.add(
            ArchiveFile.string(
              'lib/src/widgets/$fileName.dart',
              dartCode,
            ),
          );
          yield CompletedState(
            name: initial.name,
            files: initial.files,
            sizes: initial.sizes,
            pixelRatios: initial.pixelRatios,
            results: results,
            compiled: compiled,
            dartCode: dartCode,
            archive: archive,
          );
        } catch (e, st) {
          if (kDebugMode) {
            print('Fault: $e');
            print(st);
          }
          yield NotStartedState(
            name: initial.name,
            files: initial.files,
            sizes: initial.sizes,
            pixelRatios: initial.pixelRatios,
          );
        }
        return;
    }
  }
}

/// Rasterizes all given SVG files into a single image.
Future<Spritesheet?> rasterizeSheet(
  BuildContext context, {
  required List<PlatformFile> files,
  required List<int> sizeVariants,
  required double pixelRatio,
  int? maxWidth,
  ui.ImageByteFormat? format,
}) async {
  final effectiveMaxWidth = switch (pixelRatio) {
    >= 2.0 => 4096,
    _ => 2048,
  };
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  var offset = Offset(1, 1);
  var sheetsize = Size.zero;
  final sprites = <String, Map<int, Rect>>{};
  for (var variant in sizeVariants) {
    final size = variant * pixelRatio;
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      Uint8List? bytes;

      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes case final bytes?) {
        final svg = utf8.decode(bytes);
        final loader = SvgStringLoader(svg);
        final vec = await loader.loadBytes(context);
        final info = await decodeVectorGraphics(
          vec,
          locale: Locale('en'),
          textDirection: TextDirection.ltr,
          clipViewbox: true,
          loader: loader,
        );

        final sizes = applyBoxFit(
            BoxFit.contain,
            info.size,
            Size(
              size.toDouble(),
              size.toDouble(),
            ));
        final destination = Alignment.center
            .inscribe(sizes.destination, offset & sizes.destination);

        canvas.save();
        canvas.translate(destination.left, destination.top);
        canvas.scale(sizes.destination.width / sizes.source.width);
        canvas.drawPicture(info.picture);
        canvas.restore();

        final byName = sprites.putIfAbsent(file.name, () => {});
        byName[variant] = destination;
      }
      // If last icon, we force line return
      if (i == files.length - 1) {
        offset += Offset(effectiveMaxWidth.toDouble(), 0);
      } else {
        offset += Offset(size + 1, 0);
      }
      if (offset.dx + size + 1 >= effectiveMaxWidth) {
        offset = Offset(0, offset.dy + size + 1);
      }
      sheetsize = Size(
        max(offset.dx + size + 1, sheetsize.width),
        max(offset.dy + size + 1, sheetsize.height),
      );
    }
  }
  final rasterPicture = recorder.endRecording();
  final image = rasterPicture.toImageSync(
    sheetsize.width.toInt(),
    sheetsize.height.toInt(),
  );

  final effectiveFormat = format ?? ui.ImageByteFormat.png;
  final bytes = await image.toByteData(format: effectiveFormat);

  if (bytes == null) {
    return null;
  }

  return Spritesheet(
    sprites: sprites,
    bytes: bytes,
    format: effectiveFormat,
    width: image.width,
    height: image.height,
    pixelRatio: pixelRatio,
  );
}

String dartTemplate(String assetPath, CompiledSpritesheet spritesheet) {
  return '''
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

$_spriteWidget

${_buildSprites(spritesheet)}

${_buildSpriteData(spritesheet, assetPath)}
''';
}

String _buildSpriteData(
  CompiledSpritesheet spritesheet,
  String assetPath,
) {
  final buffer = StringBuffer();
  buffer.writeln('class SpriteData {');

  // Constructor
  buffer.writeln('  const SpriteData(this.id, this.name);');
  buffer.writeln('  final int id;');
  buffer.writeln('  final String name;');

  // Shared image
  buffer.writeln('  // This image is shared between all sprites.');
  buffer.writeln(
      '  static ImageProvider image = const AssetImage(\'$assetPath\');');

  // Resolve method
  buffer.writeln('  Rect resolve(double size, double pixelRatio) {');
  buffer.writeln('    var index = id * 2;');
  buffer.writeln('    double resolvedSize = ${spritesheet.sizes.last}.0;');

  // Size offset
  buffer.writeln('    switch (size) {');
  for (var size in spritesheet.sizeStartOffset) {
    buffer.writeln('      case <= ${size.$1}:');
    buffer.writeln('        index += ${size.$2};');
    buffer.writeln('        resolvedSize = ${size.$1}.0;');
  }
  buffer.writeln('    }');

  // Pixel ratio offset
  buffer.writeln('    switch (pixelRatio) {');
  for (var sheet in spritesheet.pixelRatioStartOffset) {
    buffer.writeln('      case <= ${sheet.$1}:');
    buffer.writeln('        index += ${sheet.$2};');
    buffer.writeln('        resolvedSize *= ${sheet.$1};');
  }
  buffer.writeln('    }');

  buffer.writeln('    return Rect.fromLTWH(');
  buffer.writeln('      _pos[index].toDouble(),');
  buffer.writeln('      _pos[index + 1].toDouble(),');
  buffer.writeln('      resolvedSize,');
  buffer.writeln('      resolvedSize,');
  buffer.writeln('    );');
  buffer.writeln('  }');

  // Positions
  buffer.writeln('  /// All positions are stored consecutively in a list.');
  buffer.writeln('  static const _pos = [');
  buffer.writeln('    ${spritesheet.positions.join(', ')},');
  buffer.writeln('  ];');

  buffer.writeln('}');
  return buffer.toString();
}

String _buildSprites(CompiledSpritesheet spritesheet) {
  final buffer = StringBuffer();
  buffer.writeln('abstract class Sprites {');

  for (var i = 0; i < spritesheet.fieldNames.length; i++) {
    final name = spritesheet.fieldNames[i];
    buffer.writeln('  static const $name = SpriteData($i, \'$name\');');
  }

  buffer.writeln('  static const values = [');
  for (var name in spritesheet.fieldNames) {
    buffer.writeln('    $name,');
  }

  buffer.writeln('  ];');

  buffer.writeln('}');
  return buffer.toString();
}

const _spriteWidget = r'''
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
''';
