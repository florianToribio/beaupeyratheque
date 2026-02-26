coucou
# Beaupeyratheque Mobile

> 📚 **Projet pédagogique** : Application mobile Flutter pour gérer une bibliothèque.
> Code commenté pour servir d'exemple aux étudiants.

Application complète permettant de consulter, emprunter et gérer des livres et leurs auteurs. Inclut un backend Dart/Shelf avec base de données SQLite.

## ✨ Fonctionnalités

- 🔐 **Authentification** : Connexion/Inscription avec JWT et cookies sécurisés
- 📖 **Gestion des livres** : CRUD complet avec emprunts
- ✍️ **Gestion des auteurs** : Ajout, modification, suppression
- 👥 **Liste des utilisateurs** : Consultation des membres
- 🔄 **Pull-to-refresh** : Rafraîchissement des listes
- 💾 **Persistance** : Session maintenue via FlutterSecureStorage

## 🛠️ Prérequis

- **Flutter** : 3.32.8 (channel stable)
- **Dart SDK** : Pour le serveur backend
- **ngrok** : Pour exposer le serveur local (développement mobile)

## 📦 Installation

```sh
# Installer les dépendances Flutter
flutter pub get

# Installer les dépendances du serveur
cd server_dart
dart pub get
cd ..
```

## 🚀 Démarrage rapide

### 1. Démarrer le serveur backend

```sh
cd server_dart
dart run bin/server.dart
```

Le serveur démarre sur `http://localhost:8080`

### 2. Exposer avec ngrok (pour mobile)

```sh
killall ngrok  # Tuer les instances précédentes
ngrok http 8080
```

Copiez l'URL HTTPS fournie (ex: `https://abc123.ngrok.io`)

### 3. Configurer l'URL de l'API

Dans `lib/services/api_service.dart`, définir la variable d'environnement ou modifier le baseUrl :

```sh
flutter run --dart-define=API_BASE_URL=https://abc123.ngrok.io
```

ATTENTION, sur émulateur Android, utilisez `http://10.0.2.2:8080` pour accéder au serveur local.

URL à utiliser dans Flutter
Émulateur Android: http://10.0.2.2:8080
Simulateur iOS : http://localhost:8080
Appareil physique + adb reverse : http://localhost:8080 (adb reverse tcp:8080 tcp:8080) -> (adb reverse --remove tcp:8080)
Appareil physique sans adb reverse : http://192.168.x.x:8080 (IP locale du PC)

### 4. Lancer l'application

```sh
# Par défaut (détection automatique)
flutter run

# Plateformes spécifiques
flutter run -d chrome        # Web
flutter run -d macos         # macOS
flutter run -d android       # Android
flutter run -d ios           # iOS
```

## 🏗️ Architecture

### Application mobile (Flutter)

```
lib/
├── screens/              # Écrans de l'application
│   ├── preload/         # Écran de chargement et vérification auth
│   ├── login/           # Connexion et inscription
│   └── home/            # Onglets (auteurs, livres, utilisateurs)
├── services/            # Couche métier
│   └── api_service.dart # Client HTTP avec intercepteurs Dio
├── models/              # Modèles de données (Author, Book, User)
├── mixins/              # Comportements réutilisables
│   └── auth_redirect_mixin.dart  # Redirection auto si déconnecté
└── extensions/          # Extensions Dart
    └── date_time_extensions.dart # Formatage de dates
```

### Serveur backend (Dart)

```
server_dart/
├── bin/server.dart      # Point d'entrée du serveur
├── lib/src/
│   ├── api.dart         # Routes et handlers HTTP (Shelf Router)
│   └── database.dart    # Gestion SQLite (CRUD + migrations)
└── data/                # Base de données SQLite (auto-créée)
```

## 📚 Concepts pédagogiques couverts

### Flutter/Dart côté client

- ✅ **StatefulWidget** vs **StatelessWidget**
- ✅ **Gestion d'état** avec `setState()`
- ✅ **Navigation** : routes nommées et `Navigator`
- ✅ **Formulaires** : validation, contrôleurs
- ✅ **HTTP** : Dio avec intercepteurs
- ✅ **Streams** : `StreamController` pour l'état d'authentification
- ✅ **Mixins** : réutilisation de code sans héritage
- ✅ **Extensions** : ajout de méthodes à des classes existantes
- ✅ **Null safety** : opérateurs `??`, `?.`, `!`
- ✅ **Async/await** : gestion des opérations asynchrones

### Dart côté serveur

- ✅ **Shelf** : framework HTTP minimaliste
- ✅ **Routing** : gestion des routes REST
- ✅ **SQLite** : base de données relationnelle
- ✅ **Migrations** : gestion du schéma de base
- ✅ **JWT** : authentification stateless
- ✅ **Cookies HTTP** : stockage sécurisé côté client

## 📦 Dépendances principales

### Application mobile

- **`dio`** : Client HTTP avancé avec intercepteurs
- **`flutter_secure_storage`** : Stockage sécurisé des cookies de session
- **`intl`** : Formatage de dates et internationalisation

### Serveur backend

- **`shelf`** : Framework HTTP Dart minimaliste
- **`shelf_router`** : Routing pour les endpoints REST
- **`sqlite3`** : Base de données embarquée
- **`dart_jsonwebtoken`** : Génération et validation de JWT

## 🔧 Développement

### Analyse statique

L'analyse statique est configurée avec `very_good_analysis` pour garantir la qualité du code :

```sh
flutter analyze
```

## 📖 Documentation additionnelle

- **[README du serveur](server_dart/README.md)** : Documentation complète du backend
- **[Endpoints API](server_dart/README.md#endpoints)** : Liste des routes disponibles
- **Exemples curl** : Tests manuels de l'API
