import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video/VideoPlayerScreen.dart'; // Asegúrate que la ruta sea correcta

// Renombrado de _VideoListItem a VideoListItem
class VideoListItem extends StatefulWidget {
  final File videoFile;

  // Actualiza el constructor
  const VideoListItem({required Key key, required this.videoFile}) : super(key: key);

  // Renombrado de _VideoListItemState a VideoListItemState
  @override
  VideoListItemState createState() => VideoListItemState();
}

// Renombrado de _VideoListItemState a VideoListItemState
class VideoListItemState extends State<VideoListItem> {
  // Instanciamos el plugin de thumbnails
  final _thumbnailPlugin = FcNativeVideoThumbnail();

  String? _thumbnailPath;
  late String _fileName;
  bool _thumbnailError = false; 
  
  @override
  void initState() {
    super.initState();
    // Obtenemos el nombre del archivo desde la ruta
    _fileName = widget.videoFile.path.split(Platform.pathSeparator).last;
    // Iniciamos la generación de la miniatura
    _generateThumbnail();
  }

  /// Genera una miniatura para el video y la guarda en el directorio temporal.
  Future<void> _generateThumbnail() async {
    // Si ya falló una vez, no reintenta
    if (_thumbnailError) return;

    try {
      final tempDir = await getTemporaryDirectory();
      
      // Creamos un nombre de archivo único para la miniatura
      final thumbName = 'thumb_${_fileName.hashCode}.webp';
      final destPath = '${tempDir.path}${Platform.pathSeparator}$thumbName';

      // Usamos el plugin para crear el thumbnail
      await _thumbnailPlugin.getVideoThumbnail(
        srcFile: widget.videoFile.path,
        destFile: destPath,
        width: 360,
        height: 360, // El plugin ajustará el aspect ratio
        format: 'webp',
        quality: 75,
      );

      // Si el widget sigue "montado" (visible), actualizamos el estado
      if (mounted) {
        setState(() {
          _thumbnailPath = destPath; // Guardamos la ruta de la miniatura
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

  /// Navega a la pantalla del reproductor de video.
  void _playVideo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(videoFile: widget.videoFile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hero permite la animación de transición a la pantalla del player
    return Hero(
      tag: widget.videoFile.path, 
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
        child: InkWell(
          onTap: _playVideo,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // 1. El fondo (la miniatura o el placeholder)
              _buildThumbnail(),
              
              // 2. El gradiente oscuro en la parte inferior
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 1.0], 
                  ),
                ),
              ),

              // 3. El texto (nombre del archivo)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  _fileName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 2.0, color: Colors.black.withValues(alpha:0.5))]
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Decide qué mostrar: la miniatura, un placeholder de carga o un error.
  Widget _buildThumbnail() {
    // Caso 1: Aún no hay ruta o hubo un error
    if (_thumbnailPath == null || _thumbnailError) {
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
              // Si hubo error, muestra un texto
              if (_thumbnailError) ...[ 
                SizedBox(height: 8),
                Text(
                  "Error cargando",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } 
    
    // Caso 2: Tenemos una ruta, mostramos la imagen
    else {
      return Image.file(
        File(_thumbnailPath!),
        fit: BoxFit.cover, 
        width: double.infinity, 
        height: double.infinity,
        
        // Muestra un ícono de error si la imagen no se puede cargar
        errorBuilder: (context, error, stackTrace) {
          debugPrint("ERROR al cargar imagen thumbnail de la ruta $_thumbnailPath: $error");
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

        // Animación de Fade-in para la imagen
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
}