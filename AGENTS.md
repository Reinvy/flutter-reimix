# AI Agent Coding Guidelines (AGENTS.md)

This document serves as the source of truth for any AI Coding Agent or LLM working on the `reimix` codebase. All new code generation, modifications, and testing MUST adhere strictly to these guidelines to ensure consistency, architectural integrity, and style matching.

---

## 1. Project Overview & Tech Stack
`reimix` is a beautiful, mood-based offline local music player application built with Flutter.
- **Database / Local Storage**: ObjectBox (fast, NoSQL local database).
- **State Management**: Flutter Riverpod (StateNotifier, AsyncNotifier, etc. - **manual** style).
- **Audio Playback Engine**: `just_audio` and `audio_service` (for foreground and background music control).
- **Navigation**: `go_router` (declarative routing with named paths).
- **Typography & Aesthetics**: Nunito font (via `google_fonts`), custom visual overlay animations, and active dynamic color adjustments based on the user's current mood (`MoodTheme`).

---

## 2. Directory & Architecture Structure
The project is designed using **Clean Architecture** principles. Code is split into four primary directories inside `lib/`:

```
lib/
├── core/                 # Shared configurations, routing, themes, constants
│   ├── constants/        # Color palettes, text styles, size dimensions, and strings
│   ├── errors/           # Custom application exception classes
│   ├── router/           # Navigation setup (GoRouter config & AppRoutes definitions)
│   ├── theme/            # Material 3 light/dark themes and mood-based colors
│   └── utils/            # Helper utilities and extensions
├── domain/               # Pure business logic layer (No external platform/db dependencies)
│   ├── entities/         # Immutable plain Dart models
│   ├── repositories/     # Abstract interface contracts for repositories
│   └── usecases/         # Application-specific business rules
├── data/                 # Data access, network, database, and platform integrations
│   ├── datasources/      # Remote/local data retrievers (e.g. MediaStore, AudioHandler)
│   ├── models/           # ObjectBox entity models annotated with @Entity()
│   └── repositories_impl/# Implementations of domain repositories (maps models to entities)
└── presentation/         # UI rendering and state controllers
    ├── providers/        # Riverpod providers/notifiers controlling state
    ├── screens/          # Screen-level views/scaffolds mapped to routes
    └── widgets/          # Reusable component widgets (e.g. tiles, overlays, cards)
```

---

## 3. Code Conventions & Styling Rules

### 3.1 Import Style
- **Inside `lib/`**: Always use **Relative Imports** for files within the project. Do not use package imports for internal files.
  - *Correct*: `import '../../core/constants/app_colors.dart';`
  - *Incorrect*: `import 'package:reimix/core/constants/app_colors.dart';`
- **External Dependencies**: Use standard package imports.
  - *Correct*: `import 'package:flutter_riverpod/flutter_riverpod.dart';`

### 3.2 State Management (Riverpod)
- **NO Code Generation**: Even though Riverpod generator annotations exist in dependencies, **DO NOT** use `@riverpod` or code generation (`.g.dart` files) for providers.
- All providers and notifiers must be written manually:
  - Use `StateNotifier` + `StateNotifierProvider` for synchronous or simple state.
  - Use `AsyncNotifier` + `AsyncNotifierProvider` for asynchronous state.
  - Use standard `Provider`, `FutureProvider`, and `StateProvider` where appropriate.

### 3.3 Database Models & Persistence (ObjectBox)
- Database entity classes must be located in `lib/data/models/` and suffixed with `Model` (e.g., `SongModel`).
- Annotate ObjectBox models with `@Entity()`, `@Id()`, and other required ObjectBox decorators.
- Define custom datetime values as `@Property(type: PropertyType.date)`.
- When changes are made to ObjectBox models, run build runner:
  ```powershell
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
- **Mapping**: Data models must never leakage to the domain layer. Map `SongModel` to `Song` (and vice-versa) inside `lib/data/repositories_impl/` using mapper functions.

### 3.4 UI Styling, Typography & Design System
- Avoid hardcoded values (colors, margins, padding, text sizes). Always use tokens:
  - Colors: `AppColorsLight` and `AppColorsDark` from `lib/core/constants/app_colors.dart`.
  - Dimensions: Spacing, border radius, and icon sizes from `lib/core/constants/app_dimensions.dart`.
  - Text Styles: Typography scale utilizing Google Fonts' Nunito typeface from `lib/core/constants/app_text_styles.dart`.
- Mood colors override base themes dynamically. Use `MoodTheme.of(mood)` to get colors for the active mood.

---

## 4. Testing Guidelines

### 4.1 Test Structure & Mocks
- All unit, widget, and provider tests must reside in the `test/` directory, mirroring the structure of `lib/`.
- Use `package:mocktail` for writing mock implementations.
- All reusable mocks must be added to or referenced from `test/helpers/mock_repositories.dart`. Do not declare duplicate mock classes inside individual test files.

### 4.2 Import Style in Tests
- Unlike `lib/`, test files **MUST** use absolute package imports to import code under test.
  - *Correct*: `import 'package:reimix/core/theme/mood_theme.dart';`
  - *Incorrect*: `import '../../lib/core/theme/mood_theme.dart';`

### 4.3 Running Tests
- Before concluding a task, verify all tests pass:
  ```powershell
  flutter test
  ```
