import 'package:flutter/material.dart';
import 'screens/document_verification_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
//hey
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      theme: AppTheme.darkTheme,
      home: const DocumentVerificationScreen(),
    );
  }
}

