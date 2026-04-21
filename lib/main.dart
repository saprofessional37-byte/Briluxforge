// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/app.dart';
import 'package:briluxforge/firebase_options.dart';
import 'package:briluxforge/services/local_logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the file-based logger before anything else so that all
  // subsequent AppLogger calls (including Firebase init errors) are persisted.
  await LocalLoggerService.initialize();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
