import 'dart:ui' as ui;

import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:recase/recase.dart';

class Spritesheet {
  const Spritesheet({
    required this.sprites,
    required this.bytes,
    required this.format,
    required this.width,
    required this.height,
    required this.pixelRatio,
  });

  final Map<String, Map<int, Rect>> sprites;
  final ByteData bytes;
  final ui.ImageByteFormat format;
  final double pixelRatio;
  final int width;
  final int height;
}

/// Spritesheet data that is optimized to generate code.
class CompiledSpritesheet {
  const CompiledSpritesheet({
    required this.fileName,
    required this.fieldNames,
    required this.pixelRatios,
    required this.sizes,
    required this.positions,
    required this.sizeStartOffset,
    required this.pixelRatioStartOffset,
  });

  factory CompiledSpritesheet.fromSpritesheets(List<Spritesheet> sheets) {
    sheets.sort((x, y) => x.pixelRatio.compareTo(y.pixelRatio));

    final names = sheets.first.sprites.keys.toList()..sort();
    final sizes = sheets.first.sprites.entries.first.value.keys.toList()
      ..sort((x, y) => x.compareTo(y));
    final fieldNames = <String>[];
    for (var i = 0; i < names.length; i++) {
      final name = ReCase(names[i]).camelCase;
      fieldNames.add(name);
    }
    final positions = <int>[];
    for (var sheet in sheets) {
      for (var name in names) {
        final position = sheet.sprites[name];
        for (var size in sizes) {
          final pos = position?[size];
          if (pos != null) {
            positions.add(pos.left.toInt());
            positions.add(pos.top.toInt());
          }
        }
      }
    }
    final pixelRatioStartOffset = <(double, int)>[];
    for (var i = 0; i < sheets.length; i++) {
      final sheet = sheets[i];
      final offset = i * names.length * sizes.length * 2;
      pixelRatioStartOffset.add((sheet.pixelRatio, offset));
    }

    final sizeStartOffset = <(int, int)>[];
    for (var i = 0; i < sizes.length; i++) {
      final size = sizes[i];
      final offset = i * names.length * 2;
      sizeStartOffset.add((size, offset));
    }

    return CompiledSpritesheet(
      fileName: names,
      fieldNames: fieldNames,
      sizes: sizes,
      pixelRatios: sheets.map((e) => e.pixelRatio).toList(),
      positions: positions,
      sizeStartOffset: sizeStartOffset,
      pixelRatioStartOffset: pixelRatioStartOffset,
    );
  }

  final List<(double, int)> pixelRatioStartOffset;
  final List<(int, int)> sizeStartOffset;
  final List<String> fileName;
  final List<String> fieldNames;
  final List<int> sizes;
  final List<double> pixelRatios;
  final List<int> positions;
}

sealed class AppState {
  const AppState();
}

class NotStartedState extends AppState {
  const NotStartedState({
    required this.name,
    required this.files,
    required this.sizes,
    required this.pixelRatios,
  });
  final String name;
  final List<double> pixelRatios;
  final List<int> sizes;
  final List<PlatformFile> files;
}

class RenderingState extends AppState {
  const RenderingState({
    required this.name,
    required this.files,
    required this.sizes,
    required this.pixelRatios,
  });
  final String name;
  final List<double> pixelRatios;
  final List<int> sizes;
  final List<PlatformFile> files;
}

class CompletedState extends AppState {
  const CompletedState({
    required this.name,
    required this.files,
    required this.sizes,
    required this.pixelRatios,
    required this.results,
    required this.dartCode,
    required this.compiled,
    required this.archive,
  });
  final String name;
  final List<double> pixelRatios;
  final List<int> sizes;
  final List<PlatformFile> files;
  final Map<double, Spritesheet> results;
  final CompiledSpritesheet compiled;
  final String dartCode;
  final Archive archive;
}

class FailedState extends AppState {
  const FailedState({
    required this.name,
    required this.files,
    required this.sizes,
    required this.pixelRatios,
    required this.error,
  });
  final String name;
  final List<double> pixelRatios;
  final List<int> sizes;
  final List<PlatformFile> files;
  final Object error;
}
