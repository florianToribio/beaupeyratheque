# Beaupeyratheque Server

> 🚀 **Serveur backend Dart/Shelf** pour l'application mobile Beaupeyratheque.

Serveur HTTP REST complet avec :

- 🔐 Authentification JWT via cookies HTTP
- 📚 CRUD pour auteurs, livres et utilisateurs
- 💾 Base de données SQLite

## 🛠️ Prérequis

- **Dart SDK** : ≥ 3.0.0
- **SQLite** : Inclus via `sqlite3` (aucune installation requise)

## 📦 Installation

```sh
cd server_dart
dart pub get
```

## 🚀 Démarrage

### Lancer le serveur local

```sh
dart run bin/server.dart
```

Le serveur démarre sur **http://localhost:8080** par défaut.

### Exposer avec ngrok (pour tests mobile)

```sh
killall ngrok  # Tuer les instances précédentes
ngrok http 8080
```

Ngrok fournit une URL HTTPS publique (ex: `https://abc123.ngrok.io`) qui redirige vers votre serveur local.

### Configuration du port

```sh
PORT=3000 dart run bin/server.dart
```

## 💾 Base de données

Une base SQLite `beaupeyratheque.db` est créée automatiquement dans `server_dart/data/` au premier démarrage.

### Données de test (seeding)

Le serveur insère automatiquement :

- ✍️ **2 auteurs** : Jules Verne, George Orwell
- 📖 **2 livres** : "Vingt mille lieues sous les mers", "1984"

Les utilisateurs sont créés via l'endpoint `/api/users`.

## 🔑 Compte de test

Créer directement un compte via l'endpoint `/api/users` :

## 🌐 Endpoints API

### Authentication

| Méthode | Route        | Description                        |
| ------- | ------------ | ---------------------------------- |
| `POST`  | `/api/token` | Connexion (retourne un cookie JWT) |

### Users

| Méthode | Route        | Description                 |
| ------- | ------------ | --------------------------- |
| `GET`   | `/api/users` | Liste tous les utilisateurs |
| `POST`  | `/api/users` | Créer un utilisateur        |

### Authors

| Méthode  | Route                     | Description            |
| -------- | ------------------------- | ---------------------- |
| `GET`    | `/api/authors`            | Liste tous les auteurs |
| `POST`   | `/api/authors`            | Créer un auteur        |
| `GET`    | `/api/authors/{id}`       | Obtenir un auteur      |
| `PUT`    | `/api/authors/{id}`       | Modifier un auteur     |
| `DELETE` | `/api/authors/{id}`       | Supprimer un auteur    |
| `GET`    | `/api/authors/{id}/books` | Livres d'un auteur     |

### Books

| Méthode  | Route                    | Description           |
| -------- | ------------------------ | --------------------- |
| `GET`    | `/api/books`             | Liste tous les livres |
| `POST`   | `/api/books`             | Créer un livre        |
| `GET`    | `/api/books/{id}`        | Obtenir un livre      |
| `PUT`    | `/api/books/{id}`        | Modifier un livre     |
| `DELETE` | `/api/books/{id}`        | Supprimer un livre    |
| `POST`   | `/api/books/{id}/borrow` | Emprunter un livre    |
| `POST`   | `/api/books/{id}/return` | Retourner un livre    |

### Health

| Méthode | Route     | Description       |
| ------- | --------- | ----------------- |
| `GET`   | `/health` | Status du serveur |

## 📋 Exemples curl

### Créer un utilisateur

```sh
curl -i -X POST http://localhost:8080/api/users \
  -H 'Content-Type: application/json' \
  -d '{"email":"email","password":"MonMotDePasse","displayName":"Pseudo"}'
```

### Se connecter

```sh
curl -i -X POST http://localhost:8080/api/token \
  -H 'Content-Type: application/json' \
  -d '{"email":"email","password":"MonMotDePasse"}'
```

Retourne un cookie `app-local-session` contenant le JWT.

### Lister les auteurs

```sh
curl http://localhost:8080/api/authors
```

### Créer un auteur

```sh
curl -X POST http://localhost:8080/api/authors \
  -H 'Content-Type: application/json' \
  -d '{"firstName":"Victor","lastName":"Hugo","nationality":"Française","birthDate":"1802-02-26"}'
```

### Créer un livre (lié à l'auteur 1)

```sh
curl -X POST http://localhost:8080/api/books \
  -H 'Content-Type: application/json' \
  -d '{"title":"Les Misérables","publicationYear":1862,"author":"/api/authors/1","description":"Roman social"}'
```

### Emprunter un livre

```sh
curl -X POST http://localhost:8080/api/books/1/borrow \
  -H 'Content-Type: application/json' \
  -d '{"userId":1}'
```

### Retourner un livre

```sh
curl -X POST http://localhost:8080/api/books/1/return
```

## 🏗️ Architecture

```
server_dart/
├── bin/
│   └── server.dart          # Point d'entrée, configuration Shelf
├── lib/src/
│   ├── api.dart             # Routes et handlers HTTP
│   └── database.dart        # Gestion SQLite (CRUD + migrations)
├── data/
│   └── beaupeyratheque.db   # Base SQLite (auto-créée)
└── pubspec.yaml             # Dépendances
```

### Composants principaux

**`bin/server.dart`** : Configuration et lancement du serveur Shelf

- Middlewares : logging, CORS
- Initialisation de la base de données

**`lib/src/api.dart`** : Gestionnaire de routes et logique métier

- Router Shelf avec pattern matching
- Validation des données
- Authentification JWT
- Gestion des erreurs HTTP

**`lib/src/database.dart`** : Couche d'accès aux données

- Seeding de données de test
- Requêtes paramétrées (protection SQL injection)

## 📝 Notes techniques

### Format de réponse

- Les listes retournent des tableaux JSON : `[...]`
- Les objets uniques retournent des maps : `{...}`
- Les erreurs retournent : `{"message": "..."}`

### Relations

Les livres incluent leurs relations imbriquées :

```json
{
  "id": 1,
  "title": "1984",
  "publicationYear": 1949,
  "borrowed": true,
  "author": {
    "id": 2,
    "firstName": "George",
    "lastName": "Orwell"
  },
  "borrower": {
    "id": 1,
    "email": "user@example.com",
    "displayName": "John Doe"
  }
}
```

### Reset de la base

Supprimer le fichier pour tout réinitialiser :

```sh
rm data/beaupeyratheque.db
```

Au prochain démarrage, la base sera recréée avec les données de test.
