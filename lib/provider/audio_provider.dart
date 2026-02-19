import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio_background/just_audio_background.dart';

class AudioPlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  bool _isPlaying = false;
  LoopMode _loopMode = LoopMode.off;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _speed = 1.0;
  double _pitch = 1.0;

  List<SongModel> _songs = [];
  SongModel? _currentSong;
  int _currentIndex = -1;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<bool>? _playingSubscription;

  bool get isPlaying => _isPlaying;
  LoopMode get loopMode => _loopMode;
  bool get isRepeatOne => _loopMode == LoopMode.one;
  bool get isLoopAll => _loopMode == LoopMode.all;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  double get speed => _speed;
  double get pitch => _pitch;
  SongModel? get currentSong => _currentSong;
  List<SongModel> get songs => _songs;
  AudioPlayer get player => _player;
  bool get hasNext => _currentIndex < _songs.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  AudioPlayerProvider() {
    _init();
  }

  void _init() {
    // Disable system volume UI for programmatic changes so we can use
    // our custom in-app slider without the OS volume overlay.
    try {
      VolumeController().showSystemUI = false;
    } catch (_) {}

    _positionSubscription = _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _durationSubscription = _player.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });

    // Listen to playing state
    _playingSubscription = _player.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    // Handle song completion
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        if (_loopMode == LoopMode.one) {
          _player.seek(Duration.zero);
          _player.play();
        } else if (_loopMode == LoopMode.all) {
          // if loop all, play next or wrap to first
          if (_songs.isNotEmpty) {
            if (_currentIndex < _songs.length - 1) {
              playNext();
            } else {
              // wrap to first
              playSong(_songs[0]);
            }
          }
        } else {
          playNext();
        }
      }
    });

    try {
      VolumeController().listener((v) {
        try {
          final val = (v as num).toDouble().clamp(0.0, 1.0);
          _volume = val;
          _player.setVolume(_volume);
          notifyListeners();
        } catch (_) {}
      });

      VolumeController().getVolume().then((v) {
        try {
          _volume = (v as num).toDouble().clamp(0.0, 1.0);
          _player.setVolume(_volume);
          notifyListeners();
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('VolumeController init error: $e');
    }
  }

  Future<void> setSpeed(double value) async {
    _speed = value.clamp(0.7, 1.4);
    try {
      await _player.setSpeed(_speed);
    } catch (e) {
      debugPrint('Error setting speed: $e');
    }
    notifyListeners();
  }

  Future<void> setPitch(double value) async {
    _pitch = value.clamp(0.7, 1.4);
    try {
      await _player.setPitch(_pitch);
    } catch (e) {
      debugPrint('Error setting pitch: $e');
    }
    notifyListeners();
  }

  Future<void> loadSongs() async {
    try {
      // if (Platform.isAndroid) {
      //   final status = await Permission.audio.request();
      //   if (status.isDenied) {
      //     throw Exception('Storage permission denied');
      //   }
      // }

      final raw = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      // Respect user preference to exclude short songs (< 15s)
      try {
        final prefs = await SharedPreferences.getInstance();
        final excludeShort = prefs.getBool('exclude_short_songs') ?? false;
        if (excludeShort) {
          _songs = raw.where((s) {
            final dur = s.duration ?? 0;
            return dur >= 15000;
          }).toList();
        } else {
          _songs = raw;
        }
      } catch (e) {
        _songs = raw;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading songs: $e');
      rethrow;
    }
  }

  Future<void> playSong(SongModel song) async {
    try {
      _currentSong = song;
      _currentIndex = _songs.indexOf(song);

      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(song.uri!),
          tag: MediaItem(
            id: song.id.toString(),
            title: song.displayNameWOExt,
            artist: song.artist,
            artUri: Uri.parse(
              'content://media/external/audio/albumart/${song.albumId}',
            ),
          ),
        ),
      );
      await _player.play();
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing song: $e');
    }
  }

  void playPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  Future<void> playNext() async {
    if (_currentSong == null || _songs.isEmpty) return;
    if (hasNext) {
      await playSong(_songs[_currentIndex + 1]);
    } else if (_loopMode == LoopMode.all) {
      // wrap to first
      await playSong(_songs[0]);
    }
  }

  Future<void> playPrevious() async {
    if (_currentSong == null || _songs.isEmpty) return;
    if (hasPrevious) {
      await playSong(_songs[_currentIndex - 1]);
    } else if (_loopMode == LoopMode.all) {
      // wrap to last
      await playSong(_songs[_songs.length - 1]);
    }
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    try {
      try {
        VolumeController().setVolume(_volume);
      } catch (_) {}
      await _player.setVolume(_volume);
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
    notifyListeners();
  }

  /// Cycle loop mode: off -> one -> all -> off
  void toggleRepeat() {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.one;
    } else if (_loopMode == LoopMode.one) {
      _loopMode = LoopMode.all;
    } else {
      _loopMode = LoopMode.off;
    }
    try {
      _player.setLoopMode(_loopMode);
    } catch (_) {}
    notifyListeners();
  }

  // Format duration helper
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playingSubscription?.cancel();
    try {
      VolumeController().removeListener();
    } catch (_) {}
    _player.dispose();
    super.dispose();
  }
}
