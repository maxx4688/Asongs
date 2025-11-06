import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:volume_controller/volume_controller.dart';

class AudioPlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  // Current playback state
  bool _isPlaying = false;
  // loop mode: off / one / all
  LoopMode _loopMode = LoopMode.off;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;

  // Current song and playlist
  List<SongModel> _songs = [];
  SongModel? _currentSong;
  int _currentIndex = -1;

  // Subscriptions
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<bool>? _playingSubscription;

  // Getters
  bool get isPlaying => _isPlaying;
  LoopMode get loopMode => _loopMode;
  bool get isRepeatOne => _loopMode == LoopMode.one;
  bool get isLoopAll => _loopMode == LoopMode.all;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  SongModel? get currentSong => _currentSong;
  List<SongModel> get songs => _songs;
  AudioPlayer get player => _player;
  bool get hasNext => _currentIndex < _songs.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  AudioPlayerProvider() {
    _init();
  }

  void _init() {
    // Listen to position changes
    _positionSubscription = _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    // Listen to duration changes
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

  Future<void> loadSongs() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.audio.request();
        if (status.isDenied) {
          throw Exception('Storage permission denied');
        }
      }

      _songs = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
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
        AudioSource.uri(Uri.parse(song.uri!)),
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
