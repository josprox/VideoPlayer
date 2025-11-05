import 'package:flutter/material.dart';
import 'package:video/VideoListScreen.dart'; // Importa tu pantalla principal

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Reproductor de Video',
      debugShowCheckedModeBanner: false, // ¡Quita la banner de debug!
      
      // Aquí activamos Material 3
      theme: ThemeData(
        useMaterial3: true,
        // "Expressive" usa colores más vibrantes.
        // Cambia 'Colors.blue' por tu color favorito
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal, // Prueba con Colors.teal o Colors.deepPurple
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto', // Opcional: asegura una fuente consistente
      ),
      
      home: VideoListScreen(),
    );
  }
}