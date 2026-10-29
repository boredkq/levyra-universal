import 'package:flutter_test/flutter_test.dart';
import 'package:levyra_music/audio/dsp_processor.dart';

void main() {
  group('DspProcessorSettings Tests', () {
    const dsp = DspProcessorSettings(replayGainEnabled: true);

    test('ReplayGain volume multiplier clamps between 0.2 and 1.5', () {
      // 0 dB -> multiplier 1.0
      expect(dsp.calculateReplayGainMultiplier(0.0), closeTo(1.0, 0.001));

      // -6 dB -> multiplier ~0.501
      expect(dsp.calculateReplayGainMultiplier(-6.0), closeTo(0.501, 0.01));

      // +3 dB -> multiplier ~1.412
      expect(dsp.calculateReplayGainMultiplier(3.0), closeTo(1.412, 0.01));

      // Very quiet track (+20dB) clamped to 1.5
      expect(dsp.calculateReplayGainMultiplier(20.0), equals(1.5));

      // Very loud track (-30dB) clamped to 0.2
      expect(dsp.calculateReplayGainMultiplier(-30.0), equals(0.2));
    });

    test('Built-in EQ presets contain 10 frequency bands', () {
      expect(DspProcessorSettings.presets.containsKey('Bass Boost'), isTrue);
      expect(DspProcessorSettings.presets.containsKey('Rock'), isTrue);
      expect(DspProcessorSettings.presets.containsKey('Electronic / Dance'), isTrue);

      final bassBoost = DspProcessorSettings.presets['Bass Boost']!;
      expect(bassBoost.length, equals(10));
      // Sub-bass 31Hz boosted
      expect(bassBoost[0], greaterThan(4.0));
    });
  });
}