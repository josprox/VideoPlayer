import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerScreen extends StatefulWidget {
  final File videoFile;

  const VideoPlayerScreen({Key? key, required this.videoFile}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  Future<void> initializePlayer() async {
    // 1. Inicializar el controlador de video_player
    _videoPlayerController = VideoPlayerController.file(widget.videoFile);
    await _videoPlayerController.initialize();

    // 2. Inicializar el controlador de Chewie
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      // Puedes añadir más configuraciones aquí
    );

    setState(() {
      // Actualiza la UI cuando el reproductor esté listo
    });
  }

  @override
  void dispose() {
    // 3. ¡MUY IMPORTANTE! Liberar los recursos
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.videoFile.path.split(Platform.pathSeparator).last),
      ),
      body: Center(
        child: _chewieController != null &&
                _chewieController!.videoPlayerController.value.isInitialized
            ? Chewie(
                controller: _chewieController!,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
}