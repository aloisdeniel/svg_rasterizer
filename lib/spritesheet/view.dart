// ignore_for_file: sort_child_properties_last

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:svg_rasterizer/app/state.dart';
import 'package:svg_rasterizer/app/view.dart';
import 'package:svg_rasterizer/dispatcher.dart';
import 'package:svg_rasterizer/spritesheet/action.dart';
import 'package:svg_rasterizer/spritesheet/state.dart';

class RasterizerView extends StatelessWidget {
  const RasterizerView({super.key});
  @override
  Widget build(BuildContext context) {
    final state = StateProvider.of(context) as InitializedState;
    return switch (state.spritesheet) {
      NotStartedState s => NotStarted(s),
      RenderingState s => Rendering(s),
      CompletedState s => Completed(s),
      FailedState s => NotStarted(
          NotStartedState(
            name: s.name,
            files: s.files,
            sizes: s.sizes,
            pixelRatios: s.pixelRatios,
          ),
        ),
    };
  }
}

class Rendering extends StatelessWidget {
  const Rendering(this.state, {super.key});

  final RenderingState state;

  @override
  Widget build(BuildContext context) {
    return Toolbar(
      actions: [
        CircularProgressIndicator(),
      ],
      body: ListView(
        children: [
          for (var file in state.files)
            ListTile(
              title: Text(file.name),
            ),
        ],
      ),
    );
  }
}

class NotStarted extends StatelessWidget {
  const NotStarted(
    this.state, {
    super.key,
  });

  final NotStartedState state;

  @override
  Widget build(BuildContext context) {
    return Toolbar(
      actions: [
        ShadButton.outline(
          child: const Text('Import SVG files'),
          leading: Icon(Icons.file_open),
          onPressed: () => context.dispatch(PickFilesAction()),
        ),
        Spacer(),
        if (state.files.isNotEmpty)
          ShadButton(
            trailing: Icon(Icons.build),
            onPressed: () => context.dispatch(GenerateAction(
              files: state.files,
              pixelRatios: state.pixelRatios,
              sizes: state.sizes,
            )),
            child: const Text('Generate'),
          ),
      ],
      body: state.files.isEmpty
          ? Center(child: Text('No file selected'))
          : ShadTable.list(
              header: const [
                ShadTableCell.header(child: Text('File')),
                ShadTableCell.header(
                  alignment: Alignment.centerRight,
                  child: Text('Actions'),
                ),
              ],
              columnSpanExtent: (index) {
                if (index == 1) {
                  return RemainingTableSpanExtent();
                }
                return FractionalSpanExtent(0.8);
              },
              children: state.files.map(
                (invoice) => [
                  ShadTableCell(
                    child: Text(
                      invoice.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ShadTableCell(
                      alignment: Alignment.centerRight,
                      child: ShadButton.outline(
                        child: Text('Delete'),
                      )),
                ],
              ),
            ),
    );
  }
}

class Completed extends StatelessWidget {
  const Completed(
    this.state, {
    super.key,
  });

  final CompletedState state;

  @override
  Widget build(BuildContext context) {
    return Toolbar(
      actions: [
        ShadButton.destructive(
          leading: Icon(Icons.arrow_back),
          onPressed: () => context.dispatch(ExitAction()),
          child: const Text('Cancel'),
        ),
        Spacer(),
        ShadButton(
          trailing: Icon(Icons.download),
          onPressed: () => context.dispatch(DownloadAction()),
          child: const Text('Download'),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var file in state.archive.files)
            ShadCard(
              title: Text(file.name),
              description: Text(
                  '${(file.content.lengthInBytes / 1024).toStringAsFixed(2)}kb'),
              child: switch (file.name.split('.').last) {
                'png' => Image.memory(file.content),
                _ => SelectableText(
                    utf8.decode(file.content),
                    style: TextStyle(
                      fontFamily: 'console',
                      color: Colors.white,
                    ),
                  ),
              },
            ),
        ],
      ),
    );
  }
}
