import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:svg_rasterizer/app/view.dart';
import 'package:svg_rasterizer/dispatcher.dart';

void main() {
  runApp(const RasterizerApp());
}

class RasterizerApp extends StatelessWidget {
  const RasterizerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return StateProvider(
      child: ShadApp(
        title: 'Rasterizer',
        themeMode: ThemeMode.dark,
        darkTheme: ShadThemeData(
          brightness: Brightness.dark,
          colorScheme: const ShadSlateColorScheme.dark(),
        ),
        home: const Home(),
      ),
    );
  }
}
