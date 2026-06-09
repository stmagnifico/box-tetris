import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/seed_config_loader.dart';
import 'features/boxes/presentation/providers/box_list_provider.dart';
import 'features/boxes/presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final seedBoxes = await SeedConfigLoader.load();

  runApp(
    ProviderScope(
      overrides: [
        if (seedBoxes != null)
          boxListProvider.overrideWith(
            (ref) => BoxListNotifier(seedBoxes),
          ),
      ],
      child: const BoxTetrisApp(),
    ),
  );
}

class BoxTetrisApp extends StatelessWidget {
  const BoxTetrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Box Tetris',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
