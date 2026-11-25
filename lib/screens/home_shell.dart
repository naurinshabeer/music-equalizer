import 'package:flutter/material.dart';

import '../audio_controller.dart';
import '../theme.dart';
import 'albums_screen.dart';
import 'equalizer_screen.dart';
import 'player_screen.dart';

/// Bottom-nav container: Albums | Now Playing | Equalizer.
/// IndexedStack keeps each tab alive, so nothing reloads when switching.
class HomeShell extends StatefulWidget {
  final AudioController c;
  const HomeShell({super.key, required this.c});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          AlbumsScreen(c: widget.c, onOpenPlayer: () => _go(1)),
          PlayerScreen(c: widget.c, onOpenEq: () => _go(2)),
          EqualizerScreen(c: widget.c),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        backgroundColor: C.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: C.copper.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.album_outlined),
            selectedIcon: Icon(Icons.album, color: C.copper),
            label: 'Albums',
          ),
          NavigationDestination(
            icon: Icon(Icons.graphic_eq),
            selectedIcon: Icon(Icons.graphic_eq, color: C.copper),
            label: 'Now Playing',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune),
            selectedIcon: Icon(Icons.tune, color: C.copper),
            label: 'Equalizer',
          ),
        ],
      ),
    );
  }
}
