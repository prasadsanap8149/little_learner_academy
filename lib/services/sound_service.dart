import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _effectsPlayer = AudioPlayer();
  bool _isMuted = false;
  double _musicVolume = 0.6;
  double _effectsVolume = 0.8;

  // Sound paths
  static const String _soundPath = 'sounds/';
  static const String successSound = '${_soundPath}success.mp3';
  static const String errorSound = '${_soundPath}error.mp3';
  static const String clickSound = '${_soundPath}click.mp3';
  static const String achievementSound = '${_soundPath}achievement.mp3';
  static const String levelCompleteSound = '${_soundPath}level_complete.mp3';
  static const String backgroundMusic = '${_soundPath}background_music.mp3';
  
  // Game-specific sounds
  static const String animalSound = '${_soundPath}animal_sound.mp3';
  static const String letterSound = '${_soundPath}letter_sound.mp3';
  static const String numberSound = '${_soundPath}number_sound.mp3';

  Future<void> initialize() async {
    await _musicPlayer
        .setReleaseMode(ReleaseMode.loop); // Loop background music
    await _effectsPlayer.setReleaseMode(ReleaseMode.release);
    
    // Set initial volumes
    await _musicPlayer.setVolume(_musicVolume);
    await _effectsPlayer.setVolume(_effectsVolume);
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

  // Game-specific sound effects
  Future<void> playAnimalSound() async {
    if (_isMuted) return;
    try {
      await _effectsPlayer.play(AssetSource(animalSound));
    } catch (e) {
      print('Sound file not found: $animalSound');
    }
  }

  Future<void> playLetterSound() async {
    if (_isMuted) return;
    try {
      await _effectsPlayer.play(AssetSource(letterSound));
    } catch (e) {
      print('Sound file not found: $letterSound');
    }
  }

  Future<void> playNumberSound() async {
    if (_isMuted) return;
    try {
      await _effectsPlayer.play(AssetSource(numberSound));
    } catch (e) {
      print('Sound file not found: $numberSound');
    }
  }

  // Play specific sounds with custom parameters
  Future<void> playCustomSound(String soundPath) async {
    if (_isMuted) return;
    try {
      await _effectsPlayer.play(AssetSource(soundPath));
    } catch (e) {
      print('Sound file not found: $soundPath');
    }
  }

  // Volume Controls
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume;
    await _musicPlayer.setVolume(volume);
  }

  Future<void> setEffectsVolume(double volume) async {
    _effectsVolume = volume;
    await _effectsPlayer.setVolume(volume);
  }

  double get musicVolume => _musicVolume;
  double get effectsVolume => _effectsVolume;

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

  // Load settings from preferences
  Future<void> loadSettings({
    bool? soundEnabled,
    bool? musicEnabled,
    double? soundVolume,
    double? musicVolume,
  }) async {
    if (soundEnabled != null) {
      setMuted(!soundEnabled);
    }
    if (soundVolume != null) {
      await setEffectsVolume(soundVolume);
    }
    if (musicVolume != null) {
      await setMusicVolume(musicVolume);
    }
    if (musicEnabled == true && !_isMuted) {
      await playBackgroundMusic();
    } else if (musicEnabled == false) {
      await stopBackgroundMusic();
    }
  }

  // Cleanup
  Future<void> dispose() async {
    await _musicPlayer.dispose();
    await _effectsPlayer.dispose();
  }
}
