import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerScreen extends StatefulWidget {
  final File videoFile;

  const VideoPlayerScreen({super.key, required this.videoFile});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  bool isInPiP = false;
  static const pipChannel = MethodChannel("pip_channel");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _videoController = VideoPlayerController.file(widget.videoFile);
    await _videoController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoController.value.aspectRatio,
    );

    setState(() {});
  }

  Future<void> enterNativePiP() async {
    if (!Platform.isAndroid) return;

    setState(() => isInPiP = true);

    try {
      await pipChannel.invokeMethod("enterPip");
    } catch (e) {
      debugPrint("Error entrando en PiP: $e");
    }
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
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.videoFile.path.split(Platform.pathSeparator).last;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: isInPiP
          ? null
          : AppBar(
              title: Text(fileName),
              backgroundColor: Colors.black87,
              actions: [
                if (Platform.isAndroid)
                  IconButton(
                    icon: const Icon(Icons.picture_in_picture_alt_outlined),
                    onPressed: enterNativePiP,
                  ),
              ],
            ),
      body: Center(
        child: _chewieController != null &&
                _chewieController!.videoPlayerController.value.isInitialized
            ? Chewie(controller: _chewieController!)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    "Cargando video...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }
}
