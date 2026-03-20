import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/firebase_bootstrap.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await FirebaseBootstrap.initialize();
  runApp(JobFlowApp(firebaseReady: firebaseReady));
}

class JobFlowApp extends StatelessWidget {
  const JobFlowApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JobFlow Mobile',
      theme: AppTheme.lightTheme,
      home: LoginScreen(firebaseReady: firebaseReady),
      routes: {
        LoginScreen.routeName: (context) => LoginScreen(firebaseReady: firebaseReady),
        HomeShell.routeName: (context) => const HomeShell(),
      },
    );
  }
}
