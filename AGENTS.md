# AI Agent Instructions for monak

## Project overview
- `monak` is a Flutter application with a lightweight PHP backend under `backend/`.
- The mobile/web/desktop app is implemented in `lib/`.
- The backend is a local PHP API with files like `login.php`, `get_users.php`, `manage_ortu.php`, etc.
- The app uses `http`, `shared_preferences`, and `google_fonts`.

## Important directories
- `lib/main.dart` — app entry point and `MaterialApp` setup.
- `lib/screens/` — Flutter screens, including login, dashboards, and management screens.
- `lib/services/api_service.dart` — backend communication, local vs emulator URL handling, and mock fallback behavior.
- `backend/` — PHP API endpoints and database setup.

## Build and validation commands
- `flutter pub get` — fetch dependencies.
- `flutter analyze` — validate Dart code and catch syntax/AST issues.
- `flutter test` — run widget/unit tests.
- `flutter run` — launch the app on a connected device or emulator.
- `php -S 127.0.0.1:8000 -t backend` — start the local PHP backend for app integration.

## Key conventions and patterns
- The app relies on `ApiService.baseUrl` to switch between local, Android emulator, and online backend URLs.
- Android emulator network access uses `http://10.0.2.2:8000`; other platforms use `http://127.0.0.1:8000`.
- `ApiService` contains mock login/data fallback for offline development.
- Screens are mostly stateful UI pages under `lib/screens/`; errors often occur from malformed Dart widget trees or missing braces.

## Common issue guidance
- For syntax errors like `Can't find '}' to match '{'`, inspect the surrounding Dart widget tree and ensure all braces/parentheses are balanced.
- If the backend is not running, many API calls fall back to mock data or return connection errors.
- Keep changes localized: `lib/screens/` for UI, `lib/services/api_service.dart` for backend integration, and `backend/` for API logic.

## When to use AI assistance
- Refactoring large Flutter screens into smaller widgets.
- Fixing Dart syntax issues and balancing widget tree braces.
- Updating API integration and backend URL handling.
- Improving backend error handling or mock fallback behavior.

## Notes for future agents
- Do not assume a published package; `publish_to: none` is set in `pubspec.yaml`.
- This project is a local app with PHP backend support, not a production cloud service.
- Prefer using the existing PHP endpoint names and payload formats in `backend/` when changing API calls.
