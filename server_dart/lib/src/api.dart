import 'dart:convert';
import 'dart:io';

import 'package:beaupeyratheque_server/src/database.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// Gestionnaire des routes et endpoints de l'API REST
/// Utilise Shelf (framework HTTP Dart) et Router pour le routage
class ApiHandlers {
  /// Constructeur qui initialise toutes les routes de l'API
  /// Chaque route est associée à un handler (méthode privée)
  ApiHandlers(this._database) {
    final router = Router()
      // Authentication
      ..post('/api/token', _login)

      // Users endpoints
      ..get('/api/users', _listUsers)
      ..post('/api/users', _createUser)

      // Authors endpoints (CRUD complet)
      ..get('/api/authors', _listAuthors)
      ..post('/api/authors', _createAuthor)
      ..get('/api/authors/<id|[0-9]+>', _getAuthor) // <id|[0-9]+> = paramètre avec regex
      ..put('/api/authors/<id|[0-9]+>', _updateAuthor)
      ..delete('/api/authors/<id|[0-9]+>', _deleteAuthor)
      ..get('/api/authors/<id|[0-9]+>/books', _booksByAuthor)

      // Books endpoints (CRUD + actions spécifiques)
      ..get('/api/books', _listBooks)
      ..post('/api/books', _createBook)
      ..get('/api/books/<id|[0-9]+>', _getBook)
      ..put('/api/books/<id|[0-9]+>', _updateBook)
      ..delete('/api/books/<id|[0-9]+>', _deleteBook)
      ..post('/api/books/<id|[0-9]+>/borrow', _borrowBook) // Action personnalisée
      ..post('/api/books/<id|[0-9]+>/return', _returnBook) // Action personnalisée

      // Health check endpoint
      ..get('/health', (request) => _jsonResponse({'status': 'ok'}));

    _router = router;
  }

  final DatabaseManager _database; // Accès à la base de données
  late final Router _router; // Router Shelf initialisé dans le constructeur

  Router get router => _router;

  static const _jsonHeaders = {'Content-Type': 'application/json; charset=utf-8'};
  static const _jwtSecret = 'local-dev-secret'; // Secret pour signer les JWT - mettre en secret en prod ;)

  Future<Response> _listUsers(Request request) async {
    final users = _database.listUsers();
    return _jsonResponse(users);
  }

  Future<Response> _createUser(Request request) async {
    final payload = await _readJson(request);
    final email = (payload['email'] as String?)?.trim();
    final password = payload['password'] as String?;
    final displayName = (payload['displayName'] as String?)?.trim();

    if (email == null || email.isEmpty || password == null || password.isEmpty) {
      return _jsonResponse({'message': 'email et password sont obligatoires'}, statusCode: 400);
    }

    if (_database.emailExists(email)) {
      return _jsonResponse({'message': 'email déjà utilisé'}, statusCode: 409);
    }

    try {
      final id = _database.insertUser(email: email, password: password, displayName: displayName);
      final user = _database.getUser(id);
      return _jsonResponse(user!, statusCode: 201);
    } catch (e) {
      return _jsonResponse({'message': "Impossible de créer l'utilisateur"}, statusCode: 500);
    }
  }

  /// Endpoint de connexion (POST /api/token)
  /// Vérifie les credentials et retourne un JWT dans un cookie HTTP
  Future<Response> _login(Request request) async {
    final payload = await _readJson(request);
    final email = payload['email'] as String?;
    final password = payload['password'] as String?;
    if (email == null || password == null) {
      return _jsonResponse({'message': 'Email et mot de passe requis'}, statusCode: 400);
    }

    // Vérifier les identifiants
    final user = _database.findUserByEmail(email);
    if (user == null || user['password'] != password) {
      return _jsonResponse({'message': 'Identifiants invalides'}, statusCode: 401);
    }

    // Créer un JWT (JSON Web Token) avec les informations utilisateur
    final jwt = JWT({'sub': user['id'], 'email': user['email'], 'name': user['display_name']});
    final token = jwt.sign(SecretKey(_jwtSecret), expiresIn: const Duration(hours: 12));

    // Créer un cookie HTTP pour stocker le JWT
    final host = request.requestedUri.host;
    final cookie = Cookie('app-local-session', token)
      ..path = '/' // Cookie valide sur tout le domaine
      ..httpOnly = true // Non accessible en JavaScript (sécurité XSS)
      ..expires = DateTime.now().toUtc().add(const Duration(hours: 12)); // Validité 12h
    if (host.isNotEmpty && host != 'localhost') {
      cookie.domain = host;
    }

    // Retourner 204 No Content avec le cookie dans les headers
    return Response(204, headers: {HttpHeaders.setCookieHeader: cookie.toString()});
  }

