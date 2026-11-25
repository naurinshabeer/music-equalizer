import 'package:flutter_test/flutter_test.dart';

import 'package:eq_player/models.dart';

void main() {
  test('fmtDuration formats minutes and seconds', () {
    expect(fmtDuration(const Duration(minutes: 1, seconds: 5)), '01:05');
    expect(fmtDuration(Duration.zero), '00:00');
  });

  test('first preset is Flat (all zero)', () {
    final flat = eqPresets.first;
    expect(flat.name, 'Flat');
    expect([flat.low, flat.mid, flat.high], [0, 0, 0]);
  });

  test('presets have unique names', () {
    final names = eqPresets.map((p) => p.name).toSet();
    expect(names.length, eqPresets.length);
  });
}
