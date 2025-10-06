import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Gestionnaire de base de données SQLite
/// Gère les opérations CRUD pour users, authors et books
class DatabaseManager {
  late final Database _db; // Instance SQLite

  /// Initialise la base de données
  /// - Crée le dossier data/ si nécessaire
  /// - Ouvre ou crée le fichier beaupeyratheque.db
  /// - Exécute les migrations (création des tables)
  /// - Insère des données de test (seed)
  Future<void> init() async {
    // Déterminer le chemin du dossier data/
    final packageDir = File.fromUri(Platform.script).parent.parent;
    final dataDir = Directory(p.join(packageDir.path, 'data'));
    if (!dataDir.existsSync()) {
      dataDir.createSync(recursive: true);
    }

    // Ouvrir ou créer la base de données SQLite
    final dbFile = File(p.join(dataDir.path, 'beaupeyratheque.db'));
    _db = sqlite3.open(dbFile.path);

    _migrate(); // Créer les tables
    _seed(); // Insérer des données initiales
  }

  /// Crée les tables de la base de données si elles n'existent pas
  /// Utilise CREATE TABLE IF NOT EXISTS pour éviter les erreurs si déjà créées
  void _migrate() {
    _db
      // Table users : stocke les utilisateurs de l'application
      ..execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        display_name TEXT
      );
    ''')
      // Table authors : stocke les auteurs de livres
      ..execute('''
      CREATE TABLE IF NOT EXISTS authors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        birth_date TEXT,
        nationality TEXT,
        biography TEXT
      );
    ''')
      // Table books : stocke les livres avec relations vers authors et users
      ..execute('''
      CREATE TABLE IF NOT EXISTS books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        publication_year INTEGER NOT NULL,
        author_id INTEGER,
        borrowed INTEGER NOT NULL DEFAULT 0,
        borrower_id INTEGER,
        image TEXT,
        FOREIGN KEY(author_id) REFERENCES authors(id) ON DELETE SET NULL,
        FOREIGN KEY(borrower_id) REFERENCES users(id) ON DELETE SET NULL
      );
    ''');

    // Vérifier et ajouter les colonnes manquantes (migration incrémentale)
    _ensureBookColumns();
  }

  /// Insère des données initiales de test (seeding)
  /// N'insère que si les tables sont vides (évite les doublons)
  void _seed() {
    // Vérifier si des auteurs existent déjà
    final authorCount = _db.select('SELECT COUNT(*) AS count FROM authors').first['count'] as int;
    if (authorCount == 0) {
      // Insérer des auteurs de test avec requêtes paramétrées (? pour éviter les injections SQL)
      _db
        ..execute(
          '''
INSERT INTO authors (first_name, last_name, birth_date, nationality, biography)
           VALUES (?, ?, ?, ?, ?)''',
          ['Jules', 'Verne', '1828-02-08', 'Française', 'Pionnier du roman de science-fiction.'],
        )
        ..execute(
          '''
INSERT INTO authors (first_name, last_name, birth_date, nationality, biography)
           VALUES (?, ?, ?, ?, ?)''',
          ['George', 'Orwell', '1903-06-25', 'Britannique', 'Auteur de 1984 et La Ferme des Animaux.'],
        );
    }

    // Vérifier si des livres existent déjà
    final bookCount = _db.select('SELECT COUNT(*) AS count FROM books').first['count'] as int;
    if (bookCount == 0) {
      // Récupérer les IDs des auteurs créés précédemment
      final verneId = _db.select('SELECT id FROM authors WHERE last_name = ? LIMIT 1', ['Verne']).first['id'] as int;
      final orwellId = _db.select('SELECT id FROM authors WHERE last_name = ? LIMIT 1', ['Orwell']).first['id'] as int;

      // Insérer des livres de test avec relations vers les auteurs
      _db
        ..execute(
          '''