  Future<Response> _listAuthors(Request request) async {
    final authors = _database.listAuthors();
    return _jsonResponse(authors);
  }

  Future<Response> _getAuthor(Request request, String idParam) async {
    final author = _database.getAuthor(int.parse(idParam));
    return author == null ? _jsonResponse({'message': 'Auteur introuvable'}, statusCode: 404) : _jsonResponse(author);
  }

  Future<Response> _createAuthor(Request request) async {
    final payload = await _readJson(request);
    if (!_require(payload, ['firstName', 'lastName'])) {
      return _jsonResponse({'message': 'firstName et lastName sont obligatoires'}, statusCode: 400);
    }

    final data = {
      'firstName': payload['firstName'] as String,
      'lastName': payload['lastName'] as String,
      'birthDate': payload['birthDate'] as String?,
      'nationality': payload['nationality'] as String?,
      'biography': payload['biography'] as String?,
    };
    final id = _database.insertAuthor(data);
    return _jsonResponse(_database.getAuthor(id)!, statusCode: 201);
  }

  Future<Response> _updateAuthor(Request request, String idParam) async {
    final id = int.parse(idParam);
    if (_database.getAuthor(id) == null) {
      return _jsonResponse({'message': 'Auteur introuvable'}, statusCode: 404);
    }

    final payload = await _readJson(request);
    if (!_require(payload, ['firstName', 'lastName'])) {
      return _jsonResponse({'message': 'firstName et lastName sont obligatoires'}, statusCode: 400);
    }

    final data = {
      'firstName': payload['firstName'] as String,
      'lastName': payload['lastName'] as String,
      'birthDate': payload['birthDate'] as String?,
      'nationality': payload['nationality'] as String?,
      'biography': payload['biography'] as String?,
    };
    _database.updateAuthor(id, data);
    return _jsonResponse(_database.getAuthor(id)!);
  }

  Future<Response> _deleteAuthor(Request request, String idParam) async {
    final deleted = _database.deleteAuthor(int.parse(idParam));
    return deleted ? Response(204) : _jsonResponse({'message': 'Auteur introuvable'}, statusCode: 404);
  }

  Future<Response> _booksByAuthor(Request request, String idParam) async {
    final id = int.parse(idParam);
    if (!_database.authorExists(id)) {
      return _jsonResponse({'message': 'Auteur introuvable'}, statusCode: 404);
    }
    final books = _database.listBooksByAuthor(id);
    return _jsonResponse(books);
  }

  Future<Response> _listBooks(Request request) async {
    final books = _database.listBooks();
    return _jsonResponse(books);
  }

  Future<Response> _getBook(Request request, String idParam) async {
    final book = _database.getBook(int.parse(idParam));
    return book == null ? _jsonResponse({'message': 'Livre introuvable'}, statusCode: 404) : _jsonResponse(book);
  }

  Future<Response> _createBook(Request request) async {
    final payload = await _readJson(request);
    if (!_require(payload, ['title', 'publicationYear'])) {
      return _jsonResponse({'message': 'title et publicationYear sont obligatoires'}, statusCode: 400);
    }

    final authorId = _extractId(payload['author'] as String?, '/api/authors/');
    if (authorId != null && !_database.authorExists(authorId)) {
      return _jsonResponse({'message': 'Auteur associé introuvable'}, statusCode: 400);
    }

    final data = {
      'title': payload['title'] as String,
      'description': payload['description'] as String?,
      'publicationYear': int.tryParse('${payload['publicationYear']}') ?? DateTime.now().year,
      'authorId': authorId,
      'image': payload['image'] as String?,
      'borrowed': payload['borrowed'] == true,
      'borrowerId': _extractId(payload['borrower'] as String?, '/api/users/'),
    };
    final borrowerId = data['borrowerId'] as int?;
    if (data['borrowed'] == true) {
      if (borrowerId == null || !_database.userExists(borrowerId)) {
        return _jsonResponse({'message': 'Emprunteur invalide'}, statusCode: 400);
      }
    } else {
      data['borrowerId'] = null;
    }
    final id = _database.insertBook(data);
    return _jsonResponse(_database.getBook(id)!, statusCode: 201);
  }

