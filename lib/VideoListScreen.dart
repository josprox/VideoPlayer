import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video/PreferencesService.dart';
import 'package:video/VideoPlayerScreen.dart';
import 'package:video/SettingsScreen.dart'; // Importa la pantalla de Configuración
import 'package:device_info_plus/device_info_plus.dart'; // Para la versión de SDK
import 'package:permission_handler/permission_handler.dart'; // Para permisos

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  _VideoListScreenState createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  final PreferencesService _prefsService = PreferencesService();

  // Ahora es una LISTA de rutas
  List<String> _folderPaths = [];

  List<File> _videoFiles = [];
  bool _isLoading = true;

  final List<String> _videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.wmv'];

  @override
  void initState() {
    super.initState();
    _loadSavedPathAndVideos();
  }

  Future<void> _loadSavedPathAndVideos() async {
    setState(() { _isLoading = true; });

    // Cargar la LISTA de rutas
    _folderPaths = await _prefsService.loadFolderPaths();

    if (_folderPaths.isNotEmpty) {
      // Cargar videos desde TODAS las rutas
      await _loadVideosFromPaths(_folderPaths);
    } else {
      setState(() { _isLoading = false; });
    }
  }

  // Función actualizada para escanear MÚLTIPLES rutas
  Future<void> _loadVideosFromPaths(List<String> paths) async {
    setState(() {
      _isLoading = true;
      _videoFiles = [];
    });

    List<File> videosEncontrados = [];

    // Loop por CADA ruta que el usuario guardó
    for (String path in paths) {
      try {
        final dir = Directory(path);
        // Comprueba si la carpeta aún existe
        if (!await dir.exists()) continue; 

        // Usa el Stream para no bloquear la UI
        final Stream<FileSystemEntity> entities = dir.list(recursive: false);

        await for (final FileSystemEntity entity in entities) {
          if (entity is File) {
            String extension = '';
            try {
              // Obtenemos la extensión
              extension = entity.path.split('.').last.toLowerCase();
            } catch (e) {
              // Archivo sin extensión, lo saltamos
              continue;
            }
            // Comparamos con nuestra lista
            if (_videoExtensions.contains('.$extension')) {
              videosEncontrados.add(entity);
            }
          }
        }
      } catch (e) {
        print("Error leyendo el directorio $path: $e");
        // No limpiamos las prefs, solo informamos del error y continuamos
      }
    }

    setState(() {
      _videoFiles = videosEncontrados;
      _isLoading = false;
    });
  }

  // Función para navegar a la pantalla de Configuración
  void _goToSettings() async {
    // Usamos .then() para que cuando regrese de Configuración,
    // la lista de videos se actualice automáticamente.
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    ).then((_) {
      // Recarga todo cuando vuelve de la configuración
      _loadSavedPathAndVideos();
    });
  }

  // --- Lógica de Permisos (copiada de la versión anterior) ---

  Future<void> _requestPermissions() async {
    // En móvil, pide permisos primero
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
      // Retorna el nivel de SDK (ej. 33 para Android 13)
      return androidInfo.version.sdkInt;
    }
    return null;
  }
  
  // --- Fin de Lógica de Permisos ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // El nuevo AppBar M3 tiene el color por defecto
        title: Text("Mis Videos"),
        actions: [
          // Botón para ir a Configuración
          IconButton(
            icon: Icon(Icons.settings_outlined),
            onPressed: _goToSettings,
            tooltip: "Configuración",
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    // Estado de "No hay rutas"
    if (_folderPaths.isEmpty) {
      return Center(
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
              // Botón de M3 "Filled"
              FilledButton.icon(
                icon: Icon(Icons.settings),
                label: Text("Ir a Configuración"),
                onPressed: _goToSettings,
              ),
            ],
          ),
        ),
      );
    }

    // Estado de "Hay rutas pero no videos"
    if (_videoFiles.isEmpty) {
      return Center(
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
      );
    }

    // ¡Aquí está el diseño M3 Expressive!
    // Usamos Cards para un look más "contenido"
    return ListView.builder(
      padding: EdgeInsets.all(8), // Padding para que las cards no se peguen
      itemCount: _videoFiles.length,
      itemBuilder: (context, index) {
        File videoFile = _videoFiles[index];
        String fileName = videoFile.path.split(Platform.pathSeparator).last;

        // El estilo "Expressive"
        return Card(
          elevation: 2, // Sombra sutil
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: ListTile(
            leading: Icon(
              Icons.movie_filter_outlined, 
              color: Theme.of(context).colorScheme.primary // Color del tema
            ),
            title: Text(fileName, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              videoFile.parent.path, // Muestra la ruta de la carpeta
              maxLines: 1, 
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(videoFile: videoFile),
                ),
              );
            },
          ),
        );
      },
    );
  }
}