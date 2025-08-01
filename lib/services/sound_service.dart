import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _effectsPlayer = AudioPlayer();
  bool _isMuted = false;

  // Sound paths
  static const String _soundPath = 'sounds/';
  static const String successSound = '${_soundPath}success.mp3';
  static const String errorSound = '${_soundPath}error.mp3';
  static const String clickSound = '${_soundPath}click.mp3';
  static const String achievementSound = '${_soundPath}achievement.mp3';
  static const String levelCompleteSound = '${_soundPath}level_complete.mp3';
  static const String backgroundMusic = '${_soundPath}background_music.mp3';

  Future<void> initialize() async {
    await _musicPlayer
        .setReleaseMode(ReleaseMode.loop); // Loop background music
    await _effectsPlayer.setReleaseMode(ReleaseMode.release);
  }

  // Background Music Controls
  Future<void> playBackgroundMusic() async {
    if (_isMuted) return;
    try {
      await _musicPlayer.play(AssetSource(backgroundMusic));
    } catch (e) {
      // Handle missing sound file gracefully
      print('Sound file not found: $backgroundMusic');
    }
  }

  Future<void> stopBackgroundMusic() async {
    await _musicPlayer.stop();
  }

  Future<void> pauseBackgroundMusic() async {
    await _musicPlayer.pause();
  }

  Future<void> resumeBackgroundMusic() async {
    if (_isMuted) return;
    await _musicPlayer.resume();
  }

  // Sound Effects
  Future<void> playSuccess() async {
    if (_isMuted) return;
    try {
      await _effectsPlayer.play(AssetSource(successSound));
    } catch (e) {
      // Handle missing sound file gracefully
      print('Sound file not found: $successSound');
    }
  }

  Future<void> playError() async {
    if (_isMuted) return;
    try {
      await _effectsPlayer.play(AssetSource(errorSound));
    } catch (e) {
      // Handle missing sound file gracefully
      print('Sound file not found: $errorSound');
    }
  }

  Future<void> playClick() async {
    if (_isMuted) return;
    try {
      await _effectsPlayer.play(AssetSource(clickSound));
    } catch (e) {
      // Handle missing sound file gracefully
      print('Sound file not found: $clickSound');
    }
  }

  Future<void> playAchievement() async {
    if (_isMuted) return;
    try {
      await _effectsPlayer.play(AssetSource(achievementSound));
    } catch (e) {
      // Handle missing sound file gracefully
      print('Sound file not found: $achievementSound');
    }
  }

  Future<void> playLevelComplete() async {
    if (_isMuted) return;
    try {
      await _effectsPlayer.play(AssetSource(levelCompleteSound));
    } catch (e) {
      // Handle missing sound file gracefully
      print('Sound file not found: $levelCompleteSound');
    }
  }

  // Volume Controls
  Future<void> setMusicVolume(double volume) async {
    await _musicPlayer.setVolume(volume);
  }

  Future<void> setEffectsVolume(double volume) async {
    await _effectsPlayer.setVolume(volume);
  }

  // Mute Controls
  void setMuted(bool muted) {
    _isMuted = muted;
    if (muted) {
      _musicPlayer.stop();
    } else {
      playBackgroundMusic();
    }
  }

  bool get isMuted => _isMuted;

  // Cleanup
  Future<void> dispose() async {
    await _musicPlayer.dispose();
    await _effectsPlayer.dispose();
  }
}
