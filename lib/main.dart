import 'package:flutter/material.dart';

import 'audio_controller.dart';
import 'screens/home_shell.dart';
import 'theme.dart';

void main() => runApp(const EqPlayerApp());

class EqPlayerApp extends StatefulWidget {
  const EqPlayerApp({super.key});

  @override
  State<EqPlayerApp> createState() => _EqPlayerAppState();
}

class _EqPlayerAppState extends State<EqPlayerApp> {
  // One controller shared by every screen.
  final AudioController _controller = AudioController();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EQ Player',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomeShell(c: _controller),
    );
  }
}
