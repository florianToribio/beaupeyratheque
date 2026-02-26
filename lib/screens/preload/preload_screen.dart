import 'dart:async';

import 'package:beaupeyratheque_mobile/main.dart' show apiService;
import 'package:beaupeyratheque_mobile/screens/home/home_screen.dart';
import 'package:beaupeyratheque_mobile/screens/login/login_screen.dart';
import 'package:flutter/material.dart';

class PreloadPageRoute extends MaterialPageRoute<void> {
  PreloadPageRoute() : super(builder: (context) => const PreloadScreen());

  static const routeName = '/preload';
}

class PreloadScreen extends StatefulWidget {
  const PreloadScreen({super.key});

  @override
  State<PreloadScreen> createState() => _PreloadScreenState();
}

class _PreloadScreenState extends State<PreloadScreen> {
  @override
  void initState() {
    super.initState();
    if (const bool.fromEnvironment('FLUTTER_TEST')) return;
    _checkToken();
  }

  Future<void> _checkToken() async {
    // Vérifier si un token existe
    final hasToken = await apiService.hasToken();

    if (!mounted) return;

    // Rediriger vers home si token existe, sinon vers login
    if (hasToken) {
      unawaited(Navigator.of(context).pushReplacement(HomePageRoute()));
    } else {
      unawaited(Navigator.of(context).pushReplacement(LoginPageRoute()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
