import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// 聚会桌游音频与音效中枢服务 (Game Audio & Sound FX Service)
/// 支持欢快 BGM 背景音乐循环播放、出牌/摇骰/吃牛/开盅 7 大提示音效
/// 采用纯本地程序化高保真 WAV 音频合成技术，100% 离线可用，零外部网络与素材包依赖
class GameAudioService {
  static final GameAudioService _instance = GameAudioService._internal();
  factory GameAudioService() => _instance;
  GameAudioService._internal();

  AudioPlayer? _bgmPlayer;
  AudioPlayer? _sfxPlayer;

  AudioPlayer get bgmPlayer => _bgmPlayer ??= AudioPlayer();
  AudioPlayer get sfxPlayer => _sfxPlayer ??= AudioPlayer();

  bool _isBgmEnabled = true;
  bool _isSfxEnabled = true;
  double _bgmVolume = 0.5;
  double _sfxVolume = 0.8;

  bool get isBgmEnabled => _isBgmEnabled;
  bool get isSfxEnabled => _isSfxEnabled;
  double get bgmVolume => _bgmVolume;
  double get sfxVolume => _sfxVolume;

  // 缓存合成后的各音效 WAV 字节流
  Uint8List? _bgmWavBytes;
  final Map<String, Uint8List> _sfxCache = {};

  bool _isInitialized = false;

  /// 初始化音频合成与播放器参数
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      await bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await bgmPlayer.setVolume(_bgmVolume);
      await sfxPlayer.setVolume(_sfxVolume);

      // 预生成所有音频字节
      _sfxCache['card_play'] = _synthesizeCardPlay();
      _sfxCache['bull_penalty'] = _synthesizeBullPenalty();
      _sfxCache['dice_shake'] = _synthesizeDiceShake();
      _sfxCache['bid_ding'] = _synthesizeBidDing();
      _sfxCache['challenge_bang'] = _synthesizeChallengeBang();
      _sfxCache['victory'] = _synthesizeVictory();
      _sfxCache['defeat'] = _synthesizeDefeat();

