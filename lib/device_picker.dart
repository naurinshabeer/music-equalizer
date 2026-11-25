import 'package:file_selector/file_selector.dart';

import 'models.dart';

/// Lets the user pick audio files from the phone and returns them as Tracks.
/// This is the ONLY file that imports the picker package, so if the package
/// ever causes build trouble, replacing this file with a stub removes it.
Future<List<Track>> pickDeviceAudio() async {
  const audio = XTypeGroup(
    label: 'Audio',
    extensions: ['mp3', 'm4a', 'aac', 'wav', 'flac', 'ogg', 'opus'],
    mimeTypes: ['audio/*'],
    uniformTypeIdentifiers: ['public.audio'],
  );

  final files = await openFiles(acceptedTypeGroups: [audio]);

  return [
    for (final f in files)
      Track(
        f.name.replaceAll(RegExp(r'\.[^.]+$'), ''), // drop the extension
        'From device',
        f.path,
        isAsset: false,
        album: kDevice,
      ),
  ];
}