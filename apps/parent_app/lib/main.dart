import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'app/parent_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialize
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ==========================================
  // LOCAL FIREBASE EMULATORS
  // ==========================================

  // Authentication Emulator
  await FirebaseAuth.instance.useAuthEmulator(
    '127.0.0.1',
    9099,
  );

  // Firestore Emulator
  FirebaseFirestore.instance.useFirestoreEmulator(
    '127.0.0.1',
    8080,
  );

  // Cloud Functions Emulator
  FirebaseFunctions.instance.useFunctionsEmulator(
    '127.0.0.1',
    5001,
  );

  runApp(
    const ProviderScope(
      child: ParentApp(),
    ),
  );
}