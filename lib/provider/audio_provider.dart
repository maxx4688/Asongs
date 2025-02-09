import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isRepeatOne = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String _songName = "Song Name";

  bool get isPlaying => _isPlaying;
  File? _audioFile;
  bool get repeat => _isRepeatOne;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  String get songName => _songName;
  AudioPlayer get audioPlayer => _audioPlayer;
  File? get audioFile => _audioFile;

  List<File> _playlist = [];
  int _currentIndex = 0;

  List<File> get playlist => _playlist;
  int get currentIndex => _currentIndex;

  void play() {
    _isPlaying = true;
    _audioPlayer.play();
  }

  Future<void> setAudioFile(File file, {List<File>? songs}) async {
    _audioFile = file;

    if (songs != null) {
      _playlist = songs;
      _currentIndex = _playlist.indexOf(file);
    }

    try {
      await _audioPlayer.setFilePath(file.path);
      _totalDuration = _audioPlayer.duration ?? Duration.zero;

      _audioPlayer.positionStream.listen((duration) {
        _currentPosition = duration;
        _songName = _audioFile!.path.split('/').last;
        notifyListeners();
      });

      listenToCompletion();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading audio file: $e");
    }
  }

  void playNextSong() {
    if (_playlist.isNotEmpty) {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
      setAudioFile(_playlist[_currentIndex]);
      play();
    }
    notifyListeners();
  }

  void playPreviousSong() {
    if (_playlist.isNotEmpty) {
      _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
      setAudioFile(_playlist[_currentIndex]);
      play();
    }
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeatOne = !_isRepeatOne;
    _audioPlayer.setLoopMode(_isRepeatOne ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }

  void playSong() {
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
      _audioPlayer.play();
    } else {
      _audioPlayer.pause();
    }
    notifyListeners();
  }

  StreamSubscription? _playerStateSubscription;

  void listenToCompletion() {
    _playerStateSubscription?.cancel(); // Cancel any existing listener

    _playerStateSubscription =
        _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        playNextSong();
      }
    });
  }

  void seekTo(Duration position) {
    _audioPlayer.seek(position);
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
