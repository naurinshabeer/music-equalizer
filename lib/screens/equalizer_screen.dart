import 'package:flutter/material.dart';

import '../audio_controller.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/eq_curve.dart';

class EqualizerScreen extends StatelessWidget {
  final AudioController c;
  const EqualizerScreen({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final on = c.eqEnabled;
        return Scaffold(
          appBar: AppBar(
            title: const Text('EQUALIZER'),
            actions: [
              TextButton(
                onPressed: on ? c.resetToFlat : null,
                child: const Text('RESET',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Caption('DSP engine', color: C.copper),
                      SizedBox(height: 2),
                      Text('3-Band Equalizer',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                _powerCard(on),
                const SizedBox(height: 12),
                _curveCard(on),
                const SizedBox(height: 12),
                _presets(on),
                const SizedBox(height: 12),
                _slidersCard(on),
                const SizedBox(height: 16),
                // SizedBox(
                //   height: 52,
                //   child: OutlinedButton(
                //     onPressed: on ? c.resetToFlat : null,
                //     child: const Text('RESET TO FLAT (0 DB)'),
                //   ),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  // On/off switch: lets a listener A/B the original vs. equalized sound.
  Widget _powerCard(bool on) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: on ? C.copper : C.card2),
      ),
      child: Row(
        children: [
          Icon(Icons.power_settings_new, color: on ? C.copper : C.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Caption('Equalizer engine', color: on ? C.copper : C.muted),
                const SizedBox(height: 2),
                Text(
                  on ? 'Active \u2014 shaping the sound' : 'Bypassed \u2014 original sound',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Switch(value: on, onChanged: c.setEqEnabled),
        ],
      ),
    );
  }

  Widget _curveCard(bool on) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.card2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Caption('Frequency response'),
                Caption(on ? c.presetName : 'Bypassed',
                    color: on ? C.copper : C.muted),
              ],
            ),
          ),
          EqCurve(
            low: c.lowGain,
            mid: c.midGain,
            high: c.highGain,
            minDb: c.minDb,
            maxDb: c.maxDb,
            enabled: on,
            height: 140,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 2, 4, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Caption('Low'), Caption('Mid'), Caption('High')],
            ),
          ),
        ],
      ),
    );
  }

  Widget _presets(bool on) {
    final current = c.presetName;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final p in eqPresets)
          ChoiceChip(
            label: Text(p.name),
            selected: on && current == p.name,
            showCheckmark: false,
            onSelected: on ? (_) => c.applyPreset(p) : null,
            selectedColor: C.copper,
            backgroundColor: C.card2,
            side: BorderSide.none,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: (on && current == p.name) ? C.bg : C.cream,
            ),
          ),
      ],
    );
  }

  Widget _slidersCard(bool on) {
    return Opacity(
      opacity: on ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.card2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _band(EqGroup.low, 'Low bass', on),
            _band(EqGroup.mid, 'Vocals', on),
            _band(EqGroup.high, 'Treble', on),
          ],
        ),
      ),
    );
  }

  Widget _band(EqGroup g, String label, bool on) {
    final value = c.gainOf(g);
    return Column(
      children: [
        Text('${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)} dB',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: on ? C.copper : C.muted,
                fontSize: 15)),
        const SizedBox(height: 6),
        SizedBox(
          height: 210,
          child: RotatedBox(
            quarterTurns: 3,
            child: SizedBox(
              width: 210,
              child: Slider(
                min: c.minDb,
                max: c.maxDb,
                value: value.clamp(c.minDb, c.maxDb),
                onChanged: on ? (v) => c.setGain(g, v) : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(c.rangeLabel(g),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Caption(label),
      ],
    );
  }
}