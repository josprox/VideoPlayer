import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video/vm/video_list_view_model.dart';
import 'package:video/widgets/video/video_list_item.dart';
import 'package:video/screens/SettingsScreen.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  _VideoListScreenState createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _goToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    );

    // ignore: use_build_context_synchronously
    context.read<VideoListViewModel>().loadVideos();
  }

  /// Calcula el padding horizontal para la rejilla basado en el ancho de la pantalla.
  EdgeInsets _calculateGridPadding(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    double horizontalPadding = 12.0; // Padding default para móviles

    if (screenWidth > 1200) {
      // Pantallas de PC muy anchas: centramos un contenedor de 1200px
      horizontalPadding = (screenWidth - 1200) / 2;
    } else if (screenWidth > 600) {
      // Tablets: usamos un padding mayor
      horizontalPadding = 24.0;
    }

    return EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: 16.0, // Un poco más de espacio vertical
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<VideoListViewModel>();

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
              floating: false,
              snap: false,
              pinned: true,
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: () => context.read<VideoListViewModel>().loadVideos(),
          child: _buildBody(context, viewModel),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, VideoListViewModel viewModel) {
    if (viewModel.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (!viewModel.hasFolders) {
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
                    Icon(Icons.folder_off_outlined,
                        size: 80,
                        color: Theme.of(context).colorScheme.secondary),
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

    if (viewModel.videoFiles.isEmpty) {
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
                    Icon(Icons.video_library_outlined,
                        size: 80,
                        color: Theme.of(context).colorScheme.secondary),
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
      // <-- Aplicamos el padding adaptativo
      padding: _calculateGridPadding(context),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250, // Esto sigue siendo bueno y flexible
        childAspectRatio:
            16 / 10, // <-- Un poco más de espacio vertical para el título
        crossAxisSpacing: 12, // <-- Un poco más de espacio
        mainAxisSpacing: 12, // <-- Un poco más de espacio
      ),
      itemCount: viewModel.videoFiles.length,
      itemBuilder: (context, index) {
        File videoFile = viewModel.videoFiles[index];
        return VideoListItem(
            key: ValueKey(videoFile.path), videoFile: videoFile);
      },
    );
  }
}