import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video/PreferencesService.dart';

class SettingsViewModel extends ChangeNotifier {
  final PreferencesService _prefsService = PreferencesService();
  
  List<String> _folderPaths = [];
  bool _isLoading = true;

  // Getters públicos para que la UI "escuche"
  List<String> get folderPaths => _folderPaths;
  bool get isLoading => _isLoading;

  SettingsViewModel() {
    loadPaths(); // Carga las carpetas al iniciar
  }

  // Lógica movida desde la UI
  Future<void> loadPaths() async {
    _isLoading = true;
    notifyListeners(); // Notifica a la UI que estamos cargando

    _folderPaths = await _prefsService.loadFolderPaths();
    
    _isLoading = false;
    notifyListeners(); // Notifica que terminamos y actualiza la UI
  }

  Future<void> pickAndAddFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Selecciona una carpeta de videos',
    );

    if (selectedDirectory != null) {
      if (!_folderPaths.contains(selectedDirectory)) {
        _folderPaths.add(selectedDirectory);
        await _prefsService.saveFolderPaths(_folderPaths);
        notifyListeners(); // Notifica del cambio en la lista
      } else {
        // Aquí podrías manejar el feedback de "carpeta duplicada"
        // (ej. con un bool en el ViewModel y un SnackBar en la UI)
      }
    }
  }

  Future<void> removePath(String path) async {
    _folderPaths.remove(path);
    await _prefsService.saveFolderPaths(_folderPaths);
    notifyListeners(); // Notifica del cambio
  }
}