  Future<Response> _updateBook(Request request, String idParam) async {
    final id = int.parse(idParam);
    if (_database.getBook(id) == null) {
      return _jsonResponse({'message': 'Livre introuvable'}, statusCode: 404);
    }

    final payload = await _readJson(request);
    if (!_require(payload, ['title', 'publicationYear'])) {
      return _jsonResponse({'message': 'title et publicationYear sont obligatoires'}, statusCode: 400);
    }

    final authorId = _extractId(payload['author'] as String?, '/api/authors/');
    if (authorId != null && !_database.authorExists(authorId)) {
      return _jsonResponse({'message': 'Auteur associé introuvable'}, statusCode: 400);
    }

    final data = {
      'title': payload['title'] as String,
      'description': payload['description'] as String?,
      'publicationYear': int.tryParse('${payload['publicationYear']}') ?? DateTime.now().year,
      'authorId': authorId,
      'image': payload['image'] as String?,
      'borrowed': payload['borrowed'] == true,
      'borrowerId': _extractId(payload['borrower'] as String?, '/api/users/'),
    };
    final borrowerId = data['borrowerId'] as int?;
    if (data['borrowed'] == true) {
      if (borrowerId == null || !_database.userExists(borrowerId)) {
        return _jsonResponse({'message': 'Emprunteur invalide'}, statusCode: 400);
      }
    } else {
      data['borrowerId'] = null;
    }
    _database.updateBook(id, data);
    return _jsonResponse(_database.getBook(id)!);
  }

  Future<Response> _deleteBook(Request request, String idParam) async {
    final deleted = _database.deleteBook(int.parse(idParam));
    return deleted ? Response(204) : _jsonResponse({'message': 'Livre introuvable'}, statusCode: 404);
  }

  Future<Response> _borrowBook(Request request, String idParam) async {
    final bookId = int.parse(idParam);
    final payload = await _readJson(request);
    final userId = payload['userId'] as int? ?? _extractId(payload['user'] as String?, '/api/users/');
    if (userId == null) {
      return _jsonResponse({'message': 'userId requis'}, statusCode: 400);
    }
    final ok = _database.borrowBook(bookId, userId);
    if (!ok) {
      return _jsonResponse({'message': "Impossible d'emprunter"}, statusCode: 400);
    }
    final book = _database.getBook(bookId);
    return book == null ? _jsonResponse({'message': 'Livre introuvable'}, statusCode: 404) : _jsonResponse(book);
  }

  Future<Response> _returnBook(Request request, String idParam) async {
    final bookId = int.parse(idParam);
    final ok = _database.returnBook(bookId);
    if (!ok) {
      return _jsonResponse({'message': 'Livre introuvable'}, statusCode: 404);
    }
    final book = _database.getBook(bookId);
    return book == null ? _jsonResponse({'message': 'Livre introuvable'}, statusCode: 404) : _jsonResponse(book);
  }

  // ===== MÉTHODES UTILS =====

  /// Lit et parse le corps JSON d'une requête HTTP
  /// Retourne un Map vide si le corps est vide
  Future<Map<String, dynamic>> _readJson(Request request) async {
    final content = await request.readAsString();
    if (content.trim().isEmpty) return <String, dynamic>{};

    final decoded = jsonDecode(content);
    if (decoded is Map<String, dynamic>) return decoded;

    throw const FormatException('JSON invalide');
  }

  /// Vérifie que les clés requises existent et ne sont pas vides dans un payload
  /// Utile pour valider les données avant insertion en base
  bool _require(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) return false;
      if (value is String && value.trim().isEmpty) return false;
    }
    return true;
  }

  /// Extrait l'ID numérique d'une IRI (Internationalized Resource Identifier)
  /// Exemple : _extractId('/api/authors/42', '/api/authors/') -> 42
  /// Utilisé pour les relations entre entités (livre -> auteur)
  int? _extractId(String? iri, String prefix) {
    if (iri == null || iri.isEmpty || !iri.startsWith(prefix)) return null;
    return int.tryParse(iri.substring(prefix.length));
  }

  /// Crée une réponse HTTP avec un corps JSON
  /// Encode automatiquement l'objet en JSON et ajoute les headers appropriés
  Response _jsonResponse(Object body, {int statusCode = 200}) {
    return Response(statusCode, body: jsonEncode(body), headers: _jsonHeaders);
  }
}
