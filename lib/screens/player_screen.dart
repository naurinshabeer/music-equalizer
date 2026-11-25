import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../audio_controller.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/eq_curve.dart';

class PlayerScreen extends StatelessWidget {
  final AudioController c;
  final VoidCallback onOpenEq; // switches the bottom nav to the EQ tab
  const PlayerScreen({super.key, required this.c, required this.onOpenEq});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('NOW PLAYING')),
          body: SafeArea(
            child: c.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SelectableText(c.error!,
                          textAlign: TextAlign.center),
                    ),
                  )
                : Column(
                    children: [
                      const SizedBox(height: 4),
                      _artwork(),
                      const SizedBox(height: 16),
                      _titleBlock(),
                      const SizedBox(height: 4),
                      _seekBar(),
                      _controls(),
                      const SizedBox(height: 12),
                      _eqCard(),
                      const SizedBox(height: 8),
                      const Divider(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child:
                              Caption('Queue • ${c.tracks.length} tracks'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Material(
                          color: C.bg,
                          clipBehavior: Clip.hardEdge,
                          child: _trackList(),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // Prominent entry point to the main feature.
  Widget _eqCard() {
    final on = c.eqEnabled;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: C.copper.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: c.eqReady ? onOpenEq : null,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: on ? C.copper : C.track),
            ),
            child: Row(
              children: [
                Icon(Icons.tune, color: on ? C.copper : C.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Caption('Equalizer', color: on ? C.copper : C.muted),
                      const SizedBox(height: 2),
                      Text(
                        on ? c.presetName : 'Bypassed',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: EqCurve(
                    low: c.lowGain,
                    mid: c.midGain,
                    high: c.highGain,
                    minDb: c.minDb,
                    maxDb: c.maxDb,
                    enabled: on,
                    compact: true,
                    height: 36,
                  ),
                ),
                const Icon(Icons.chevron_right, color: C.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _artwork() {
    return Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.card2, width: 2),
        gradient: const LinearGradient(
          colors: [C.rust, C.copper],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: C.copper.withOpacity(0.30),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.graphic_eq, size: 80, color: C.cream),
    );
  }

  Widget _titleBlock() {
    return StreamBuilder<int?>(
      stream: c.player.currentIndexStream,
      builder: (context, snap) {
        final i = snap.data ?? 0;
        final t = (i >= 0 && i < c.tracks.length) ? c.tracks[i] : null;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                t?.title ?? 'No track loaded',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(t?.artist ?? '',
                  style: const TextStyle(color: C.muted, fontSize: 14)),
            ],
          ),
        );
      },
    );
  }

  Widget _seekBar() {
    return StreamBuilder<Duration?>(
      stream: c.player.durationStream,
      builder: (context, durSnap) {
        final total = durSnap.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: c.player.positionStream,
          builder: (context, posSnap) {
            var pos = posSnap.data ?? Duration.zero;
            if (pos > total) pos = total;
            final maxMs = total.inMilliseconds.toDouble();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Slider(
                    min: 0,
                    max: maxMs > 0 ? maxMs : 1,
                    value: pos.inMilliseconds
                        .toDouble()
                        .clamp(0, maxMs > 0 ? maxMs : 1),
                    onChanged: (v) =>
                        c.player.seek(Duration(milliseconds: v.round())),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(fmtDuration(pos),
                            style: const TextStyle(color: C.muted)),
                        Text(fmtDuration(total),
                            style: const TextStyle(color: C.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _controls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _squareButton(Icons.skip_previous, c.player.seekToPrevious),
        const SizedBox(width: 16),
        StreamBuilder<PlayerState>(
          stream: c.player.playerStateStream,
          builder: (context, snap) {
            final playing = snap.data?.playing ?? false;
            final loading =
                snap.data?.processingState == ProcessingState.loading ||
                    snap.data?.processingState == ProcessingState.buffering;
            return Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: C.copper,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: C.copper.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(22),
                      child: CircularProgressIndicator(
                          color: C.cream, strokeWidth: 3),
                    )
                  : IconButton(
                      iconSize: 42,
                      color: C.cream,
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                      onPressed: playing ? c.player.pause : c.player.play,
                    ),
            );
          },
        ),
        const SizedBox(width: 16),
        _squareButton(Icons.skip_next, c.player.seekToNext),
      ],
    );
  }

  Widget _squareButton(IconData icon, VoidCallback onTap) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: C.card2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        iconSize: 30,
        color: C.cream,
        icon: Icon(icon),
        onPressed: onTap,
      ),
    );
  }

  Widget _trackList() {
    return StreamBuilder<int?>(
      stream: c.player.currentIndexStream,
      builder: (context, snap) {
        final current = snap.data;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: c.tracks.length,
          itemBuilder: (context, i) {
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
                title: Text(c.tracks[i].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected ? C.copper : C.cream)),
                subtitle: Text(c.tracks[i].artist,
                    style: const TextStyle(color: C.muted)),
                onTap: () => c.playIndex(i),
              ),
            );
          },
        );
      },
    );
  }
}
