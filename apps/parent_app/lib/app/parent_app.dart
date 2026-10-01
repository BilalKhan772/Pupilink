import 'package:flutter/material.dart';

import '../routing/parent_router.dart';

class ParentApp extends StatelessWidget {
  const ParentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'School Progress',

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),

      initialRoute: ParentRouter.splash,

      routes: ParentRouter.routes,
    );
  }
}