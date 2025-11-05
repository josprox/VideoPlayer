import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importar
import 'package:video/settings_view_model.dart'; // Importar

class SettingsScreen extends StatelessWidget { // Ahora puede ser StatelessWidget
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // "Observa" los cambios en el ViewModel
    final viewModel = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración de Carpetas'),
      ),
      body: viewModel.isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildPathList(context, viewModel), // Pasamos el viewModel
      floatingActionButton: FloatingActionButton.extended(
        // Llama al método del ViewModel
        onPressed: () => context.read<SettingsViewModel>().pickAndAddFolder(),
        icon: Icon(Icons.add),
        label: Text('Añadir Carpeta'),
      ),
    );
  }

  Widget _buildPathList(BuildContext context, SettingsViewModel viewModel) {
    if (viewModel.folderPaths.isEmpty) {
      return Center(
        child: Text(
          'No has añadido ninguna carpeta.\nUsa el botón (+) para empezar.',
          textAlign: TextAlign.center,
        ),
      );
    }

    // Usamos viewModel.folderPaths
    return ListView.builder(
      itemCount: viewModel.folderPaths.length,
      itemBuilder: (context, index) {
        final path = viewModel.folderPaths[index];
        final displayPath = path.split(RegExp(r'[/\\]')).last;

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: Icon(Icons.folder_copy_outlined, color: Theme.of(context).colorScheme.secondary),
            title: Text(displayPath),
            subtitle: Text(path),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              // Llama al método del ViewModel
              onPressed: () => context.read<SettingsViewModel>().removePath(path),
            ),
          ),
        );
      },
    );
  }
}