import 'dart:async';
import 'dart:io';

import 'package:beaupeyratheque_mobile/models/author.dart';
import 'package:beaupeyratheque_mobile/models/book.dart';
import 'package:beaupeyratheque_mobile/models/user.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Fichiers séparés contenant les différentes parties de l'API (organisation modulaire)
part './api_service_auth.dart';
part './api_service_authors.dart';
part './api_service_books.dart';
part './api_service_users.dart';

/// Service centralisé pour gérer toutes les requêtes HTTP vers l'API backend
/// Utilise Dio pour les requêtes HTTP et FlutterSecureStorage pour stocker le cookie de session
class ApiService {
  /// Constructeur avec initialisation de Dio
  /// Le baseUrl provient d'une variable d'environnement
  ApiService({String baseUrl = const String.fromEnvironment('API_BASE_URL')})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          // Headers pour API Platform (format JSON-LD)
          headers: {'Content-Type': 'application/ld+json', 'Accept': 'application/ld+json'},
        ),
      );

  static const _cookieKey = 'session_cookie';

  final Dio _dio; // Client HTTP pour les requêtes
  final _secureStorage = const FlutterSecureStorage(); // Stockage sécurisé
  bool _initialized = false; // Flag pour éviter les initialisations multiples
  String? _sessionCookie; // Cookie de session stocké en mémoire

  // StreamController pour notifier les changements d'état d'authentification
  // broadcast() permet d'avoir plusieurs listeners
  final _authStateController = StreamController<bool>.broadcast();
  Stream<bool> get authStateStream => _authStateController.stream;

  /// Initialise le service API
  /// - Charge le cookie de session depuis le stockage sécurisé
  /// - Configure les intercepteurs Dio pour gérer automatiquement les cookies et erreurs
  Future<void> init() async {
    if (_initialized) return; // Éviter une double initialisation

    // Récupérer le cookie stocké lors de la session précédente
    _sessionCookie = await _secureStorage.read(key: _cookieKey);
    debugPrint('[ApiService] init - session cookie: ${_sessionCookie != null ? "exists" : "null"}');
    _authStateController.add(await hasToken());

    // Ajout d'intercepteurs pour modifier automatiquement les requêtes/réponses
    _dio.interceptors.add(
      InterceptorsWrapper(
        // onRequest : appelé AVANT chaque requête
        onRequest: (options, handler) {
          debugPrint('[ApiService] Request: ${options.method} ${options.path}');
          // Ajouter le cookie de session à chaque requête si disponible
          if (_sessionCookie != null && _sessionCookie!.isNotEmpty) {
            options.headers[HttpHeaders.cookieHeader] = 'app-local-session=$_sessionCookie';
            debugPrint('[ApiService] Adding session cookie to request');
          }
          handler.next(options); // Continuer la requête
        },
        // onResponse : appelé APRÈS chaque réponse réussie
        onResponse: (response, handler) async {
          debugPrint('[ApiService] Response: ${response.statusCode} ${response.requestOptions.path}');
          // Capturer le cookie de session si présent dans la réponse
          await _captureSessionCookie(response.headers);
          handler.next(response); // Continuer le traitement
        },
        // onError : appelé en cas d'erreur HTTP
        onError: (error, handler) async {
          debugPrint('[ApiService] Error: ${error.response?.statusCode} ${error.requestOptions.path}');
          final response = error.response;
          if (response != null) {
            await _captureSessionCookie(response.headers);
            // Si erreur 401 (non autorisé), déconnecter l'utilisateur
            if (response.statusCode == 401) {
              debugPrint('[ApiService] 401 error - clearing token');
              await clearToken();
            }
          }
          handler.next(error); // Propager l'erreur
        },
      ),
    );

    _initialized = true;
  }

  /// Supprime le cookie de session (déconnexion)
  /// Efface à la fois la mémoire et le stockage sécurisé
  Future<void> clearToken() async {
    debugPrint('[ApiService] clearToken called');
    _sessionCookie = null; // Effacer de la mémoire
    await _secureStorage.delete(key: _cookieKey); // Effacer du stockage
    _authStateController.add(false); // Notifier les listeners de la déconnexion
  }

  /// Vérifie si un cookie de session existe
  /// Retourne true si l'utilisateur est authentifié
  Future<bool> hasToken() async {
    // D'abord vérifier en mémoire (plus rapide)
    if (_sessionCookie != null && _sessionCookie!.isNotEmpty) {
      debugPrint('[ApiService] hasToken: true (in memory)');
      return true;
    }

    // Sinon charger depuis le stockage sécurisé
    _sessionCookie = await _secureStorage.read(key: _cookieKey);
    final hasToken = _sessionCookie != null && _sessionCookie!.isNotEmpty;
    debugPrint('[ApiService] hasToken: $hasToken (from storage)');
    return hasToken;
  }

  /// Capture et stocke le cookie de session depuis les headers de réponse HTTP
  /// Appelé automatiquement après chaque réponse grâce aux intercepteurs
  Future<void> _captureSessionCookie(Headers headers) async {
    final values = headers[HttpHeaders.setCookieHeader];
    if (values == null || values.isEmpty) return;

    // Parcourir tous les cookies de la réponse
    for (final value in values) {
      final cookie = Cookie.fromSetCookieValue(value);
      // Rechercher le cookie de session nommé 'app-local-session'
      if (cookie.name == 'app-local-session' && cookie.value.isNotEmpty) {
        debugPrint('[ApiService] Captured session cookie');
        _sessionCookie = cookie.value; // Stocker en mémoire
        await _secureStorage.write(key: _cookieKey, value: _sessionCookie); // Persister
        _authStateController.add(true); // Notifier l'authentification réussie
        break;
      }
    }
  }
}
