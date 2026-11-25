const String kBuiltIn = 'Built-in';
const String kDevice = 'My Device';

class Track {
  final String title;
  final String artist;

  /// Asset path for bundled tracks, or a real file path for device tracks.
  final String path;
  final bool isAsset;
  final String album;

  const Track(
    this.title,
    this.artist,
    this.path, {
    this.isAsset = true,
    this.album = kBuiltIn,
  });
}

/// A preset is just a set of dB gains for the three bands.
/// Values are clamped to the device's real min/max when applied.
class EqPreset {
  final String name;
  final double low, mid, high;
  const EqPreset(this.name, this.low, this.mid, this.high);
}

const List<EqPreset> eqPresets = [
  EqPreset('Flat', 0, 0, 0),
  EqPreset('Bass Boost', 6, 1, -2),
  EqPreset('Vocal Clarity', -2, 5, 2),
  EqPreset('Treble Boost', -2, 0, 6),
];

String fmtDuration(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}