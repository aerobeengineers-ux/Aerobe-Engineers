import 'package:flutter/material.dart';

const Color navy = Color(0xFF0D1B2A);
const Color accent = Color(0xFF0099CC);

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: accent),
  appBarTheme: const AppBarTheme(backgroundColor: navy, foregroundColor: Colors.white),
  inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
);
