import 'package:app_desktop/app_data.dart';
import 'package:flutter/material.dart';
import 'package:app_desktop/login.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Establir mida mínima (per evitar textos solapats)
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = WindowOptions(
    minimumSize: Size(650, 800)
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppData(),
      child: const App(),
    )
  );
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> {
    @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
            colorScheme: .fromSeed(seedColor: Colors.cyan)
        ),
        home: Login(),
    );
  }
}