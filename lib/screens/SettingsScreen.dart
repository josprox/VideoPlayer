import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video/vm/settings_view_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración de Carpetas'),
      ),
      body: viewModel.isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildPathList(context, viewModel),
      floatingActionButton: FloatingActionButton.extended(
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

    return ListView.builder(
      itemCount: viewModel.folderPaths.length,
      itemBuilder: (context, index) {
        final path = viewModel.folderPaths[index];
        final displayPath = path.split(RegExp(r'[/\\]')).last;

        // <-- CAMBIO: Tarjeta con estilo "Outlined"
        return Card(
          shape: RoundedRectangleBorder(
            side: BorderSide( // Añade un borde sutil
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          color: Theme.of(context).colorScheme.surface, // Fondo normal
          elevation: 0, // Sin sombra
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: Icon(Icons.folder_copy_outlined, color: Theme.of(context).colorScheme.secondary),
            title: Text(displayPath),
            subtitle: Text(path),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              onPressed: () => context.read<SettingsViewModel>().removePath(path),
            ),
          ),
        );
      },
    );
  }
}