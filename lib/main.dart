import 'package:flutter/material.dart';
import 'package:video/screens/VideoListScreen.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:provider/provider.dart';
import 'package:video/vm/settings_view_model.dart';
import 'package:video/vm/video_list_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Envolvemos la app en MultiProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => VideoListViewModel()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  static final _defaultDarkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
    ),
    fontFamily: 'Roboto',
  );

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
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        
        ThemeData theme;
        ThemeData darkTheme;

        if (lightDynamic != null && darkDynamic != null) {
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