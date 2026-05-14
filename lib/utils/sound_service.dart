import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../models/pattern_model.dart';

class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  bool _enabled = true;
  bool _initialized = false;
  String _tempDir = '';

  final List<AudioPlayer> _pool = [];
  int _poolIndex = 0;
  static const int _poolSize = 4;

  bool get enabled => _enabled;
  set enabled(bool v) => _enabled = v;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    final dir = await getTemporaryDirectory();
    _tempDir = dir.path;

    await AudioPlayer.global.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: [AVAudioSessionOptions.mixWithOthers],
      ),
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        audioMode: AndroidAudioMode.normal,
        audioFocus: AndroidAudioFocus.none,
      ),
    ));

    for (int i = 0; i < _poolSize; i++) {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setPlayerMode(PlayerMode.lowLatency);
      _pool.add(player);
    }
  }

  Future<void> dispose() async {
    for (final p in _pool) {
      await p.dispose();
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> playNodeTap() =>
      _playTone(frequency: 880, durationMs: 80, volume: 0.85);

  Future<void> playDragConnect() =>
      _playTone(frequency: 1100, durationMs: 65, volume: 0.75);

  Future<void> playCommonPatternAlert() async {
    await _playTone(frequency: 330, durationMs: 180, volume: 0.95);
    await Future.delayed(const Duration(milliseconds: 100));
    await _playTone(frequency: 260, durationMs: 220, volume: 0.95);
  }

  Future<void> playStrengthResult(StrengthCategory strength) async {
    switch (strength) {
      case StrengthCategory.weakest:
        await _playTone(frequency: 220, durationMs: 350, volume: 0.90);
      case StrengthCategory.weak:
        await _playTone(frequency: 294, durationMs: 300, volume: 0.85);
      case StrengthCategory.weakToMedium:
        await _playTone(frequency: 370, durationMs: 250, volume: 0.80);
      case StrengthCategory.medium:
        await _playTone(frequency: 440, durationMs: 250, volume: 0.80);
      case StrengthCategory.mediumToStrong:
        await _playTone(frequency: 523, durationMs: 200, volume: 0.80);
        await Future.delayed(const Duration(milliseconds: 80));
        await _playTone(frequency: 659, durationMs: 180, volume: 0.75);
      case StrengthCategory.strong:
        await _playTone(frequency: 659, durationMs: 180, volume: 0.85);
        await Future.delayed(const Duration(milliseconds: 60));
        await _playTone(frequency: 784, durationMs: 200, volume: 0.85);
      case StrengthCategory.strongest:
        await _playTone(frequency: 784, durationMs: 150, volume: 0.85);
        await Future.delayed(const Duration(milliseconds: 50));
        await _playTone(frequency: 988, durationMs: 150, volume: 0.85);
        await Future.delayed(const Duration(milliseconds: 50));
        await _playTone(frequency: 1175, durationMs: 220, volume: 0.90);
    }
  }

  // ── Playback engine ───────────────────────────────────────────────────────

  Future<void> _playTone({
    required double frequency,
    required int durationMs,
    required double volume,
  }) async {
    if (!_enabled) return;
    if (!_initialized) await _init();

    try {
      final String filePath = await _getToneFile(frequency, durationMs, volume);
      final player = _pool[_poolIndex % _poolSize];
      _poolIndex++;

      await player.stop();
      await player.setVolume(1.0);
      await player.play(DeviceFileSource(filePath));
    } catch (_) {}
  }

  final Map<String, String> _fileCache = {};

  Future<String> _getToneFile(
      double frequency, int durationMs, double volume) async {
    final key = '${frequency.toInt()}_${durationMs}_${(volume * 100).toInt()}';

    if (_fileCache.containsKey(key)) return _fileCache[key]!;

    final bytes = _generateWav(
      frequency: frequency,
      durationMs: durationMs,
      volume: volume,
    );

    final file = File('$_tempDir/tone_$key.wav');
    await file.writeAsBytes(bytes, flush: true);
    _fileCache[key] = file.path;
    return file.path;
  }

  // ── WAV generation ────────────────────────────────────────────────────────

  static Uint8List _generateWav({
    required double frequency,
    required int durationMs,
    required double volume,
  }) {
    const int sampleRate = 44100;
    final int numSamples = (sampleRate * durationMs / 1000).round();
    final int dataSize = numSamples * 2;

    final ByteData header = ByteData(44);
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, 36 + dataSize, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E

    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // (space)
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, 1, Endian.little); // mono
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);

    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);

    final ByteData samples = ByteData(dataSize);
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      double envelope = 1.0;
      final double attackEnd = 0.003;
      final double decayStart = durationMs / 1000.0 * 0.75;
      if (t < attackEnd) {
        envelope = t / attackEnd;
      } else if (t > decayStart) {
        envelope =
            1.0 - ((t - decayStart) / (durationMs / 1000.0 - decayStart));
      }
      envelope = envelope.clamp(0.0, 1.0);

      final double sample =
          sin(2 * pi * frequency * t) * volume * envelope * 32767;
      samples.setInt16(
          i * 2, sample.round().clamp(-32768, 32767), Endian.little);
    }

    final Uint8List wav = Uint8List(44 + dataSize);
    wav.setRange(0, 44, header.buffer.asUint8List());
    wav.setRange(44, 44 + dataSize, samples.buffer.asUint8List());
    return wav;
  }
}
