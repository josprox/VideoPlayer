import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video/services/PreferencesService.dart';

class VideoListViewModel extends ChangeNotifier {
  final PreferencesService _prefsService = PreferencesService();
  
  List<String> _folderPaths = [];
  List<File> _videoFiles = [];
  bool _isLoading = true;

  final List<String> _videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.wmv'];

  // Getters públicos
  List<File> get videoFiles => _videoFiles;
  bool get isLoading => _isLoading;
  bool get hasFolders => _folderPaths.isNotEmpty;

  VideoListViewModel() {
    loadVideos(); // Carga los videos al iniciar
  }

  Future<void> loadVideos() async {
    _isLoading = true;
    notifyListeners();

    await _requestPermissions();
    _folderPaths = await _prefsService.loadFolderPaths();
    
    if (_folderPaths.isNotEmpty) {
      _videoFiles = []; // Limpia la lista antes de recargar
      List<File> videosEncontrados = [];

      for (String path in _folderPaths) {
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
      _videoFiles = videosEncontrados;
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- Lógica de Permisos ---
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
}