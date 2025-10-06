part of '../home_screen.dart';

/// Dialogue de confirmation de suppression réutilisable
/// Affiche un message personnalisé et retourne true si l'utilisateur confirme
class ConfirmDeleteDialog extends StatelessWidget {
  const ConfirmDeleteDialog({required this.title, required this.message, super.key});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        // Bouton Annuler : ferme le dialogue et retourne false
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
        // Bouton Supprimer : ferme le dialogue et retourne true
        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Supprimer')),
      ],
    );
  }
}
