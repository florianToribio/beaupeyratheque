part of '../home_screen.dart';

/// Dialogue affichant les détails complets d'un livre
/// Affiche l'auteur, année de publication, description et statut d'emprunt
class _BookDetailsDialog extends StatelessWidget {
  const _BookDetailsDialog({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(book.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Utilisation de l'opérateur ?? pour fournir une valeur par défaut si l'auteur est null
          Text('Auteur : ${book.author?.fullName ?? 'Auteur inconnu'}'),
          const SizedBox(height: 8),
          Text('Année : ${book.publicationYear}'),
          // Affichage conditionnel de la description
          if (book.description != null && book.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(book.description!),
          ],
          const SizedBox(height: 8),
          // Affichage du statut d'emprunt
          Text(
            book.isBorrowed ? 'Emprunté par ${book.borrowerName ?? 'Utilisateur ${book.borrowerId}'}' : 'Disponible',
          ),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer'))],
    );
  }
}