INSERT INTO books (title, description, publication_year, author_id, borrowed, borrower_id, image)
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
          [
            'Vingt mille lieues sous les mers',
            "Roman d'aventure sous-marine",
            1870,
            verneId, // Relation avec Jules Verne
            0, // Non emprunté (0 = false)
            null,
            null,
          ],
        )
        ..execute(
          '''
INSERT INTO books (title, description, publication_year, author_id, borrowed, borrower_id, image)
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
          [
            '1984',
            'Roman dystopique sur un régime totalitaire',
            1949,
            orwellId, // Relation avec George Orwell
            0,
            null,
            null,
          ],
        );
    }
  }

  Map<String, dynamic>? findUserByEmail(String email) {
    final results = _db.select('SELECT * FROM users WHERE email = ? LIMIT 1', [email]);
    if (results.isEmpty) return null;
    return Map.from(results.first);
  }

  List<Map<String, dynamic>> listUsers() {
    final results = _db.select('SELECT id, email, display_name FROM users ORDER BY email ASC');
    return results.map(_rowToUser).toList();
  }

  Map<String, dynamic>? getUser(int id) {
    final results = _db.select('SELECT id, email, display_name FROM users WHERE id = ? LIMIT 1', [id]);
    if (results.isEmpty) return null;
    return _rowToUser(results.first);
  }

  bool emailExists(String email) {
    final results = _db.select('SELECT 1 FROM users WHERE email = ? LIMIT 1', [email]);
    return results.isNotEmpty;
  }

  int insertUser({required String email, required String password, String? displayName}) {
    _db.execute(
      'INSERT INTO users (email, password, display_name) VALUES (?, ?, ?)',
      [email, password, displayName],
    );
    return _lastInsertedId;
  }

  List<Map<String, dynamic>> listAuthors() {
    final results = _db.select(
      'SELECT id, first_name, last_name, birth_date, nationality, biography FROM authors ORDER BY last_name ASC',
    );
    return results.map(_rowToAuthor).toList();
  }

  Map<String, dynamic>? getAuthor(int id) {
    final results = _db.select(
      'SELECT id, first_name, last_name, birth_date, nationality, biography FROM authors WHERE id = ?',
      [id],
    );
    if (results.isEmpty) return null;
    return _rowToAuthor(results.first);
  }

  int insertAuthor(Map<String, dynamic> data) {
    _db.execute(
      '''
INSERT INTO authors (first_name, last_name, birth_date, nationality, biography)
         VALUES (?, ?, ?, ?, ?)''',
      [
        data['firstName'],
        data['lastName'],
        data['birthDate'],
        data['nationality'],
        data['biography'],
      ],
    );
    return _lastInsertedId;
  }

  bool updateAuthor(int id, Map<String, dynamic> data) {
    _db.execute(
      '''
UPDATE authors
            SET first_name = ?,
                last_name = ?,
                birth_date = ?,
                nationality = ?,
                biography = ?
          WHERE id = ?''',
      [
        data['firstName'],
        data['lastName'],
        data['birthDate'],
        data['nationality'],
        data['biography'],
        id,
      ],
    );
    return true;
  }

  bool deleteAuthor(int id) {
    if (!authorExists(id)) {
      return false;
    }
    _db.execute('DELETE FROM authors WHERE id = ?', [id]);
    return true;
  }

  List<Map<String, dynamic>> listBooks() {
    final results = _db.select('''
      SELECT
        b.id,
        b.title,
        b.description,
        b.publication_year,
        b.author_id,
        b.borrowed,
        u.id AS borrower_id,
        u.email AS borrower_email,
        u.display_name AS borrower_name,
        b.image,
        a.first_name,
        a.last_name,
        a.birth_date,
        a.nationality,
        a.biography
      FROM books b
      LEFT JOIN authors a ON a.id = b.author_id
      LEFT JOIN users u ON u.id = b.borrower_id
      ORDER BY b.title ASC
    ''');
    return results.map(_rowToBook).toList();
  }

  List<Map<String, dynamic>> listBooksByAuthor(int authorId) {
    final results = _db.select(
      '''
      SELECT
        b.id,
        b.title,
        b.description,
        b.publication_year,
        b.author_id,
        b.borrowed,
        u.id AS borrower_id,
        u.email AS borrower_email,
        u.display_name AS borrower_name,
        b.image,
        a.first_name,
        a.last_name,
        a.birth_date,
        a.nationality,
        a.biography
      FROM books b
      LEFT JOIN authors a ON a.id = b.author_id
      LEFT JOIN users u ON u.id = b.borrower_id
      WHERE b.author_id = ?
      ORDER BY b.title ASC
    ''',
      [authorId],
    );
    return results.map(_rowToBook).toList();
  }

  Map<String, dynamic>? getBook(int id) {
    final results = _db.select(
      '''
      SELECT
        b.id,
        b.title,
        b.description,
        b.publication_year,
        b.author_id,
        b.borrowed,
        u.id AS borrower_id,
        u.email AS borrower_email,
        u.display_name AS borrower_name,
        b.image,
        a.first_name,
        a.last_name,
        a.birth_date,
        a.nationality,
        a.biography
      FROM books b
      LEFT JOIN authors a ON a.id = b.author_id
      LEFT JOIN users u ON u.id = b.borrower_id
      WHERE b.id = ?
    ''',
      [id],
    );
    if (results.isEmpty) return null;
    return _rowToBook(results.first);
  }

  int insertBook(Map<String, dynamic> data) {
    _db.execute(
      '''
INSERT INTO books (title, description, publication_year, author_id, image, borrowed, borrower_id)
         VALUES (?, ?, ?, ?, ?, ?, ?)''',
      [
        data['title'],
        data['description'],
        data['publicationYear'],
        data['authorId'],
        data['image'],
        if (data['borrowed'] as bool) 1 else 0,
        data['borrowerId'],
      ],
    );
    return _lastInsertedId;
  }

  bool updateBook(int id, Map<String, dynamic> data) {
    _db.execute(
      '''
UPDATE books
            SET title = ?,
                description = ?,
                publication_year = ?,
                author_id = ?,
                image = ?,
                borrowed = ?,
                borrower_id = ?
          WHERE id = ?''',
      [
        data['title'],
        data['description'],
        data['publicationYear'],
        data['authorId'],
        data['image'],
        if (data['borrowed'] as bool) 1 else 0,
        data['borrowerId'],
        id,
      ],
    );
    return true;
  }

  bool deleteBook(int id) {
    if (!bookExists(id)) {
      return false;
    }
    _db.execute('DELETE FROM books WHERE id = ?', [id]);
    return true;
  }

  bool borrowBook(int id, int userId) {
    final book = _db.select('SELECT borrowed FROM books WHERE id = ? LIMIT 1', [id]);
    if (book.isEmpty) return false;
    if ((book.first['borrowed'] as int) == 1) return false;
    final user = _db.select('SELECT 1 FROM users WHERE id = ? LIMIT 1', [userId]);
    if (user.isEmpty) return false;
    _db.execute(
      'UPDATE books SET borrowed = 1, borrower_id = ? WHERE id = ?',
      [userId, id],
    );
    return true;
  }

  bool returnBook(int id) {
    final book = _db.select('SELECT 1 FROM books WHERE id = ? LIMIT 1', [id]);
    if (book.isEmpty) return false;
    _db.execute(
      'UPDATE books SET borrowed = 0, borrower_id = NULL WHERE id = ?',
      [id],
    );
    return true;
  }

  bool authorExists(int id) => _recordExists('authors', id);

  bool bookExists(int id) => _recordExists('books', id);

  bool userExists(int id) => _recordExists('users', id);

  // ===== MÉTHODES DE TRANSFORMATION (Row -> Map) =====

  /// Convertit une ligne SQL en objet User (Map JSON)
  /// Utilise le snake_case de la DB et le camelCase pour l'API
  Map<String, dynamic> _rowToUser(Row row) {
    return {
      'id': row['id'] as int,
      'email': row['email'] as String,
      'displayName': row['display_name'] as String?, // snake_case -> camelCase
    };
  }

  /// Convertit une ligne SQL en objet Author
  Map<String, dynamic> _rowToAuthor(Row row) {
    return _mapAuthor(row);
  }

  /// Convertit une ligne SQL en objet Book avec relations imbriquées
  /// Inclut l'auteur et l'emprunteur si disponibles (LEFT JOIN)
  Map<String, dynamic> _rowToBook(Row row) {
    return {
      'id': row['id'] as int,
      'title': row['title'] as String,
      'description': row['description'] as String?,
      'publicationYear': row['publication_year'] as int,
      'borrowed': (row['borrowed'] as int) == 1, // SQLite stocke les booléens en int
      'image': row['image'] as String?,
      // Relations imbriquées (nested objects)
      'author': row['author_id'] == null ? null : _mapAuthor(row, idColumn: 'author_id'),
      'borrower': row['borrower_id'] == null
          ? null
          : {
              'id': row['borrower_id'] as int,
              'displayName': row['borrower_name'] as String?,
              'email': row['borrower_email'] as String?,
            },
    };
  }

  // ===== MÉTHODES UTILITAIRES =====

  /// Récupère l'ID du dernier enregistrement inséré
  /// Utilisé après INSERT pour obtenir l'ID auto-incrémenté
  int get _lastInsertedId {
    final result = _db.select('SELECT last_insert_rowid() AS id');
    return result.first['id'] as int;
  }

  /// Transforme une Row en objet Author avec mapping snake_case -> camelCase
  Map<String, dynamic> _mapAuthor(Row row, {String idColumn = 'id'}) {
    return {
      'id': row[idColumn] as int,
      'firstName': (row['first_name'] as String?) ?? '',
      'lastName': (row['last_name'] as String?) ?? '',
      'birthDate': row['birth_date'] as String?,
      'nationality': row['nationality'] as String?,
      'biography': row['biography'] as String?,
    };
  }

  /// Vérifie si un enregistrement existe dans une table donnée
  bool _recordExists(String table, int id) {
    final result = _db.select('SELECT 1 FROM $table WHERE id = ? LIMIT 1', [id]);
    return result.isNotEmpty;
  }

  /// Migration incrémentale : ajoute les colonnes manquantes à la table books
  /// Utilisé pour ajouter de nouvelles colonnes sans recréer la table
  void _ensureBookColumns() {
    // PRAGMA table_info retourne les métadonnées de la table
    final info = _db.select('PRAGMA table_info(books)');
    final columns = info.map((row) => row['name'] as String).toSet();

    // Ajouter la colonne 'borrowed' si elle n'existe pas
    if (!columns.contains('borrowed')) {
      _db.execute('ALTER TABLE books ADD COLUMN borrowed INTEGER NOT NULL DEFAULT 0');
    }
    // Ajouter la colonne 'borrower_id' si elle n'existe pas
    if (!columns.contains('borrower_id')) {
      _db.execute('ALTER TABLE books ADD COLUMN borrower_id INTEGER');
    }
  }
}
