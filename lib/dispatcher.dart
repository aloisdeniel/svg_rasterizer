import 'package:flutter/material.dart';
import 'package:svg_rasterizer/app/state.dart';
import 'package:svg_rasterizer/app/update.dart';
import 'package:svg_rasterizer/spritesheet/state.dart' as s;

extension DispatcherExtension on BuildContext {
  /// Dispatches an action to the app state.
  ///
  /// This method is used to dispatch actions to the app state. It is a
  /// convenience method that allows you to call the [dispatch] method on the
  /// [StateProvider] without having to explicitly pass the context.
  void dispatch(Object action) {
    StateProvider.dispatch(this, action);
  }
}

class StateProvider extends StatefulWidget {
  const StateProvider({
    super.key,
    required this.child,
  });

  final Widget child;

  static AppState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_Provider>()!.state;
  }

  static void dispatch(BuildContext context, Object action) {
    return context
        .dependOnInheritedWidgetOfExactType<_Provider>()!
        .onDispatch(action);
  }

  @override
  State<StateProvider> createState() => _StateProviderState();
}

class _StateProviderState extends State<StateProvider> {
  AppState _state = InitializedState(
    spritesheet: s.NotStartedState(
      name: 'Sprite',
      sizes: [12, 24, 32],
      files: [],
      pixelRatios: [1.0, 2.0, 3.0],
    ),
  );

  void _onDispatch(Object action) async {
    await for (var element in update(context, _state, action)) {
      setState(() {
        _state = element;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Provider(
      state: _state,
      onDispatch: _onDispatch,
      child: widget.child,
    );
  }
}

class _Provider extends InheritedWidget {
  const _Provider({
    required this.state,
    required this.onDispatch,
    required super.child,
  });
  final AppState state;
  final ValueChanged<Object> onDispatch;

  @override
  bool updateShouldNotify(_Provider oldWidget) {
    return state != oldWidget.state;
  }
}
