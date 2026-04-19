# SAYIBI AI — Application Flutter

Application mobile et web (Android, iOS, Web) pour SAYIBI AI : chat, documents, génération, recherche et profil.

## Prérequis

- Flutter 3.x (SDK Dart 3.10+)
- Backend FastAPI démarré (voir `../sayibi_backend`)

## Configuration API

Par défaut, le backend utilisé est **`https://sayibi-backend.onrender.com`** (`lib/core/constants/api_constants.dart`, `API_HOST`).

**Backend local (uvicorn)** :

```bash
flutter run --dart-define=API_HOST=http://127.0.0.1:8000
```

**Émulateur Android → machine locale** :

```bash
flutter run --dart-define=API_HOST=http://10.0.2.2:8000
```

**Web (Chrome) vers Render** — fixer le port pour coller au `CORS_ORIGINS` du serveur (ex. 8080) :

```bash
cd sayibi_flutter
flutter pub get
flutter run -d chrome --web-port=8080
```

Si le navigateur ouvre un autre port et qu’une erreur CORS apparaît, ajoutez `http://localhost:CE_PORT` dans la variable **`CORS_ORIGINS`** sur Render (Dashboard → service → Environment).

## Lancer le projet

```bash
cd sayibi_flutter
flutter pub get
flutter run
```

## Structure

- `lib/core/` — thème, constantes (dont chaînes UI pour i18n), services (`ApiService` avec refresh JWT, Hive, tokens).
- `lib/features/` — écrans et providers Riverpod par domaine.
- `lib/shared/` — widgets et modèles partagés.

## Authentification

Connexion / inscription appellent `/api/v1/auth/*`. Les jetons sont stockés via `shared_preferences` et rafraîchis automatiquement sur `401` grâce à l’intercepteur Dio.

## Navigation

`go_router` : splash → onboarding (première fois) → login → shell principal avec barre du bas (Chat, Docs, Créer, Recherche, Profil). Un raccourci voix ouvre une feuille modale avec l’écran voix.
