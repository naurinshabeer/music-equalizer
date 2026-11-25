import 'package:flutter/material.dart';

import '../audio_controller.dart';
import '../models.dart';
import '../theme.dart';

class AlbumsScreen extends StatelessWidget {
  final AudioController c;
  final VoidCallback onOpenPlayer;
  const AlbumsScreen({super.key, required this.c, required this.onOpenPlayer});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final deviceCount = c.indicesOf(kDevice).length;
        return Scaffold(
          appBar: AppBar(title: const Text('ALBUMS')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _card(
                context,
                album: kBuiltIn,
                subtitle: 'Bundled with the app',
                icon: Icons.library_music,
                colors: const [C.rust, C.copper],
                count: c.indicesOf(kBuiltIn).length,
              ),
              const SizedBox(height: 12),
              _card(
                context,
                album: kDevice,
                subtitle: deviceCount == 0
                    ? 'Tap to add songs from your phone'
                    : 'Songs you picked from your phone',
                icon: Icons.phone_android,
                colors: const [C.card2, C.rust],
                count: deviceCount,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _card(
    BuildContext context, {
    required String album,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required int count,
  }) {
    return Material(
      color: C.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlbumDetailScreen(
              c: c,
              album: album,
              onOpenPlayer: onOpenPlayer,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.card2),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(icon, color: C.cream, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(album,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(color: C.muted, fontSize: 13)),
                    const SizedBox(height: 6),
                    Caption('$count ${count == 1 ? 'track' : 'tracks'}',
                        color: C.copper),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: C.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class AlbumDetailScreen extends StatelessWidget {
  final AudioController c;
  final String album;
  final VoidCallback onOpenPlayer;
  const AlbumDetailScreen({
    super.key,
    required this.c,
    required this.album,
    required this.onOpenPlayer,
  });

  bool get _isDevice => album == kDevice;

  Future<void> _addSongs(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final first = await c.importFromDevice();
      if (first == null) return; // user cancelled the picker
      await c.playIndex(first);
      navigator.pop();
      onOpenPlayer();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not add songs: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final indices = c.indicesOf(album);
        return Scaffold(
          appBar: AppBar(
            title: Text(album.toUpperCase()),
            actions: [
              if (_isDevice)
                IconButton(
                  tooltip: 'Add songs',
                  icon: const Icon(Icons.add, color: C.copper),
                  onPressed: () => _addSongs(context),
                ),
            ],
          ),
          body: indices.isEmpty ? _empty(context) : _list(context, indices),
        );
      },
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.library_add, size: 56, color: C.muted),
            const SizedBox(height: 16),
            const Text('No songs yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'Pick audio files from your phone to play them here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: C.muted),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _addSongs(context),
              icon: const Icon(Icons.folder_open),
              label: const Text('ADD SONGS'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<int> indices) {
    return StreamBuilder<int?>(
      stream: c.player.currentIndexStream,
      builder: (context, snap) {
        final current = snap.data;
        return Material(
          color: C.bg,
          clipBehavior: Clip.hardEdge,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            itemCount: indices.length + (_isDevice ? 1 : 0),
            itemBuilder: (context, n) {
              if (n == indices.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton.icon(
                    onPressed: () => _addSongs(context),
                    icon: const Icon(Icons.add),
                    label: const Text('ADD MORE SONGS'),
                  ),
                );
              }
              final i = indices[n];
              final t = c.tracks[i];
              final selected = i == current;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  selected: selected,
                  selectedTileColor: C.copper.withOpacity(0.14),
                  selectedColor: C.copper,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected ? C.copper : C.card2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      selected ? Icons.graphic_eq : Icons.music_note,
                      color: C.cream,
                    ),
                  ),
                  title: Text(t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected ? C.copper : C.cream)),
                  subtitle:
                      Text(t.artist, style: const TextStyle(color: C.muted)),
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    await c.playIndex(i);
                    navigator.pop();
                    onOpenPlayer();
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}