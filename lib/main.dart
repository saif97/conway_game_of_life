import 'package:flutter/material.dart';

import 'ui/screen_home.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Life / A cellular playground',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFB8F36D),
        brightness: Brightness.dark,
        primary: const Color(0xFFB8F36D),
        surface: const Color(0xFF171C19),
      ),
      scaffoldBackgroundColor: const Color(0xFF101511),
      dividerColor: const Color(0xFF30372F),
      fontFamily: 'sans-serif',
      textTheme: const TextTheme(
        bodySmall: TextStyle(color: Color(0xFF9BA897)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF222922),
        border: OutlineInputBorder(borderSide: BorderSide.none),
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 400),
      ),
    ),
    home: const ScreenHome(),
  );
}
