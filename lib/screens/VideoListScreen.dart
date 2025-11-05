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

  @override
  Widget build(BuildContext context) {
    // "Observamos" el ViewModel
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
              floating: true, 
              snap: true,      
            ),
          ];
        },
        // El onRefresh ahora llama al ViewModel
        body: RefreshIndicator(
          onRefresh: () => context.read<VideoListViewModel>().loadVideos(), 
          child: _buildBody(context, viewModel), // Pasamos el viewModel
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
      itemCount: viewModel.videoFiles.length,
      itemBuilder: (context, index) {
        File videoFile = viewModel.videoFiles[index];
        return VideoListItem(key: ValueKey(videoFile.path), videoFile: videoFile);
      },
    );
  }
}