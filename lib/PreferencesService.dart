import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  // Ahora usamos una clave en plural
  final String _key = 'videoFolderPaths'; 

  Future<void> saveFolderPaths(List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    // Usamos setStringList para guardar una lista
    await prefs.setStringList(_key, paths);
  }

  Future<List<String>> loadFolderPaths() async {
    final prefs = await SharedPreferences.getInstance();
    // Usamos getStringList para recuperar la lista
    // Si no existe, devuelve una lista vacía
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> clearAllFolderPaths() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}