import 'package:svg_rasterizer/spritesheet/state.dart' as s;

sealed class AppState {
  const AppState();
}

class InitializedState extends AppState {
  const InitializedState({
    required this.spritesheet,
  });
  final s.AppState spritesheet;
}
