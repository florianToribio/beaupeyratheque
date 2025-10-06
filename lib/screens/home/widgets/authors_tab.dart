part of '../home_screen.dart';

/// Onglet affichant la liste des auteurs
/// Ce widget est un StatefulWidget pour gérer l'état de la liste
class AuthorsTab extends StatefulWidget {
  const AuthorsTab({super.key});

  @override
  State<AuthorsTab> createState() => AuthorsTabState();
}

class AuthorsTabState extends State<AuthorsTab> {
  List<Author> _authors = const []; // Liste des auteurs (vide par défaut)
  bool _loading = true; // Indicateur de chargement

  @override
  void initState() {
    super.initState();
    // Charger les données dès que le widget est initialisé
    _loadAuthors();
  }

  /// Charge la liste des auteurs depuis l'API
  Future<void> _loadAuthors() async {
    setState(() => _loading = true);
    try {
      final authors = await apiService.getAuthors();
      if (!mounted) return;
      setState(() {
        _authors = authors;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      // Affichage d'un message d'erreur via SnackBar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $error')));
    }
  }

  /// Ouvre le formulaire de création/édition d'auteur
  /// Si [author] est fourni, le formulaire est en mode édition
  Future<void> openAuthorForm({Author? author}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _AuthorFormDialog(author: author),
    );
    // Si le formulaire retourne true (succès), recharger la liste
    if (result ?? false) {
      await _loadAuthors();
    }
  }

  /// Supprime un auteur après confirmation
  Future<void> _deleteAuthor(Author author) async {
    // Afficher un dialogue de confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          ConfirmDeleteDialog(title: "Supprimer l'auteur", message: 'Voulez-vous supprimer ${author.fullName} ?'),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await apiService.deleteAuthor(author.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $error')));
    } finally {
      // Toujours recharger la liste (que la suppression ait réussi ou non)
      await _loadAuthors();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher un indicateur de chargement pendant la récupération des données
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Si la liste est vide, afficher un message
    if (_authors.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAuthors,
        child: ListView(
          // AlwaysScrollableScrollPhysics permet de scroller même si le contenu est court
          // Nécessaire pour que RefreshIndicator fonctionne
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: const Center(child: Text('Aucun auteur pour le moment')),
            ),
          ],
        ),
      );
    }

    // Liste scrollable des auteurs avec pull-to-refresh
    return RefreshIndicator(
      onRefresh: _loadAuthors,
      child: ListView.builder(
        itemCount: _authors.length,
        itemBuilder: (context, index) =>
            _AuthorTile(author: _authors[index], onTap: _showDetails, onEdit: openAuthorForm, onDelete: _deleteAuthor),
      ),
    );
  }

  /// Affiche les détails d'un auteur dans un dialogue
  void _showDetails(Author author) {
    showDialog<void>(
      context: context,
      builder: (context) => _AuthorDetailsDialog(author: author),
    );
  }
}

/// Widget représentant une ligne d'auteur dans la liste
/// StatelessWidget car il ne gère pas d'état propre, il reçoit tout via ses paramètres
class _AuthorTile extends StatelessWidget {
  const _AuthorTile({required this.author, required this.onTap, required this.onEdit, required this.onDelete});

  final Author author;
  final void Function(Author) onTap; // Callback pour afficher les détails
  final void Function({Author? author}) onEdit; // Callback pour éditer
  final void Function(Author) onDelete; // Callback pour supprimer

  @override
  Widget build(BuildContext context) {
    // Construction du sous-titre avec les informations disponibles
    final details = <String>[
      if (author.nationality != null && author.nationality!.isNotEmpty) 'Nationalité : ${author.nationality}',
      if (author.birthDate != null) 'Né(e) le ${author.birthDate!.toFormattedString()}',
    ].join('\n');

    return ListTile(
      title: Text(author.fullName),
      subtitle: details.isEmpty ? null : Text(details),
      onTap: () => onTap(author),
      // Wrap permet d'aligner plusieurs widgets horizontalement
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier',
            onPressed: () => onEdit(author: author),
          ),
          IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Supprimer', onPressed: () => onDelete(author)),
        ],
      ),
    );
  }
}
