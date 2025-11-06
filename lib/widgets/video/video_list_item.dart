import 'dart:io';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video/screens/YouTubeStyleVideoPlayer.dart';

class VideoListItem extends StatefulWidget {
  final File videoFile;

  const VideoListItem({required Key key, required this.videoFile})
      : super(key: key);

  @override
  VideoListItemState createState() => VideoListItemState();
}

class VideoListItemState extends State<VideoListItem> {
  final _thumbnailPlugin = FcNativeVideoThumbnail();

  String? _thumbnailPath;
  late String _fileName;
  bool _thumbnailError = false;

  @override
  void initState() {
    super.initState();
    _fileName = widget.videoFile.path.split(Platform.pathSeparator).last;
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    // ... (Tu lógica de _generateThumbnail es excelente, no necesita cambios)
    if (_thumbnailError) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final thumbName = 'thumb_${_fileName.hashCode}.webp';
      final destPath = '${tempDir.path}${Platform.pathSeparator}$thumbName';

      await _thumbnailPlugin.getVideoThumbnail(
        srcFile: widget.videoFile.path,
        destFile: destPath,
        width: 360,
        height: 360,
        format: 'webp',
        quality: 75,
      );

      if (mounted) {
        setState(() {
          _thumbnailPath = destPath;
          _thumbnailError = false;
        });
      }
    } catch (e) {
      debugPrint("ERROR al generar thumbnail para $_fileName: $e");
      if (mounted) {
        setState(() {
          _thumbnailError = true;
          _thumbnailPath = null;
        });
      }
    }
  }

  void _playVideo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            YouTubeStyleVideoPlayer(videoFile: widget.videoFile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: widget.videoFile.path, // ¡La animación Hero es muy expresiva! Bien.
      child: Card(
        // <-- CAMBIO: Principios de M3
        elevation: 0, // 1. Usar elevación 0
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest, // 2. Usar elevación tonal
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: _playVideo,
          borderRadius:
              BorderRadius.circular(12), // Para que el ripple coincida
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // 1. El fondo (miniatura, shimmer o error)
                //    Tu widget _buildThumbnail es perfecto.
                _buildThumbnail(),

                // 2. El gradiente oscuro (scrim)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7) // <-- CAMBIO: Más sutil
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.4, 1.0], // <-- CAMBIO: Empezar un poco antes
                    ),
                  ),
                ),

                // 3. El texto
                Positioned(
                  // <-- CAMBIO: Más control sobre la posición
                  bottom: 8.0,
                  left: 10.0,
                  right: 10.0,
                  child: Text(
                    _fileName,
                    // <-- CAMBIO: Tipografía semántica de M3
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              blurRadius: 3.0,
                              color: Colors.black.withValues(alpha: 0.5),
                              offset: Offset(0, 1),
                            )
                          ],
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    // ... (Tu lógica de _buildThumbnail con Shimmer y estados de error es perfecta)
    // ... (¡No la cambies, es excelente UX!)

    // Caso 1: Hubo un error
    if (_thumbnailError) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.movie_filter_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 40,
              ),
              SizedBox(height: 8),
              Text(
                "Error cargando",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    // Caso 2: Aún no hay ruta (ESTAMOS CARGANDO)
    if (_thumbnailPath == null) {
      return _buildLoadingPlaceholder(); // <-- ¡Shimmer es genial!
    }

    // Caso 3: Tenemos una ruta, mostramos la imagen
    else {
      return Image.file(
        File(_thumbnailPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // Muestra un ícono de error si la imagen no se puede cargar
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
              "ERROR al cargar imagen thumbnail de la ruta $_thumbnailPath: $error");
          return Container(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Theme.of(context).colorScheme.onErrorContainer,
                size: 40,
              ),
            ),
          );
        },

        // Animación de Fade-in (¡Esto es muy M3 Expressive, excelente!)
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
      );
    }
  }

  /// WIDGET: El placeholder con efecto Shimmer
  Widget _buildLoadingPlaceholder() {
    final colors = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colors.surfaceContainerHighest,
      highlightColor: colors.surfaceContainerLowest,
      child: Container(
        // El "esqueleto" es solo un contenedor del color base
        color: colors.surfaceContainerHighest,
      ),
    );
  }
}