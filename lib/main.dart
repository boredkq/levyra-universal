import 'package:flutter/material.dart';
import 'core/theme/levyra_theme.dart';
import 'ui/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LevyraApp());
}

class LevyraApp extends StatelessWidget {
  const LevyraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Levyra Music',
      debugShowCheckedModeBanner: false,
      theme: LevyraTheme.darkTheme,
      home: const MainShell(),
    );
  }
}
