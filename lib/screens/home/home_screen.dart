import 'package:beaupeyratheque_mobile/extensions/date_time_extensions.dart';
import 'package:beaupeyratheque_mobile/main.dart' show apiService;
import 'package:beaupeyratheque_mobile/mixins/auth_redirect_mixin.dart';
import 'package:beaupeyratheque_mobile/models/author.dart';
import 'package:beaupeyratheque_mobile/models/book.dart';
import 'package:beaupeyratheque_mobile/models/user.dart';
import 'package:beaupeyratheque_mobile/services/api_service.dart';
import 'package:flutter/material.dart';

// Inclusion des fichiers de dialogue et widgets comme parties du fichier principal
part 'dialogs/author_details_dialog.dart';
part 'dialogs/author_form_dialog.dart';
part 'dialogs/book_details_dialog.dart';
part 'dialogs/book_form_dialog.dart';
part 'dialogs/confirm_delete_dialog.dart';
part 'widgets/authors_tab.dart';
part 'widgets/books_tab.dart';
part 'widgets/users_tab.dart';

/// Route pour naviguer vers l'écran d'accueil
/// Exemple d'utilisation : Navigator.of(context).pushNamed(HomePageRoute.routeName)
class HomePageRoute extends MaterialPageRoute<void> {
  HomePageRoute() : super(builder: (context) => const HomeScreen());

  static const routeName = '/home';
}

/// Écran principal de l'application affichant les auteurs, livres et utilisateurs
/// Cet écran utilise un système d'onglets avec une barre de navigation inférieure
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AuthRedirectMixin {
  // GlobalKeys permettent d'accéder à l'état des widgets enfants depuis le parent
  // Utilisées ici pour déclencher l'ouverture des formulaires depuis les boutons FAB
  final _authorsKey = GlobalKey<AuthorsTabState>();
  final _booksKey = GlobalKey<BooksTabState>();
  final _usersKey = GlobalKey<UsersTabState>();

  // Index de l'onglet actuellement affiché (0 = Auteurs, 1 = Livres, 2 = Utilisateurs)
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final titles = ['Auteurs', 'Livres', 'Utilisateurs'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          // Bouton de déconnexion qui supprime le token d'authentification
          TextButton.icon(
            onPressed: () async => apiService.clearToken(),
            icon: const Icon(Icons.logout),
            label: const Text('Déconnexion'),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onPrimary),
          ),
        ],
      ),
      // IndexedStack permet de garder l'état de chaque onglet même quand on change d'onglet
      // Contrairement à un simple switch, les widgets ne sont pas détruits/recréés
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AuthorsTab(key: _authorsKey),
          BooksTab(key: _booksKey),
          UsersTab(key: _usersKey),
        ],
      ),
      // Barre de navigation inférieure avec 3 onglets
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Auteurs'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Livres'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Utilisateurs'),
        ],
      ),
      // Bouton flottant qui change selon l'onglet actif
      floatingActionButton: _HomeFab(currentIndex: _currentIndex, authorsKey: _authorsKey, booksKey: _booksKey),
    );
  }
}

/// Widget représentant le bouton d'action flottant (FAB) qui change selon l'onglet
/// Affiche un bouton "+" pour ajouter un auteur ou un livre, ou rien pour l'onglet Utilisateurs
class _HomeFab extends StatelessWidget {
  const _HomeFab({required this.currentIndex, required this.authorsKey, required this.booksKey});

  final int currentIndex;
  final GlobalKey<AuthorsTabState> authorsKey;
  final GlobalKey<BooksTabState> booksKey;

  @override
  Widget build(BuildContext context) {
    // Onglet Auteurs (index 0) : bouton pour ajouter un auteur
    if (currentIndex == 0) {
      return FloatingActionButton(
        // Utilisation de currentState pour accéder à l'état du widget AuthorsTab
        onPressed: () => authorsKey.currentState?.openAuthorForm(),
        tooltip: 'Nouvel auteur',
        child: const Icon(Icons.add),
      );
    }
    // Onglet Livres (index 1) : bouton pour ajouter un livre
    if (currentIndex == 1) {
      return FloatingActionButton(
        onPressed: () => booksKey.currentState?.openBookForm(),
        tooltip: 'Nouveau livre',
        child: const Icon(Icons.add),
      );
    }
    // Onglet Utilisateurs (index 2) : pas de bouton (les utilisateurs s'enregistrent eux-mêmes)
    return const SizedBox.shrink();
  }
}
