# Equalizer — Flutter Music Player with a 3-Band EQ

A simple music player built in Flutter with **Low / Mid / High** equalizer controls that change the sound in real time.

- **Platform targeted:** Android (developed and tested on a OnePlus phone, model CPH2487)
- **Demo video:** `<ADD VIDEO LINK>`
- **Author:** `<ADD YOUR NAME>`

## Features

**Required by the challenge**
- Plays bundled tracks (3 royalty-free songs) and songs picked from the device
- Play / pause, seek bar, next / previous
- Shows the current track name, elapsed time and total duration
- 3-band equalizer (Low, Mid, High), each with a slider, audibly changing the sound live
- Reset to Flat

**Extras**
- **Preset chips:** Flat, Bass Boost, Vocal Clarity, Treble Boost (the chip shows "Custom" if you move a slider by hand)
- **Engine on/off switch** to bypass the equalizer, so you can A/B compare the original and the equalized sound
- **Live frequency-response curve** that reshapes as you drag. It is driven by the real slider values, not a fake animation.
- **Albums:** "Built-in" (bundled tracks) and "My Device" (picked files), sharing one queue
- Bottom navigation: Albums, Now Playing, Equalizer
- Custom app icon, splash screen and dark "analog" theme

## How the equalizer works

1. `just_audio`'s `AudioPlayer` is created with an `AudioPipeline` that contains an `AndroidEqualizer`. The equalizer is Android's built-in audio effect, so it processes the audio live while it plays. It is enabled once audio is loaded, because its parameters only exist after that.
2. Android devices expose a handful of frequency bands (their number and centre frequencies depend on the phone). The app reads them at startup and groups them by centre frequency:
   - **Low:** below 250 Hz
   - **Mid:** 250 Hz to 4 kHz
   - **High:** 4 kHz and above
3. Each slider sets the gain (in dB) on every band in its group, immediately.
4. The slider range comes from the device (`minDecibels` / `maxDecibels`), and the labels under each slider show the real frequencies of that group on the current phone.
5. Presets are three dB values clamped to the device range. **Reset to Flat** applies the Flat preset and also zeroes every band.
6. The on/off switch calls `setEnabled(false/true)` on the equalizer.

The frequency-response curve is a `CustomPainter` that draws a smooth line through the three current gains.

## Architecture

```
lib/
├── main.dart                  App entry; creates one shared AudioController
├── audio_controller.dart      Player, queue, equalizer, presets (ChangeNotifier)
├── models.dart                Track, EqPreset, preset values, time formatting
├── device_picker.dart         Picks audio files from the phone (file_selector)
├── theme.dart                 Colours and theme
├── screens/
│   ├── home_shell.dart        Bottom navigation (Albums | Now Playing | Equalizer)
│   ├── albums_screen.dart     Album list and album detail
│   ├── player_screen.dart     Now Playing
│   └── equalizer_screen.dart  EQ sliders, presets, curve, bypass switch
└── widgets/
    └── eq_curve.dart          Frequency-response curve
```

All audio logic lives in `AudioController`, a `ChangeNotifier` shared by every screen. The screens only build UI and call its methods. State management is plain Flutter (`ListenableBuilder` / `StreamBuilder`), with no extra state package. There is one shared queue; albums are filtered views of it, so next / previous works across everything.

## Packages

| Package | Used for |
|---|---|
| `just_audio` | Playback, queue and the Android equalizer pipeline |
| `audio_session` | Audio focus / music session configuration |
| `file_selector` | Picking audio files from the device |

## Run it

Requirements: Flutter SDK and an **Android** phone or emulator. The equalizer uses an Android-only API, so it will not work on iOS, web or desktop.

```bash
git clone <ADD REPO URL>
cd <repo folder>
flutter pub get
flutter run
```

For a release build:

```bash
flutter build apk --release
flutter install
```

The three demo tracks are bundled in `assets/audio/` (`track1.mp3`, `track2.mp3`, `track3.mp3`).

## Challenges faced

- **File picker versions.** The first picker package (`file_picker`) caused build failures: an old version used an Android API that Flutter has since removed, and a newer one needed a higher Android SDK version. I replaced it with `file_selector`, and kept all picker code in a single file (`device_picker.dart`) so it is easy to swap.
- **Bundled audio would not load on my phone.** `just_audio` plays bundled assets through a local proxy, which gave a generic "(0) Source error" on this device. The fix was to copy each bundled asset to the app's cache folder at startup and play it as a normal file. The loader also reports exactly which step failed, which made debugging much faster.
- **Equalizer bands differ per device.** Instead of hard-coding three frequencies, the app reads the device's bands and groups them, and takes the dB limits from the hardware.
- **No real audio analysis.** `just_audio` cannot read live audio levels, so I did not build a spectrum visualizer. The only graphic on the EQ screen is the response curve, which reflects the actual slider values.
- **Flutter layout quirks.** For example, a selected list tile's highlight painted outside the scrolling list until I gave the list its own clipped `Material`.

## Music credits

All tracks are from [Pixabay Music](https://pixabay.com/music/):

- "Electronic Stylish Rock" by AlexGrohl
- "Acoustic Guitar" by AtlasAudio
- "Woah (CJC Beat Factory Remix)" by AAP

Please check each track's own page for its license terms. `<ADD LICENSE NOTE / TRACK URLS>`

## Use of AI tools

- **Claude (Anthropic)** was used for planning the scope, choosing the approach for the equalizer, generating and refactoring the Flutter code, debugging build and asset errors, and drafting this README and the demo script.
- **Google Stitch** was used to generate the visual design direction (colour palette and layout ideas). The app's theme follows its palette.

I ran, tested and verified everything on my own device, and made the final decisions about the design and scope.
