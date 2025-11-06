import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';

class YouTubeStyleVideoPlayer extends StatefulWidget {
  final File videoFile;
  const YouTubeStyleVideoPlayer({super.key, required this.videoFile});

  @override
  _YouTubeStyleVideoPlayerState createState() =>
      _YouTubeStyleVideoPlayerState();
}

class _YouTubeStyleVideoPlayerState extends State<YouTubeStyleVideoPlayer>
    with WidgetsBindingObserver {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  static const pipChannel = MethodChannel('pip_channel');
  bool _showControls = true;
  bool isInPiP = false;
  final bool _userInteracting = false;
  double _verticalDragStartY = 0;
  bool _changingVolume = false;
  String? _overlayLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPlayer();
    VolumeController().listener((volume) {});
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _initPlayer() async {
    _videoController = VideoPlayerController.file(widget.videoFile);
    await _videoController.initialize();

    _videoController.addListener(() {
      if (_videoController.value.isPlaying) {
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

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() => _showControls = false);
      }
    });

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
    final target =
        _videoController.value.position - const Duration(seconds: 10);
    _videoController.seekTo(target >= Duration.zero ? target : Duration.zero);
    setState(() => _overlayLabel = '« 10s');
    _clearOverlayLabel();
  }

  void _onDoubleTapRight() {
    final target =
        _videoController.value.position + const Duration(seconds: 10);
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
    _changingVolume =
        details.localPosition.dx > (MediaQuery.of(context).size.width / 2);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) async {
    final delta = (_verticalDragStartY - details.localPosition.dy) / 1200;

    if (_changingVolume) {
      double current = await VolumeController().getVolume();
      double next = (current + delta).clamp(0.0, 1.0);
      VolumeController().setVolume(next);
    } else {
      double current = await ScreenBrightness().current;
      double next = (current + delta).clamp(0.0, 1.0);
      ScreenBrightness().setScreenBrightness(next);
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
    final current =
        _chewieController?.videoPlayerController.value.playbackSpeed ?? 1.0;
    final next = (speeds.indexOf(current) + 1) % speeds.length;
    await _videoController.setPlaybackSpeed(speeds[next]);
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!Platform.isAndroid) return;

    if (state == AppLifecycleState.paused) {
      if (_videoController.value.isInitialized &&
          !_videoController.value.isPlaying) {
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // --- UI: Controles estilo YouTube ---
  Widget _buildControls() {
    final pos = _videoController.value.position;
    final dur = _videoController.value.duration;

    return AnimatedOpacity(
      opacity: _showControls ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // --- TOP ---
            SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.speed),
                    onPressed: _changePlaybackSpeed,
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.picture_in_picture_alt),
                    onPressed: enterNativePiP,
                  ),
                ],
              ),
            ),

            // --- PLAY BUTTON ---
            Center(
              child: IconButton(
                iconSize: 56,
                color: Colors.white,
                icon: Icon(
                  _videoController.value.isPlaying
                      ? Icons.pause_circle
                      : Icons.play_circle,
                ),
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

            // --- BOTTOM: PROGRESS + TIMES ---
            Column(
              children: [
                VideoProgressIndicator(
                  _videoController,
                  allowScrubbing: true,
                  colors: VideoProgressColors(playedColor: Colors.red),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(pos),
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        _formatDuration(dur),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Center(
        child:
            _chewieController != null &&
                _chewieController!.videoPlayerController.value.isInitialized
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTap,
                onVerticalDragStart: _onVerticalDragStart,
                onVerticalDragUpdate: _onVerticalDragUpdate,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // --- VIDEO ---
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: _videoController.value.size.width,
                          height: _videoController.value.size.height,
                          child: Chewie(controller: _chewieController!),
                        ),
                      ),
                    ),

                    // --- DOUBLE TAP ZONES ---
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

                    // --- SEEK LABEL ---
                    if (_overlayLabel != null)
                      Positioned(top: 40, child: _buildOverlayLabel()),

                    // --- CONTROLES ---
                    IgnorePointer(
                      ignoring: !_showControls,
                      child: Positioned.fill(
                        child: Container(
                          color: Colors.black26,
                          child: _buildControls(),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildOverlayLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _overlayLabel!,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
