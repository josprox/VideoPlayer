import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video/PreferencesService.dart'; // Importa tu servicio

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _prefsService = PreferencesService();
  List<String> _folderPaths = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    setState(() { _isLoading = true; });
    _folderPaths = await _prefsService.loadFolderPaths();
    setState(() { _isLoading = false; });
  }

  Future<void> _pickFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Selecciona una carpeta de videos',
    );

    if (selectedDirectory != null) {
      if (!_folderPaths.contains(selectedDirectory)) {
        setState(() {
          _folderPaths.add(selectedDirectory);
        });
        await _prefsService.saveFolderPaths(_folderPaths);
      } else {
        // Opcional: Mostrar un SnackBar si la carpeta ya existe
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Esa carpeta ya está en la lista.')),
        );
      }
    }
  }

  Future<void> _removePath(String path) async {
    setState(() {
      _folderPaths.remove(path);
    });
    await _prefsService.saveFolderPaths(_folderPaths);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración de Carpetas'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildPathList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickFolder,
        icon: Icon(Icons.add),
        label: Text('Añadir Carpeta'),
      ),
    );
  }

  Widget _buildPathList() {
    if (_folderPaths.isEmpty) {
      return Center(
        child: Text(
          'No has añadido ninguna carpeta.\nUsa el botón (+) para empezar.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: _folderPaths.length,
      itemBuilder: (context, index) {
        final path = _folderPaths[index];
        // Acortamos el path para que se vea bien
        final displayPath = path.split(RegExp(r'[/\\]')).last; // Muestra solo el nombre de la carpeta

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: Icon(Icons.folder_copy_outlined, color: Theme.of(context).colorScheme.secondary),
            title: Text(displayPath),
            subtitle: Text(path), // Muestra la ruta completa
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              onPressed: () => _removePath(path),
            ),
          ),
        );
      },
    );
  }
}