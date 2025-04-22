import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:svg_rasterizer/app/state.dart';
import 'package:svg_rasterizer/dispatcher.dart';
import 'package:svg_rasterizer/spritesheet/view.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final state = StateProvider.of(context);
    return Scaffold(
      body: Layout(
        child: switch (state) {
          InitializedState() => RasterizerView(),
        },
      ),
    );
  }
}

class Layout extends StatelessWidget {
  const Layout({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Header(),
        Container(
          height: 1,
          color: ShadTheme.of(context).colorScheme.border,
        ),
        Expanded(child: child),
      ],
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Title(),
        ],
      ),
    );
  }
}

class Toolbar extends StatelessWidget {
  const Toolbar({
    super.key,
    required this.body,
    required this.actions,
  });

  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: body),
        if (actions.isNotEmpty) ...[
          Container(
            height: 1,
            color: ShadTheme.of(context).colorScheme.border,
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: actions,
            ),
          ),
        ],
      ],
    );
  }
}

class Title extends StatelessWidget {
  const Title({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180),
      child: ShadSelect<String>(
        placeholder: const Text('F.SVG.U'),
        options: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 6, 6, 6),
            child: Text(
              'Utils',
              style: theme.textTheme.muted.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.popoverForeground,
              ),
              textAlign: TextAlign.start,
            ),
          ),
          ShadOption(
            value: 'Spritesheet',
            child: Text('Spritesheet'),
          ),
        ],
        selectedOptionBuilder: (context, value) => Text(value),
        onChanged: print,
      ),
    );
  }
}
