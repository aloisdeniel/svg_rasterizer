import 'package:flutter/widgets.dart';
import 'package:svg_rasterizer/spritesheet/action.dart' as sa;
import 'package:svg_rasterizer/spritesheet/update.dart' as su;

import 'state.dart';

Stream<AppState> update(
  BuildContext context,
  AppState initial,
  Object action,
) async* {
  if (initial is InitializedState) {
    switch (action) {
      case sa.AppAction():
        await for (var element in su.update(
          context,
          initial.spritesheet,
          action,
        )) {
          yield InitializedState(
            spritesheet: element,
          );
        }
        return;
    }
  }
}
