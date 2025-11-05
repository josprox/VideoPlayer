import 'package:flutter/material.dart';
import 'package:video/VideoListScreen.dart';
import 'package:dynamic_color/dynamic_color.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  // Temas de RESPALDO
  static final _defaultDarkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
    ),
    fontFamily: 'Roboto',
  );

  // Es buena práctica tener un respaldo para light mode también
  static final _defaultLightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    ),
    fontFamily: 'Roboto',
  );


  @override
  Widget build(BuildContext context) {
    // Usamos DynamicColorBuilder para obtener los colores del sistema
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        
        ThemeData theme;
        ThemeData darkTheme;

        if (lightDynamic != null && darkDynamic != null) {
          // Si hay colores dinámicos (Android 12+), los usuamos
          theme = ThemeData(
            useMaterial3: true,
            colorScheme: lightDynamic,
            fontFamily: 'Roboto',
          );
          darkTheme = ThemeData(
            useMaterial3: true,
            colorScheme: darkDynamic,
            fontFamily: 'Roboto',
          );
        } else {
          // Si NO hay, usa tus temas de respaldo
          theme = _defaultLightTheme;
          darkTheme = _defaultDarkTheme;
        }

        return MaterialApp(
          title: 'Video',
          debugShowCheckedModeBanner: false,
          
          theme: theme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.system, 
          
          home: VideoListScreen(),
        );
      },
    );
  }
}