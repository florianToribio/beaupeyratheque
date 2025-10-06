import 'package:beaupeyratheque_mobile/main.dart' show apiService;
import 'package:beaupeyratheque_mobile/screens/login/login_screen.dart';
import 'package:flutter/material.dart';

/// Mixin pour gérer la redirection automatique vers l'écran de login
/// Un mixin permet de réutiliser du code dans plusieurs classes sans héritage
mixin AuthRedirectMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    // Démarrer l'écoute du stream d'authentification dès l'initialisation
    _listenToAuthState();
  }

  /// Écoute le stream d'état d'authentification
  /// Redirige vers le login si l'utilisateur se déconnecte
  void _listenToAuthState() {
    // authStateStream émet true/false selon l'état de connexion
    apiService.authStateStream.listen((isAuthenticated) {
      if (!mounted) return; // Toujours vérifier mounted avant d'utiliser le context
      if (!isAuthenticated) {
        // Rediriger vers login si déconnecté (remplace l'écran actuel)
        Navigator.of(context).pushReplacementNamed(LoginPageRoute.routeName);
      }
    });
  }
}
