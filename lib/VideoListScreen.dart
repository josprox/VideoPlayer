import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart'; 
import 'package:path_provider/path_provider.dart';  

import 'package:video/PreferencesService.dart';
import 'package:video/VideoPlayerScreen.dart';
import 'package:video/SettingsScreen.dart'; 
import 'package:device_info_plus/device_info_plus.dart'; 
import 'package:permission_handler/permission_handler.dart';


// =========================================================================
// WIDGET 1: El item de la lista (Actualizado con el plugin multiplataforma)
// =========================================================================


class _VideoListItem extends StatefulWidget {
  final File videoFile;

  const _VideoListItem({required Key key, required this.videoFile}) : super(key: key);

  @override
  _VideoListItemState createState() => _VideoListItemState();
}

class _VideoListItemState extends State<_VideoListItem> {
  // ✅ Instanciamos el nuevo plugin
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

  // --- ✅ FUNCIÓN _generateThumbnail ACTUALIZADA ---
  Future<void> _generateThumbnail() async {
    if (_thumbnailError) return;

    try {
      final tempDir = await getTemporaryDirectory();
      
      // Este plugin necesita una RUTA DE DESTINO
      // Creamos un nombre de archivo único para el thumbnail
      final thumbName = 'thumb_${_fileName.hashCode}.webp';
      final destPath = '${tempDir.path}${Platform.pathSeparator}$thumbName';

      // Usamos el nuevo método del plugin
      await _thumbnailPlugin.getVideoThumbnail(
        srcFile: widget.videoFile.path,
        destFile: destPath,
        width: 360,
        height: 360, // El plugin ajustará el aspect ratio
        format: 'webp',
        quality: 75,
      );

      // Si todo salió bien, guardamos la RUTA DE DESTINO
      if (mounted) {
        setState(() {
          _thumbnailPath = destPath; // <-- Usamos la ruta de destino
          _thumbnailError = false; 
        });
      }
    } catch (e) {
      debugPrint("ERROR al generar thumbnail (multiplataforma) para $_fileName: $e");
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
        builder: (context) => VideoPlayerScreen(videoFile: widget.videoFile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // El 'build' se queda EXACTAMENTE IGUAL que antes
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
              _buildThumbnail(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.5, 1.0], 
                  ),
                ),
              ),
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

  // El '_buildThumbnail' se queda EXACTAMENTE IGUAL que antes
  Widget _buildThumbnail() {
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
    } else {
      return Image.file(
        File(_thumbnailPath!),
        fit: BoxFit.cover, 
        width: double.infinity, 
        height: double.infinity,
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

// ... (Aquí iría el resto de tu clase VideoListScreen sin cambios) ...
// =========================================================================
// WIDGET 2: Tu pantalla principal (VideoListScreen)
// =========================================================================
class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  _VideoListScreenState createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> with WidgetsBindingObserver {
  final PreferencesService _prefsService = PreferencesService();
  List<String> _folderPaths = [];
  List<File> _videoFiles = [];
  bool _isLoading = true;
  final List<String> _videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.wmv'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissions().then((_) {
      _loadSavedPathAndVideos();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("App reanudada. Buscando nuevos videos...");
      _loadSavedPathAndVideos();
    }
  }


  Future<void> _loadSavedPathAndVideos() async {
    setState(() { _isLoading = true; });
    _folderPaths = await _prefsService.loadFolderPaths();
    if (_folderPaths.isNotEmpty) {
      await _loadVideosFromPaths(_folderPaths);
    } else {
      if(mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _loadVideosFromPaths(List<String> paths) async {
    if(mounted) setState(() { _videoFiles = []; });

    List<File> videosEncontrados = [];
    for (String path in paths) {
      try {
        final dir = Directory(path);
        if (!await dir.exists()) continue;

        final Stream<FileSystemEntity> entities = dir.list(recursive: false);
        await for (final FileSystemEntity entity in entities) {
          if (entity is File) {
            String extension = '';
            try {
              extension = entity.path.split('.').last.toLowerCase();
            } catch (e) { continue; }
            if (_videoExtensions.contains('.$extension')) {
              videosEncontrados.add(entity);
            }
          }
        }
      } catch (e) {
        debugPrint("Error leyendo el directorio $path: $e");
      }
    }

    if(mounted) {
      setState(() {
        _videoFiles = videosEncontrados;
        _isLoading = false;
      });
    }
  }

  void _goToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    ).then((_) {
      _loadSavedPathAndVideos();
    });
  }

  // --- Lógica de Permisos (sin cambios) ---
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      var status = await Permission.storage.status;
      if (Platform.isAndroid && (await _getAndroidSDKVersion() ?? 0) >= 33) {
        status = await Permission.videos.status;
      }
      if (!status.isGranted) {
        if (Platform.isAndroid && (await _getAndroidSDKVersion() ?? 0) >= 33) {
          await Permission.videos.request();
        } else {
          await Permission.storage.request();
        }
      }
    }
  }
  Future<int?> _getAndroidSDKVersion() async {
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    }
    return null;
  }
  // --- Fin de Lógica de Permisos ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large( 
              title: Text("Mis Videos"),
              actions: [
                IconButton(
                  icon: Icon(Icons.settings_outlined),
                  onPressed: _goToSettings,
                  tooltip: "Configuración",
                ),
              ],
              floating: true, 
              snap: true,     
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _loadSavedPathAndVideos, 
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    // --- Estados vacíos (No hay carpetas / No hay videos) ---
    if (_folderPaths.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_off_outlined, size: 80, color: Theme.of(context).colorScheme.secondary),
                    SizedBox(height: 20),
                    Text(
                      "No has añadido carpetas", 
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Ve a Configuración para empezar a escanear tus videos.", 
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    FilledButton.icon(
                      icon: Icon(Icons.settings),
                      label: Text("Ir a Configuración"),
                      onPressed: _goToSettings,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (_videoFiles.isEmpty) {
      return LayoutBuilder(
         builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_library_outlined, size: 80, color: Theme.of(context).colorScheme.secondary),
                    SizedBox(height: 20),
                    Text(
                      "No se encontraron videos", 
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Revisa las carpetas en Configuración o añade una nueva.",
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
         ),
      );
    }

    // --- Layout de Rejilla (GridView) ---
    return GridView.builder(
      padding: EdgeInsets.all(12.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250, 
        childAspectRatio: 16 / 9, 
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _videoFiles.length,
      itemBuilder: (context, index) {
        File videoFile = _videoFiles[index];
        // ¡Importante! Añadimos una Key única a cada VideoListItem
        return _VideoListItem(key: ValueKey(videoFile.path), videoFile: videoFile);
      },
    );
  }
}