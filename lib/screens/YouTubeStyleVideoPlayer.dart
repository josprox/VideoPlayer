import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// YouTube-style player WITHOUT foreground service / notifications.
/// Limpio, estable y completamente funcional para reproducción local.

class YouTubeStyleVideoPlayer extends StatefulWidget {
  final File videoFile;
  const YouTubeStyleVideoPlayer({super.key, required this.videoFile});

  @override
  _YouTubeStyleVideoPlayerState createState() => _YouTubeStyleVideoPlayerState();
}

class _YouTubeStyleVideoPlayerState extends State<YouTubeStyleVideoPlayer>
    with WidgetsBindingObserver {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  static const pipChannel = MethodChannel('pip_channel');
  bool _showControls = true;
  bool isInPiP = false;
  bool _userInteracting = false;
  double _verticalDragStartY = 0;
  bool _changingVolume = false;
  String? _overlayLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPlayer();

    VolumeController().listener((volume) {});
  }

  Future<void> _initPlayer() async {
    _videoController = VideoPlayerController.file(widget.videoFile);
    await _videoController.initialize();

    _videoController.addListener(() {
      final isPlaying = _videoController.value.isPlaying;
      if (isPlaying) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    });

    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoController.value.aspectRatio,
      showControls: false,
    );

    setState(() {});
  }

  Future<void> enterNativePiP() async {
    if (!Platform.isAndroid) return;
    setState(() => isInPiP = true);
    try {
      await pipChannel.invokeMethod('enterPip');
    } catch (e) {
      debugPrint('Error entrando en PiP: $e');
    }
  }

  // --- Gestos ---
  void _onDoubleTapLeft() {
    final target = _videoController.value.position - const Duration(seconds: 10);
    _videoController.seekTo(target >= Duration.zero ? target : Duration.zero);
    setState(() => _overlayLabel = '« 10s');
    _clearOverlayLabel();
  }

  void _onDoubleTapRight() {
    final target = _videoController.value.position + const Duration(seconds: 10);
    final max = _videoController.value.duration;
    _videoController.seekTo(target <= max ? target : max);
    setState(() => _overlayLabel = '10s »');
    _clearOverlayLabel();
  }

  void _clearOverlayLabel() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _overlayLabel = null);
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _verticalDragStartY = details.localPosition.dy;
    _changingVolume = details.localPosition.dx > (MediaQuery.of(context).size.width / 2);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) async {
    final delta = (_verticalDragStartY - details.localPosition.dy) / 300;
    if (_changingVolume) {
      final current = await VolumeController().getVolume();
      var next = (current + delta).clamp(0.0, 1.0);
      VolumeController().setVolume(next);
    } else {
      final current = await ScreenBrightness().current;
      var next = (current + delta).clamp(0.0, 1.0);
      await ScreenBrightness().setScreenBrightness(next);
    }
  }

  void _onTap() {
    setState(() => _showControls = !_showControls);

    if (_showControls) {
      Future.delayed(const Duration(seconds: 5)).then((_) {
        if (mounted && !_userInteracting) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _changePlaybackSpeed() async {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final current = _chewieController?.videoPlayerController.value.playbackSpeed ?? 1.0;
    final nextIndex = (speeds.indexOf(current) + 1) % speeds.length;
    await _videoController.setPlaybackSpeed(speeds[nextIndex]);
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!Platform.isAndroid) return;

    if (state == AppLifecycleState.paused) {
      if (_videoController.value.isInitialized && !_videoController.value.isPlaying) {
        _videoController.play();
      }
      enterNativePiP();
    }

    if (state == AppLifecycleState.resumed) {
      setState(() => isInPiP = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  // --- UI helpers ---
  Widget _buildControls() {
    final position = _videoController.value.position;
    final duration = _videoController.value.duration;

    return AnimatedOpacity(
      opacity: _showControls ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: Column(
        children: [
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.speed),
                    color: Colors.white,
                    onPressed: _changePlaybackSpeed,
                  ),
                ])
              ],
            ),
          ),

          Expanded(
            child: Center(
              child: IconButton(
                iconSize: 56,
                color: Colors.white,
                icon: Icon(_videoController.value.isPlaying ? Icons.pause_circle : Icons.play_circle),
                onPressed: () {
                  if (_videoController.value.isPlaying) {
                    _videoController.pause();
                  } else {
                    _videoController.play();
                  }
                  setState(() {});
                },
              ),
            ),
          ),

          Column(
            children: [
              VideoProgressIndicator(
                _videoController,
                allowScrubbing: true,
                colors: VideoProgressColors(playedColor: Colors.red),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(position), style: const TextStyle(color: Colors.white)),
                    Text(_formatDuration(duration), style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final twoDigits = (int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    final hours = d.inHours;
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: isInPiP
          ? null
          : null,
      body: Center(
        child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTap,
                onDoubleTap: () {},
                onVerticalDragStart: _onVerticalDragStart,
                onVerticalDragUpdate: _onVerticalDragUpdate,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Chewie(controller: _chewieController!),

                    Positioned.fill(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onDoubleTap: _onDoubleTapLeft,
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onDoubleTap: _onDoubleTapRight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_overlayLabel != null)
                      Positioned(top: 40, child: _buildOverlayLabel()),

                    Positioned.fill(child: _buildControls()),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Cargando video...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOverlayLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(_overlayLabel!, style: const TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}