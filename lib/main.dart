import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'features/vapor_note/presentation/vapor_note_screen.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env', isOptional: true);
  runApp(const VaporApp());
}

class VaporApp extends StatelessWidget {
  const VaporApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vapor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF8A5CFF),
        ),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const VaporNoteScreen(),
    );
  }
}
