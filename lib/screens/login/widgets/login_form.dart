part of '../login_screen.dart';

/// Formulaire de connexion/inscription
/// Ce widget gère à la fois la connexion et la création de compte
class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  // Clé globale pour valider le formulaire
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour gérer le contenu des champs de texte
  // Les valeurs par défaut proviennent des variables d'environnement (pratique en développement)
  final _emailController = TextEditingController(text: const String.fromEnvironment('DEFAULT_USER_EMAIL'));
  final _passwordController = TextEditingController(text: const String.fromEnvironment('DEFAULT_USER_PASSWORD'));
  final _displayNameController = TextEditingController();

  // État local du widget
  bool _isLoading = false; // Indique si une requête est en cours
  bool _isSignup = false; // true = mode inscription, false = mode connexion

  @override
  void dispose() {
    // IMPORTANT : toujours libérer les ressources des contrôleurs pour éviter les fuites mémoire
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  /// Méthode appelée lors de la soumission du formulaire
  Future<void> _submit() async {
    // Validation du formulaire (vérifie tous les validators des TextFormField)
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final displayName = _displayNameController.text.trim();

      // En mode inscription, créer d'abord le compte
      if (_isSignup) {
        await apiService.register(email, password, displayName: displayName.isEmpty ? null : displayName);
      }

      // Ensuite se connecter (dans tous les cas)
      await apiService.login(email, password);

      // Vérifier que le widget est toujours monté avant de naviguer
      if (!mounted) return;

      // Redirection vers l'écran d'accueil (remplace l'écran de login dans la pile)
      unawaited(Navigator.of(context).pushReplacementNamed(HomePageRoute.routeName));
    } catch (e) {
      // Toujours vérifier mounted avant d'utiliser le contexte après un await
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Affichage d'un message d'erreur en bas de l'écran
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Theme.of(context).colorScheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pendant le chargement, afficher un indicateur de progression
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Icon(Icons.lock_outline, size: 100, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 32),

            // Champ "Nom affiché" visible uniquement en mode inscription
            if (_isSignup)
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom affiché',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                // Le validator retourne null si valide, sinon un message d'erreur
                validator: (value) {
                  if (!_isSignup) return null;
                  if (value == null || value.trim().isEmpty) {
                    return 'Indiquez un nom à afficher';
                  }
                  return null;
                },
              ),
            if (_isSignup) const SizedBox(height: 16),

            // Champ email avec validation basique
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre email';
                }
                if (!value.contains('@')) {
                  return 'Email invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Champ mot de passe avec texte masqué
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true, // Masque le texte saisi
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre mot de passe';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Bouton de soumission (texte change selon le mode)
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(_isSignup ? 'Créer mon compte' : 'Se connecter', style: const TextStyle(fontSize: 16)),
            ),

            // Bouton pour basculer entre connexion et inscription
            TextButton(
              onPressed: () => setState(() {
                _isSignup = !_isSignup;
              }),
              child: Text(_isSignup ? 'Déjà un compte ? Se connecter' : 'Créer un compte'),
            ),
          ],
        ),
      ),
    );
  }
}
