import 'dart:io';

import 'package:beaupeyratheque_server/src/api.dart';
import 'package:beaupeyratheque_server/src/database.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

Future<void> main(List<String> args) async {
  final db = DatabaseManager();
  await db.init();

  final api = ApiHandlers(db);
  final handler = const Pipeline().addMiddleware(logRequests()).addHandler(api.router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('Beaupeyratheque server listening on port ${server.port}');
  await printLocalIpAddress();
}

Future<void> printLocalIpAddress() async {
  try {
    // Obtenir toutes les interfaces réseau disponibles
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);

    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        // Ignore les adresses de loopback (127.0.0.1)
        if (!addr.isLoopback) {
          stdout
            ..writeln('Nom interface: ${interface.name}')
            ..writeln('Adresse locale: ${addr.address}');
        }
      }
    }
  } catch (e) {
    stdout.writeln('Erreur en récupérant l’adresse IP : $e');
  }
}
