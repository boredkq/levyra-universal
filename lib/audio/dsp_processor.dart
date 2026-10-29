import 'dart:math';

/// Studio-grade Audio DSP Processor settings and calculations.
/// Implements ReplayGain loudness normalization, 10-band Parametric EQ,
/// Crossfade, DJ Soft mode, Bass Boost, and Tempo/Pitch adjustments.
class DspProcessorSettings {
  final bool replayGainEnabled;
  final double targetLufs; // Typically -14.0 LUFS standard

  final bool equalizerEnabled;
  final List<double> eqBandsDb; // 10 bands: 31Hz to 16kHz (-12dB to +12dB)
  final double bassBoostLevel;  // 0.0 to 1.0
  final double virtualizerLevel;// 0.0 to 1.0

  final Duration crossfadeDuration; // 0s (off) to 12s
  final bool djSoftMode;            // Smooth BPM transition

  final double playbackSpeed;       // 0.5x to 2.0x
  final double pitchSemitones;      // -12.0 to +12.0

  const DspProcessorSettings({
    this.replayGainEnabled = true,
    this.targetLufs = -14.0,
    this.equalizerEnabled = false,
    this.eqBandsDb = const [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    this.bassBoostLevel = 0.0,
    this.virtualizerLevel = 0.0,
    this.crossfadeDuration = const Duration(seconds: 3),
    this.djSoftMode = true,
    this.playbackSpeed = 1.0,
    this.pitchSemitones = 0.0,
  });

  /// Standard 10 frequency center points in Hz
  static const List<int> bandFrequenciesHz = [
    31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000
  ];

  /// Built-in EQ Presets
  static const Map<String, List<double>> presets = {
    'Flat': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    'Bass Boost': [6.0, 5.0, 3.5, 1.0, 0, 0, 0, 0, 0, 0],
    'Rock': [4.5, 3.0, -1.0, -2.0, 1.0, 2.5, 4.0, 5.0, 4.5, 4.0],
    'Electronic / Dance': [5.0, 4.0, 1.5, 0, -1.5, 1.5, 3.0, 4.0, 4.5, 4.0],
    'Vocal / Acoustic': [-2.0, -1.0, 0, 2.0, 4.0, 4.5, 3.5, 2.0, 1.0, 0],
    'Classical': [3.5, 3.0, 2.5, 2.0, -1.0, -1.0, 0, 2.0, 3.0, 3.5],
  };

  /// Calculates effective volume multiplier for ReplayGain normalization
  double calculateReplayGainMultiplier(double trackGainDb) {
    if (!replayGainEnabled) return 1.0;
    // Difference between target and source track gain
    final effectiveDb = trackGainDb;
    // Linear amplitude = 10^(dB / 20)
    final linear = pow(10.0, effectiveDb / 20.0).toDouble();
    // Clamp to prevent digital clipping / distortion
    return linear.clamp(0.2, 1.5);
  }

  DspProcessorSettings copyWith({
    bool? replayGainEnabled,
    double? targetLufs,
    bool? equalizerEnabled,
    List<double>? eqBandsDb,
    double? bassBoostLevel,
    double? virtualizerLevel,
    Duration? crossfadeDuration,
    bool? djSoftMode,
    double? playbackSpeed,
    double? pitchSemitones,
  }) {
    return DspProcessorSettings(
      replayGainEnabled: replayGainEnabled ?? this.replayGainEnabled,
      targetLufs: targetLufs ?? this.targetLufs,
      equalizerEnabled: equalizerEnabled ?? this.equalizerEnabled,
      eqBandsDb: eqBandsDb ?? this.eqBandsDb,
      bassBoostLevel: bassBoostLevel ?? this.bassBoostLevel,
      virtualizerLevel: virtualizerLevel ?? this.virtualizerLevel,
      crossfadeDuration: crossfadeDuration ?? this.crossfadeDuration,
      djSoftMode: djSoftMode ?? this.djSoftMode,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      pitchSemitones: pitchSemitones ?? this.pitchSemitones,
    );
  }
}
