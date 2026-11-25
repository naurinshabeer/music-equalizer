import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import 'device_picker.dart';
import 'models.dart';

enum EqGroup { low, mid, high }

/// Owns the player and the equalizer. Screens listen to it and call its
/// methods; no audio logic lives in the UI files.
class AudioController extends ChangeNotifier {
  final AndroidEqualizer equalizer = AndroidEqualizer();
  late final AudioPlayer player = AudioPlayer(
    audioPipeline: AudioPipeline(androidAudioEffects: [equalizer]),
  );

  /// One shared queue. Albums are just filtered views of this list, so
  /// next/previous work across everything.
  final List<Track> tracks = [
    const Track('Electronic Stylish Rock', 'AlexGrohl', 'assets/audio/track1.mp3'),
    const Track('Acoustic Guitar', 'AtlasAudio', 'assets/audio/track2.mp3'),
    const Track('Woah (CJC Beat Factory Remix)', 'AAP', 'assets/audio/track3.mp3'),
  ];

  late final ConcatenatingAudioSource _queue;

  AndroidEqualizerParameters? eqParams;
  String? error;

  bool eqEnabled = true;
  double lowGain = 0, midGain = 0, highGain = 0;

  List<AndroidEqualizerBand> _low = [], _mid = [], _high = [];

  bool get eqReady => eqParams != null;
  double get minDb => eqParams?.minDecibels ?? -12;
  double get maxDb => eqParams?.maxDecibels ?? 12;

  double gainOf(EqGroup g) {
    switch (g) {
      case EqGroup.low:
        return lowGain;
      case EqGroup.mid:
        return midGain;
      case EqGroup.high:
        return highGain;
    }
  }

  double _clamp(double v) => v.clamp(minDb, maxDb).toDouble();

  /// Name of the preset matching the current sliders, or 'Custom'.
  String get presetName {
    bool close(double a, double b) => (a - b).abs() < 0.3;
    for (final p in eqPresets) {
      if (close(lowGain, _clamp(p.low)) &&
          close(midGain, _clamp(p.mid)) &&
          close(highGain, _clamp(p.high))) {
        return p.name;
      }
    }
    return 'Custom';
  }

  // ----------------------------------------------------------------- albums

  /// Positions (in the shared queue) of the tracks belonging to an album.
  List<int> indicesOf(String album) => [
        for (var i = 0; i < tracks.length; i++)
          if (tracks[i].album == album) i,
      ];

  Future<void> playIndex(int i) async {
    await player.seek(Duration.zero, index: i);
    player.play(); // not awaited: completes only when playback ends
  }

  /// Opens the system file picker, adds the chosen songs to the shared queue
  /// and returns the queue position of the first new song (null if cancelled).
  Future<int?> importFromDevice() async {
    final picked = await pickDeviceAudio();
    if (picked.isEmpty) return null;

    final sources = [for (final t in picked) await _sourceFor(t)];
    final firstIndex = tracks.length;
    tracks.addAll(picked);
    await _queue.addAll(sources);
    notifyListeners();
    return firstIndex;
  }

  // ---------------------------------------------------------------- loading

  /// Bundled assets are copied to the app cache and played as normal files.
  /// This avoids just_audio's local-proxy asset loading, which failed on
  /// some devices with "(0) Source error". Device files are already files.
  Future<AudioSource> _sourceFor(Track t) async {
    if (!t.isAsset) return AudioSource.uri(Uri.file(t.path));

    final data = await rootBundle.load(t.path); // throws if not bundled
    final file = File('${Directory.systemTemp.path}/${t.path.split('/').last}');
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    debugPrint('LOADED ${file.path} (${await file.length()} bytes)');
    return AudioSource.uri(Uri.file(file.path));
  }

  Future<void> init() async {
    String step = 'starting';
    try {
      step = 'configuring audio session';
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      final sources = <AudioSource>[];
      for (final t in tracks) {
        step = 'reading ${t.path}';
        sources.add(await _sourceFor(t));
      }

      step = 'loading into player';
      _queue = ConcatenatingAudioSource(children: sources);
      await player.setAudioSource(_queue);
      await player.setLoopMode(LoopMode.all);

      // Equalizer parameters only exist once audio is loaded.
      step = 'starting equalizer';
      await equalizer.setEnabled(true);
      final params = await equalizer.parameters;

      // Group the device's bands by centre frequency (Hz).
      _low = params.bands.where((b) => b.centerFrequency < 250).toList();
      _mid = params.bands
          .where((b) => b.centerFrequency >= 250 && b.centerFrequency < 4000)
          .toList();
      _high = params.bands.where((b) => b.centerFrequency >= 4000).toList();
      eqParams = params;

      await resetToFlat(); // make the UI match the hardware at start
    } catch (e, st) {
      debugPrint('INIT FAILED during "$step": $e\n$st');
      error = 'Failed while $step:\n\n$e';
      notifyListeners();
    }
  }

  // -------------------------------------------------------------------- EQ

  void _apply(List<AndroidEqualizerBand> bands, double v) {
    for (final b in bands) {
      b.setGain(v);
    }
  }

  /// Move one slider; applies to every device band in that group, live.
  void setGain(EqGroup g, double v) {
    v = _clamp(v);
    switch (g) {
      case EqGroup.low:
        lowGain = v;
        _apply(_low, v);
        break;
      case EqGroup.mid:
        midGain = v;
        _apply(_mid, v);
        break;
      case EqGroup.high:
        highGain = v;
        _apply(_high, v);
        break;
    }
    notifyListeners();
  }

  void applyPreset(EqPreset p) {
    lowGain = _clamp(p.low);
    midGain = _clamp(p.mid);
    highGain = _clamp(p.high);
    _apply(_low, lowGain);
    _apply(_mid, midGain);
    _apply(_high, highGain);
    notifyListeners();
  }

  Future<void> resetToFlat() async {
    applyPreset(eqPresets.first);
    // Also zero any band that isn't in a group, just in case.
    for (final b in eqParams?.bands ?? <AndroidEqualizerBand>[]) {
      b.setGain(0);
    }
  }

  /// Bypass switch: lets you A/B the original sound against the EQ'd sound.
  Future<void> setEqEnabled(bool on) async {
    await equalizer.setEnabled(on);
    eqEnabled = on;
    notifyListeners();
  }

  /// e.g. "60 Hz - 230 Hz" for the Low group on this device.
  String rangeLabel(EqGroup g) {
    final bands = g == EqGroup.low ? _low : (g == EqGroup.mid ? _mid : _high);
    if (bands.isEmpty) return '\u2014';
    String f(double hz) => hz >= 1000
        ? '${(hz / 1000).toStringAsFixed(1)} kHz'
        : '${hz.round()} Hz';
    final lo = bands.first.centerFrequency;
    final hi = bands.last.centerFrequency;
    return lo == hi ? f(lo) : '${f(lo)} - ${f(hi)}';
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}