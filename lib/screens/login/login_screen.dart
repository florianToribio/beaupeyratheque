import 'dart:async';

import 'package:beaupeyratheque_mobile/main.dart' show apiService;
import 'package:beaupeyratheque_mobile/screens/home/home_screen.dart';
import 'package:beaupeyratheque_mobile/services/api_service.dart';
import 'package:flutter/material.dart';

part 'widgets/login_form.dart';

class LoginPageRoute extends MaterialPageRoute<void> {
  LoginPageRoute() : super(builder: (context) => const LoginScreen());

  static const routeName = '/login';
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: const _LoginForm(),
    );
  }
}