      _bgmWavBytes = _synthesizeBgmLoop();
    } catch (_) {
      // 在无声卡或特殊测试环境下静默容错
    }
  }

  /// 播放背景音乐 (若未播放则启动，若已关闭则忽略)
  Future<void> startBgm() async {
    if (!_isBgmEnabled) return;
    await initialize();
    if (_bgmWavBytes == null) return;
    try {
      await bgmPlayer.stop();
      await bgmPlayer.setVolume(_bgmVolume);
      await bgmPlayer.play(BytesSource(_bgmWavBytes!));
    } catch (_) {}
  }

  /// 停止背景音乐
  Future<void> stopBgm() async {
    try {
      await _bgmPlayer?.stop();
    } catch (_) {}
  }

  /// 切换背景音乐开关
  void toggleBgm() {
    _isBgmEnabled = !_isBgmEnabled;
    if (_isBgmEnabled) {
      startBgm();
    } else {
      stopBgm();
    }
  }

  /// 切换音效开关
  void toggleSfx() {
    _isSfxEnabled = !_isSfxEnabled;
  }

  /// 设置 BGM 音量 (0.0 ~ 1.0)
  Future<void> setBgmVolume(double val) async {
    _bgmVolume = val.clamp(0.0, 1.0);
    try {
      await _bgmPlayer?.setVolume(_bgmVolume);
    } catch (_) {}
  }

  /// 设置音效音量 (0.0 ~ 1.0)
  Future<void> setSfxVolume(double val) async {
    _sfxVolume = val.clamp(0.0, 1.0);
    try {
      await _sfxPlayer?.setVolume(_sfxVolume);
    } catch (_) {}
  }

  /// 播放指定名称音效
  Future<void> playSound(String soundKey) async {
    if (!_isSfxEnabled) return;
    await initialize();

    final bytes = _sfxCache[soundKey];
    if (bytes != null) {
      try {
        await sfxPlayer.stop();
        await sfxPlayer.setVolume(_sfxVolume);
        await sfxPlayer.play(BytesSource(bytes));
      } catch (_) {
        // 兜底使用系统触觉与简易反馈
        _fallbackHaptic(soundKey);
      }
    } else {
      _fallbackHaptic(soundKey);
    }
  }

  void _fallbackHaptic(String soundKey) {
    if (soundKey == 'bull_penalty' || soundKey == 'challenge_bang') {
      HapticFeedback.heavyImpact();
    } else if (soundKey == 'dice_shake') {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  // ================= 音频 WAV 信号合成器 (PCM 16-bit 22050Hz) =================

  static const int _sampleRate = 22050;

  /// 生成标准 44 字节 WAV 头
  static Uint8List _createWav(List<int> samples) {
    final int dataSize = samples.length * 2;
    final int fileSize = 36 + dataSize;
    final b = ByteData(44 + dataSize);

    // RIFF header
    b.setUint8(0, 0x52); b.setUint8(1, 0x49); b.setUint8(2, 0x46); b.setUint8(3, 0x46); // 'RIFF'
    b.setUint32(4, fileSize, Endian.little);
    b.setUint8(8, 0x57); b.setUint8(9, 0x41); b.setUint8(10, 0x56); b.setUint8(11, 0x45); // 'WAVE'

    // fmt subchunk
    b.setUint8(12, 0x66); b.setUint8(13, 0x6D); b.setUint8(14, 0x74); b.setUint8(15, 0x20); // 'fmt '
    b.setUint32(16, 16, Endian.little); // Subchunk1Size
    b.setUint16(20, 1, Endian.little); // AudioFormat (PCM = 1)
    b.setUint16(22, 1, Endian.little); // NumChannels (Mono = 1)
    b.setUint32(24, _sampleRate, Endian.little); // SampleRate
    b.setUint32(28, _sampleRate * 2, Endian.little); // ByteRate
    b.setUint16(32, 2, Endian.little); // BlockAlign (Mono 16-bit = 2)
    b.setUint16(34, 16, Endian.little); // BitsPerSample

    // data subchunk
    b.setUint8(36, 0x64); b.setUint8(37, 0x61); b.setUint8(38, 0x74); b.setUint8(39, 0x61); // 'data'
    b.setUint32(40, dataSize, Endian.little);

    // Samples
    int offset = 44;
    for (final s in samples) {
      final clamped = s.clamp(-32768, 32767);
      b.setInt16(offset, clamped, Endian.little);
      offset += 2;
    }

    return b.buffer.asUint8List();
  }

  /// 1. 出牌唰声 (Card Play) - 短促平滑的扫频与弹性翻牌脆响 (~160ms)
  static Uint8List _synthesizeCardPlay() {
    final numSamples = (_sampleRate * 0.16).toInt();
    final samples = <int>[];
    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      final progress = i / numSamples;
      final env = exp(-18.0 * progress);
      final freq = 800.0 + 1200.0 * (1.0 - progress);
      final noise = (Random().nextDouble() * 2 - 1) * 0.25;
      final wave = sin(2 * pi * freq * t) * 0.75 + noise;
      samples.add((wave * env * 24000).toInt());
    }
    return _createWav(samples);
  }

  /// 2. 吃牛头惩罚声 (Bull Penalty) - 低沉警报重击与牛角哀鸣 (~550ms)
  static Uint8List _synthesizeBullPenalty() {
    final numSamples = (_sampleRate * 0.55).toInt();
    final samples = <int>[];
    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      final progress = i / numSamples;
      final env = exp(-5.0 * progress);
      // 低频颤音，模拟牛叫与重锤
      final freq = 120.0 + 15.0 * sin(2 * pi * 12 * t);
      final subBass = sin(2 * pi * 60.0 * t);
      final tone = sin(2 * pi * freq * t);
      final wave = (tone * 0.6 + subBass * 0.4);
      samples.add((wave * env * 28000).toInt());
    }
    return _createWav(samples);
  }

  /// 3. 摇骰盅碰撞声 (Dice Shake) - 真实物理多骰子剧烈撞击与骰盅清脆回响 (~520ms)
  static Uint8List _synthesizeDiceShake() {
    final int numSamples = (_sampleRate * 0.52).toInt();
    final buffer = Float64List(numSamples);

    // 预定义摇骰动作中的 3 幕连续撞击浪潮 (模拟手摇前后甩动)
    // 包含 5 颗骰子在盅内不同时间点产生的高密碰撞
    final rand = Random(1337);
    final impactEvents = <Map<String, dynamic>>[];

    // 浪潮 1: 初次加速甩动 (50ms ~ 140ms, 7次撞击)
    for (int i = 0; i < 7; i++) {
      impactEvents.add({
        'time': 0.05 + i * 0.012 + (rand.nextDouble() * 0.006),
        'force': 0.5 + rand.nextDouble() * 0.45,
        'pitch': 2800.0 + rand.nextDouble() * 1600.0,
        'bodyPitch': 480.0 + rand.nextDouble() * 180.0,
      });
    }

    // 浪潮 2: 反向剧烈撞击 (190ms ~ 310ms, 9次撞击，力度最大)
    for (int i = 0; i < 9; i++) {
      impactEvents.add({
        'time': 0.19 + i * 0.013 + (rand.nextDouble() * 0.007),
        'force': 0.7 + rand.nextDouble() * 0.3,
        'pitch': 3100.0 + rand.nextDouble() * 1800.0,
        'bodyPitch': 420.0 + rand.nextDouble() * 220.0,
      });
    }

    // 浪潮 3: 停顿沉底撞击 (360ms ~ 470ms, 8次散乱停落撞击)
    for (int i = 0; i < 8; i++) {
      impactEvents.add({
        'time': 0.36 + i * 0.014 + (rand.nextDouble() * 0.008),
        'force': 0.4 + rand.nextDouble() * 0.4,
        'pitch': 2600.0 + rand.nextDouble() * 1500.0,
        'bodyPitch': 520.0 + rand.nextDouble() * 160.0,
      });
    }

    // 叠加每次碰撞的物理冲击声学波形
    for (final ev in impactEvents) {
      final double startTime = ev['time'] as double;
      final double force = ev['force'] as double;
      final double clickPitch = ev['pitch'] as double;
      final double bodyPitch = ev['bodyPitch'] as double;

      final int startSample = (startTime * _sampleRate).toInt();
      // 每次撞击持续约 35ms
      final int impactDuration = (_sampleRate * 0.035).toInt();

      for (int j = 0; j < impactDuration; j++) {
        final int targetIdx = startSample + j;
        if (targetIdx >= numSamples) break;

        final double dt = j / _sampleRate;
        // 极快衰减的亚克力骰子脆响
        final double clickEnv = exp(-320.0 * dt);
        final double clickTone = sin(2 * pi * clickPitch * dt) + 0.4 * sin(2 * pi * clickPitch * 1.6 * dt);
        // 骰盅硬质内壁敲击声
        final double bodyEnv = exp(-140.0 * dt);
        final double bodyTone = sin(2 * pi * bodyPitch * dt);
        // 细微摩擦杂音
        final double noise = (rand.nextDouble() * 2 - 1) * exp(-450.0 * dt);

        final double sampleVal = force * (clickTone * clickEnv * 0.65 + bodyTone * bodyEnv * 0.25 + noise * 0.1);
        buffer[targetIdx] += sampleVal;
      }
    }

    // 归一化并转成 16-bit PCM samples
    double maxAmp = 0.001;
    for (int i = 0; i < numSamples; i++) {
      final a = buffer[i].abs();
      if (a > maxAmp) maxAmp = a;
    }

    final samples = <int>[];
    final scale = 30000.0 / maxAmp;
    for (int i = 0; i < numSamples; i++) {
      samples.add((buffer[i] * scale).toInt());
    }

    return _createWav(samples);
  }

  /// 4. 叫点提示声 (Bid Ding) - 清脆晶莹的高音叮叮响 (~350ms)
  static Uint8List _synthesizeBidDing() {
    final numSamples = (_sampleRate * 0.35).toInt();
    final samples = <int>[];
    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      final progress = i / numSamples;
      final env = exp(-10.0 * progress);
      // 1046.5Hz (C6) + 泛音
      final wave = sin(2 * pi * 1046.5 * t) * 0.7 + sin(2 * pi * 2093.0 * t) * 0.3;
      samples.add((wave * env * 22000).toInt());
    }
    return _createWav(samples);
  }

  /// 5. 开/劈大喊震慑声 (Challenge Bang) - 震撼重雷与重音金石裂帛 (~700ms)
  static Uint8List _synthesizeChallengeBang() {
    final numSamples = (_sampleRate * 0.7).toInt();
    final samples = <int>[];
    final rand = Random(99);

    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      final progress = i / numSamples;
      final env = exp(-6.5 * progress);
      final noise = (rand.nextDouble() * 2 - 1) * exp(-18.0 * progress);
      final strike = sin(2 * pi * 180.0 * (1.0 - progress * 0.5) * t);
      final wave = noise * 0.6 + strike * 0.4;
      samples.add((wave * env * 30000).toInt());
    }
    return _createWav(samples);
  }

  /// 6. 胜利大捷乐曲 (Victory) - 明快四度/五度上扬和弦大乐 (~900ms)
  static Uint8List _synthesizeVictory() {
    final numSamples = (_sampleRate * 0.9).toInt();
    final samples = <int>[];
    // C5, E5, G5, C6 辉煌大三和弦分解
    final notes = [523.25, 659.25, 783.99, 1046.5];
    final noteDuration = numSamples ~/ 4;

    for (int i = 0; i < numSamples; i++) {
      final noteIndex = min(i ~/ noteDuration, 3);
      final freq = notes[noteIndex];
      final t = i / _sampleRate;
      final noteLocalProgress = (i % noteDuration) / noteDuration;
      final env = exp(-4.0 * noteLocalProgress);
      final wave = sin(2 * pi * freq * t) * 0.7 + sin(2 * pi * freq * 2 * t) * 0.3;
      samples.add((wave * env * 24000).toInt());
    }
    return _createWav(samples);
  }

  /// 7. 失利沮丧乐曲 (Defeat) - 下行小调慢音落寞音效 (~700ms)
  static Uint8List _synthesizeDefeat() {
    final numSamples = (_sampleRate * 0.7).toInt();
    final samples = <int>[];
    final notes = [440.0, 392.0, 349.23, 293.66]; // A4, G4, F4, D4
    final noteDuration = numSamples ~/ 4;

    for (int i = 0; i < numSamples; i++) {
      final noteIndex = min(i ~/ noteDuration, 3);
      final freq = notes[noteIndex];
      final t = i / _sampleRate;
      final noteLocalProgress = (i % noteDuration) / noteDuration;
      final env = exp(-4.0 * noteLocalProgress);
      final wave = sin(2 * pi * freq * t);
      samples.add((wave * env * 20000).toInt());
    }
    return _createWav(samples);
  }

  /// 8. 背景音乐长循环 (BGM Loop) - 欢快舒缓聚会木琴小调 (~4.8秒循环)
  static Uint8List _synthesizeBgmLoop() {
    const double bgmSeconds = 4.8;
    final int numSamples = (_sampleRate * bgmSeconds).toInt();
    final samples = <int>[];

    // C大调轻快跳跃旋律音符 (C5, G4, A4, F4, E4, D4, G4, C5)
    final melody = [523.25, 392.00, 440.00, 349.23, 329.63, 293.66, 392.00, 523.25];
    final noteLen = numSamples ~/ melody.length;

    for (int i = 0; i < numSamples; i++) {
      final step = i ~/ noteLen;
      final freq = melody[step % melody.length];
      final t = i / _sampleRate;
      final noteProgress = (i % noteLen) / noteLen;
      // 柔和木琴/拨弦包络
      final env = exp(-5.0 * noteProgress);
      final bass = sin(2 * pi * (freq / 2) * t) * 0.35;
      final lead = sin(2 * pi * freq * t) * 0.5 + sin(2 * pi * freq * 2 * t) * 0.15;
      final wave = lead + bass;
      samples.add((wave * env * 14000).toInt());
    }

    return _createWav(samples);
  }

  /// 释放播放器资源
  Future<void> dispose() async {
    await _bgmPlayer?.dispose();
    await _sfxPlayer?.dispose();
  }
}
