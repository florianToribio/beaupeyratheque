part of '../home_screen.dart';

/// Onglet affichant la liste des livres
/// Gère également la liste des utilisateurs pour les emprunts
class BooksTab extends StatefulWidget {
  const BooksTab({super.key});

  @override
  State<BooksTab> createState() => BooksTabState();
}

class BooksTabState extends State<BooksTab> {
  List<Book> _books = const [];
  List<User> _users = const []; // Nécessaire pour afficher la liste des emprunteurs possibles
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Charge à la fois les livres et les utilisateurs
  /// Les utilisateurs sont nécessaires pour la fonctionnalité d'emprunt
  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Lancer les deux requêtes en parallèle
      final books = await apiService.getBooks();
      final users = await apiService.getUsers();
      if (!mounted) return;
      setState(() {
        _books = books;
        _users = users;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $error')));
    }
  }

  /// Ouvre le formulaire de création/édition de livre
  Future<void> openBookForm({Book? book}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _BookFormDialog(book: book, users: _users),
    );
    if (result ?? false) {
      await _loadData();
    }
  }

  /// Supprime un livre après confirmation
  Future<void> _deleteBook(Book book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          ConfirmDeleteDialog(title: 'Supprimer le livre', message: 'Voulez-vous supprimer "${book.title}" ?'),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await apiService.deleteBook(book.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $error')));
    } finally {
      await _loadData();
    }
  }

  /// Emprunte un livre en affichant une liste d'utilisateurs
  /// Utilise un ModalBottomSheet pour la sélection de l'utilisateur
  Future<void> _borrowBook(Book book) async {
    final selectedUserId = await showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        if (_users.isEmpty) {
          return const Padding(padding: EdgeInsets.all(16), child: Text('Aucun utilisateur disponible'));
        }
        // Liste des utilisateurs affichée depuis le bas de l'écran
        return ListView(
          children: _users
              .map(
                (user) => ListTile(
                  title: Text(user.label),
                  subtitle: Text(user.email),
                  // Ferme le bottom sheet et retourne l'ID de l'utilisateur sélectionné
                  onTap: () => Navigator.of(context).pop(user.id),
                ),
              )
              .toList(),
        );
      },
    );
    if (selectedUserId == null) return; // L'utilisateur a annulé

    try {
      await apiService.borrowBook(book.id, selectedUserId);
      if (!mounted) return;
      await _loadData();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $error')));
    }
  }

  /// Marque un livre comme rendu
  Future<void> _returnBook(Book book) async {
    try {
      await apiService.returnBook(book.id);
      if (!mounted) return;
      await _loadData();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_books.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: const Center(child: Text('Aucun livre pour le moment')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _books.length,
        itemBuilder: (context, index) => _BookTile(
          book: _books[index],
          usersAvailable: _users.isNotEmpty,
          onTap: _showBookDetails,
          onBorrow: _borrowBook,
          onReturn: _returnBook,
          onEdit: openBookForm,
          onDelete: _deleteBook,
        ),
      ),
    );
  }

  void _showBookDetails(Book book) {
    showDialog<void>(
      context: context,
      builder: (context) => _BookDetailsDialog(book: book),
    );
  }
}

/// Widget représentant une ligne de livre dans la liste
/// Affiche les informations du livre et les actions possibles (emprunter, modifier, supprimer)
class _BookTile extends StatelessWidget {
  const _BookTile({
    required this.book,
    required this.usersAvailable,
    required this.onTap,
    required this.onBorrow,
    required this.onReturn,
    required this.onEdit,
    required this.onDelete,
  });

  final Book book;
  final bool usersAvailable; // Indique si des utilisateurs existent pour emprunter
  final void Function(Book) onTap;
  final void Function(Book) onBorrow;
  final void Function(Book) onReturn;
  final void Function({Book? book}) onEdit;
  final void Function(Book) onDelete;

  @override
  Widget build(BuildContext context) {
    // Construction du sous-titre avec auteur, année et statut d'emprunt
    final subtitle = [
      '${book.author?.fullName ?? 'Auteur inconnu'} • ${book.publicationYear}',
      if (book.isBorrowed) 'Emprunté par ${book.borrowerName ?? 'Utilisateur ${book.borrowerId}'}',
    ].join('\n');

    return ListTile(
      title: Text(book.title),
      subtitle: Text(subtitle),
      onTap: () => onTap(book),
      trailing: Wrap(
        spacing: 4,
        children: [
          // Bouton emprunter/retourner (change selon l'état du livre)
          IconButton(
            icon: Icon(book.isBorrowed ? Icons.unpublished : Icons.shopping_bag_outlined),
            tooltip: book.isBorrowed ? 'Marquer comme rendu' : 'Emprunter',
            // Le bouton est désactivé si aucun utilisateur n'existe (en mode emprunt)
            onPressed: book.isBorrowed
                ? () => onReturn(book)
                : usersAvailable
                    ? () => onBorrow(book)
                    : null,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier',
            onPressed: () => onEdit(book: book),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer',
            onPressed: () => onDelete(book),
          ),
        ],
      ),
    );
  }
}
