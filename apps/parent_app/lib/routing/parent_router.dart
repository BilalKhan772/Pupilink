import 'package:flutter/material.dart';

import '../features/splash/ui/splash_screen.dart';
import '../features/auth/ui/screens/parent_login_screen.dart';
import '../features/auth/ui/screens/parent_signup_screen.dart';
import '../features/home/ui/parent_home_shell.dart';

class ParentRouter {
  static const String splash = '/';

  static const String login = '/login';

  static const String signup = '/signup';

  static const String dashboard = '/dashboard';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),

    login: (context) => const ParentLoginScreen(),

    signup: (context) => const ParentSignupScreen(),

    dashboard: (context) => const ParentHomeShell(),
  };
}