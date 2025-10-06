import 'package:intl/intl.dart';

/// Extension pour ajouter des méthodes utilitaires à la classe DateTime
/// Les extensions permettent d'ajouter des fonctionnalités à des classes existantes
extension DateTimeExtensions on DateTime {
  /// Convertit une date au format français dd/MM/yyyy
  /// Exemple : DateTime(2024, 3, 15) -> "15/03/2024"
  String toFormattedString() {
    return DateFormat('dd/MM/yyyy').format(this);
  }
}
