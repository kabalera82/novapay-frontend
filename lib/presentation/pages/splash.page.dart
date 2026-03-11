// lib/presentation/pages/splash.page.dart
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'login.page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  static const String routename = '/splash';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final Player _player;
  late final VideoController _controller;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);

    _player.open(Media('asset:///assets/videos/novapay.mp4'));
_player.setPlaylistMode(PlaylistMode.none);

// espera a que el player esté listo antes de setear volumen
_player.stream.playing.listen((_) {
  _player.setVolume(100);
});

    _player.stream.completed.listen((completed) {
      if (completed && mounted && !_hasNavigated) {
        _hasNavigated = true;
        Navigator.of(context).pushReplacementNamed(LoginPage.routename);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Video(
        controller: _controller,
        controls: NoVideoControls,
        fit: BoxFit.cover,
      ),
    );
  }
}