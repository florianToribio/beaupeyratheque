part of '../home_screen.dart';

/// Dialogue affichant les détails complets d'un auteur
/// Affiche la nationalité, date de naissance et biographie
class _AuthorDetailsDialog extends StatelessWidget {
  const _AuthorDetailsDialog({required this.author});

  final Author author;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(author.fullName),
      content: Column(
        mainAxisSize: MainAxisSize.min, // S'adapte à la hauteur du contenu
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Affichage conditionnel des informations si elles existent
          if (author.email != null && author.email!.isNotEmpty) Text('Email : ${author.email}'),
          if (author.nationality != null) Text('Nationalité : ${author.nationality}'),
          if (author.birthDate != null) Text('Naissance : ${author.birthDate!.toFormattedString()}'),
          if (author.biography != null && author.biography!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(author.biography!),
          ],
        ],
      ),
      actions: [TextButton(onPressed: Navigator.of(context).pop, child: const Text('Fermer'))],
    );
  }
}
