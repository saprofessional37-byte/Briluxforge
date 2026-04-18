# CLAUDE.MD — Briluxforge Master System Architecture & Directives

> **Document Version:** 2.2-MVP
> **Target Executor:** Claude 3.5 Sonnet (Junior Coder)
> **Authored By:** Staff Architect / Lead Security Engineer
> **Last Updated:** 2026-04-16

---

## 1. System Persona & Core Directives

### 1.1 Persona

You are a **disciplined senior Flutter engineer** building a production desktop application. You write clean, minimal, testable Dart code. You do not explain concepts unless asked. You do not add comments that restate what code already says. Every response must contain **working code or a concrete architectural decision** — never filler.

### 1.2 Absolute Laws (Violating Any of These Is a Critical Failure)

1. **ZERO-PROMPT-BACKEND LAW** — Briluxforge has **no backend for processing user prompts, storing API keys, or handling chat data.** All prompts go directly from the user's device to their configured API provider. The only permitted network calls to services we control are: (a) Firebase Authentication for user accounts, and (b) Gumroad API for license validation. If you find yourself writing a server that touches prompts, keys, or chat data, **stop immediately.**
2. **MVP-SCOPE LAW** — You must never suggest, plan, or build anything outside the MVP feature list defined in Section 9 of this document. If a feature is not in the Phase list, it does not exist. Do not "future-proof" by pre-building hooks for features that are not in scope.
3. **LOCAL-FIRST LAW** — All user content data (API keys, chat history, skills, preferences, token counts) lives on the device. The only exceptions are the user's authentication identity (Firebase) and license status (Gumroad). No telemetry, no analytics, no crash reporting.
4. **NO-HALLUCINATION LAW** — If you are unsure about a Flutter API, a Dart method signature, or a package's behavior, say so. Do not invent APIs. Do not guess parameter names. Ask me, or state the uncertainty explicitly.
5. **SINGLE-FILE OUTPUT LAW** — When I ask you to build a file, give me the **complete file** from the first import to the closing brace. Never give partial snippets, diffs, or "add this somewhere." I will paste your output directly into my IDE.
6. **PREMIUM UX LAW** — User interface quality is a primary competitive advantage for Briluxforge. Every screen, every widget, every interaction must feel polished and premium. No placeholder UI that "we'll fix later." No unstyled defaults. If a screen exists, it must look finished. The bar is Claude Desktop / Linear / Raycast.

### 1.3 Communication Rules

- When I paste an error, diagnose it. Do not re-explain the architecture.
- When I ask for a file, produce the file. Do not produce a plan for the file.
- Prefix every response with a one-line summary: `// FILE: lib/features/chat/chat_screen.dart` or `// ACTION: pubspec.yaml dependency addition`.
- If my request conflicts with this document, **this document wins**. Flag the conflict and follow this document.

---

## 2. Tech Stack & Syntax Enforcement

### 2.1 Locked Dependencies

| Dependency | Version Constraint | Purpose |
|---|---|---|
| **Core** | | |
| `flutter` | Stable channel, latest | UI framework |
| `flutter_riverpod` | `^2.5.x` | State management (runtime) |
| `riverpod_annotation` | `^2.3.x` | Code-gen annotations |
| `riverpod_generator` | `^2.4.x` (dev) | Generates providers |
| `build_runner` | latest (dev) | Code generation |
| `json_annotation` | latest | Model serialization |
| `json_serializable` | latest (dev) | Codegen for models |
| **Security & Storage** | | |
| `flutter_secure_storage` | `^9.x` | Platform-native key storage (API keys only) |
| `drift` | latest | Type-safe SQLite for chat history & skills |
| `sqlite3_flutter_libs` | latest | SQLite native binaries for desktop |
| `drift_dev` | latest (dev) | Drift code generation |
| `shared_preferences` | latest | Non-sensitive prefs (onboarding flags, theme) |
| `path_provider` | latest | Local file system paths |
| **Networking** | | |
| `http` | `^1.x` | Raw HTTP for API calls |
| **Auth & Licensing** | | |
| `firebase_core` | latest | Firebase initialization |
| `firebase_auth` | latest | User account auth (email/password) |
| **UI** | | |
| `flutter_markdown` | latest | Markdown rendering in chat messages |
| `highlight` | latest | Code syntax highlighting inside markdown |
| `url_launcher` | latest | Opening links from markdown content |
| `google_fonts` | latest | Inter font family |
| **Utility** | | |
| `uuid` | `^4.x` | Unique IDs for messages/conversations |
| `equatable` | latest | Value equality for models |

**Do NOT add any dependency not listed here without explicit written approval from me.** If you believe a package is needed, state the case. Do not add it preemptively.

### 2.2 Riverpod Architecture — Mandatory Syntax

**You must use `riverpod_generator` with annotation-based syntax exclusively.** Legacy `StateNotifierProvider`, `ChangeNotifierProvider`, and manual `Provider` declarations are **banned**. Mixing old and new Riverpod syntax creates state management bugs that are extremely difficult to debug.

#### Provider Declaration (The Only Allowed Pattern)

```dart
// CORRECT — annotation-based, code-generated
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_provider.g.dart';

@riverpod
class ChatNotifier extends _$ChatNotifier {
  @override
  ChatState build() {
    return const ChatState.initial();
  }

  Future<void> sendMessage(String content) async {
    state = state.copyWith(status: ChatStatus.loading);
    // ...
  }
}
```

```dart
// CORRECT — simple computed/derived provider
@riverpod
int tokenCount(Ref ref) {
  final chat = ref.watch(chatNotifierProvider);
  return chat.messages.fold(0, (sum, m) => sum + m.tokenCount);
}
```

```dart
// BANNED — legacy syntax, never use these
final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) => ...); // ❌
final myProvider = ChangeNotifierProvider((ref) => ...); // ❌
final myProvider = Provider<MyService>((ref) => ...); // ❌
```

#### Provider File Rules

- Every provider file must have `part 'filename.g.dart';` at the top.
- After creating or modifying any provider, remind me to run: `dart run build_runner build --delete-conflicting-outputs`
- Never hand-write `.g.dart` files.

### 2.3 Dart Style Rules

- **Immutable state.** All state classes are `@immutable` or use `@freezed` / manual `copyWith`. Never mutate state objects directly.
- **Named parameters.** All widget constructors and model constructors use named parameters with `required` where non-nullable.
- **Trailing commas.** Every parameter list, argument list, and collection literal that spans multiple lines gets a trailing comma. This is non-negotiable — it ensures consistent `dart format` output.
- **Explicit types.** No `var` for class fields or function return types. `var` is acceptable only for trivially obvious local variables (e.g., `var list = <String>[];`).
- **No dynamic.** The type `dynamic` is banned. Use `Object?` when truly needed, or define a proper type.
- **Null safety.** No `!` bang operator unless there is a preceding null check on the same variable within the same scope. If you find yourself using `!`, refactor the logic.
- **Const constructors.** Use `const` on every constructor, widget, and value that allows it. Flutter's widget rebuild optimization depends on this.

### 2.4 Project Folder Structure

```
briluxforge/
├── lib/
│   ├── main.dart                          # Entry point, ProviderScope, MaterialApp
│   ├── app.dart                           # MaterialApp.router config, theme
│   │
│   ├── core/                              # Shared infrastructure (non-feature)
│   │   ├── constants/
│   │   │   ├── app_constants.dart          # App name, version, magic numbers
│   │   │   └── api_constants.dart          # Endpoint URLs, model identifiers
│   │   ├── theme/
│   │   │   ├── app_theme.dart              # ThemeData definitions (dark + light)
│   │   │   ├── app_colors.dart             # Color palette
│   │   │   └── app_typography.dart         # TextTheme + semantic text styles
│   │   ├── routing/
│   │   │   └── app_router.dart             # Top-level navigation/routing
│   │   ├── utils/
│   │   │   ├── logger.dart                 # Structured logging utility
│   │   │   └── extensions.dart             # Dart extension methods
│   │   ├── database/
│   │   │   ├── app_database.dart           # Drift database definition
│   │   │   └── app_database.g.dart         # Generated
│   │   └── errors/
│   │       ├── app_exception.dart          # Custom exception hierarchy
│   │       └── error_handler.dart          # Global error catch + formatting
│   │
│   ├── features/                           # Feature-sliced modules
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── user_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository.dart
│   │   │   ├── presentation/
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── signup_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       └── auth_form.dart
│   │   │   └── providers/
│   │   │       └── auth_provider.dart
│   │   │
│   │   ├── licensing/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── license_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── gumroad_repository.dart
│   │   │   ├── presentation/
│   │   │   │   └── widgets/
│   │   │   │       └── license_status_banner.dart
│   │   │   └── providers/
│   │   │       └── license_provider.dart
│   │   │
│   │   ├── onboarding/
│   │   │   ├── presentation/
│   │   │   │   ├── onboarding_screen.dart
│   │   │   │   ├── use_case_screen.dart       # "What will you use Briluxforge for?"
│   │   │   │   └── widgets/
│   │   │   │       └── use_case_card.dart      # Illustrated option cards
│   │   │   └── providers/
│   │   │       └── onboarding_provider.dart
│   │   │
│   │   ├── api_keys/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── api_key_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── api_key_repository.dart
│   │   │   ├── presentation/
│   │   │   │   ├── api_key_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── api_key_card.dart
│   │   │   │       └── key_status_indicator.dart
│   │   │   └── providers/
│   │   │       └── api_key_provider.dart
│   │   │
│   │   ├── delegation/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   ├── delegation_result.dart
│   │   │   │   │   └── model_profile.dart
│   │   │   │   └── engine/
│   │   │   │       ├── delegation_engine.dart     # Layer 1: local rule engine
│   │   │   │       ├── keyword_matrix.dart        # Keyword/pattern scoring
│   │   │   │       ├── context_analyzer.dart      # Token counting, context sizing
│   │   │   │       └── fallback_handler.dart      # Layer 2 + 3: API + default
│   │   │   ├── presentation/
│   │   │   │   └── widgets/
│   │   │   │       └── delegation_failure_dialog.dart  # User choice on failure
│   │   │   └── providers/
│   │   │       └── delegation_provider.dart
│   │   │
│   │   ├── chat/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   ├── message_model.dart
│   │   │   │   │   └── conversation_model.dart
│   │   │   │   ├── tables/
│   │   │   │   │   ├── conversations_table.dart   # Drift table definition
│   │   │   │   │   └── messages_table.dart        # Drift table definition
│   │   │   │   └── repositories/
│   │   │   │       └── chat_repository.dart       # Drift-backed CRUD
│   │   │   ├── presentation/
│   │   │   │   ├── chat_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── message_bubble.dart         # Markdown-rendered message
│   │   │   │       ├── chat_input_bar.dart
│   │   │   │       ├── model_selector.dart
│   │   │   │       └── delegation_badge.dart
│   │   │   └── providers/
│   │   │       ├── chat_provider.dart
│   │   │       └── active_conversation_provider.dart
│   │   │
│   │   ├── skills/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── skill_model.dart
│   │   │   │   ├── tables/
│   │   │   │   │   └── skills_table.dart          # Drift table definition
│   │   │   │   └── repositories/
│   │   │   │       └── skills_repository.dart
│   │   │   ├── presentation/
│   │   │   │   ├── skills_screen.dart
│   │   │   │   ├── skill_editor_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── skill_card.dart
│   │   │   │       └── skill_toggle.dart
│   │   │   └── providers/
│   │   │       └── skills_provider.dart
│   │   │
│   │   ├── savings/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── savings_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── savings_repository.dart
│   │   │   ├── presentation/
│   │   │   │   └── widgets/
│   │   │   │       └── savings_tracker_widget.dart
│   │   │   └── providers/
│   │   │       └── savings_provider.dart
│   │   │
│   │   └── settings/
│   │       ├── presentation/
│   │       │   └── settings_screen.dart
│   │       └── providers/
│   │           └── settings_provider.dart
│   │
│   └── services/                           # Cross-feature services
│       ├── secure_storage_service.dart      # flutter_secure_storage wrapper
│       ├── api_client_service.dart          # Generic HTTP caller for all providers
│       └── skill_injection_service.dart     # Prepends active skills to API calls
│
├── test/                                    # Mirrors lib/ structure
├── assets/
│   ├── brain/
│   │   └── model_profiles.json             # Smart Brain data (shipped with app)
│   └── images/
│       └── onboarding/                     # Illustrated cards for use-case selection
│           ├── coding.svg
│           ├── research.svg
│           ├── writing.svg
│           ├── building.svg
│           └── general.svg
├── pubspec.yaml
└── analysis_options.yaml
```

**Rules:**

- Every feature is self-contained inside `features/<n>/`.
- Features communicate only through Riverpod providers — never by importing another feature's internal files directly.
- The `services/` directory is for stateless, cross-cutting utilities. Services are injected via `@riverpod` providers.
- The `core/` directory is for truly shared, non-feature infrastructure (theme, routing, error handling, database).
- **No barrel files** (`export` re-exports). Every import must point to the exact file. Barrel files create circular dependency risks and make tree-shaking harder.

---

## 3. Authentication & Licensing

### 3.1 Why Accounts Exist

Briluxforge requires user accounts for one reason: **to manage paid subscriptions.** Users sign up with email + password. No credit card is required at signup or during the free trial. API keys, chat data, and all content remain local — accounts are purely for identity and license gating.

### 3.2 Auth Architecture — Firebase Authentication

Firebase Auth is used because it is a managed service with a free tier — it is **not** our backend. The Flutter SDK talks directly to Firebase servers. We write zero server-side auth code.

```dart
/// AuthRepository — wraps Firebase Auth SDK.
/// This is the ONLY file that imports firebase_auth.
class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> logIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logOut() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  User? get currentUser => _auth.currentUser;
}
```

**Auth Flow:**

```
App Launch
    │
    ▼
┌──────────────────────┐
│ Firebase Auth Check   │
│ (authStateChanges)    │
└───────┬──────────────┘
        │
   ┌────┴────┐
   │ Logged  │ No ──→ Login/Signup Screen
   │  In?    │            │
   └────┬────┘            ▼
        │           Signup (email + password, NO credit card)
        │                 │
        ▼                 ▼
┌──────────────────────┐
│ License Check        │
│ (Gumroad validation) │
└───────┬──────────────┘
        │
   ┌────┴────────┐
   │ Valid       │ No/Trial ──→ Free trial mode (full features, time-limited)
   │ License?    │                 │
   └────┬────────┘                 ▼
        │                    Trial expired? → Upgrade prompt (Gumroad checkout link)
        ▼
   Main App (full access)
```

### 3.3 Licensing — Gumroad Integration

Gumroad handles all payment processing. Briluxforge validates license keys against the Gumroad API.

**Pricing tiers (from product.md):**

| Plan | Price | Gumroad Product |
|---|---|---|
| Monthly | $9/month | Subscription product |
| Annual | $59/year | Subscription product |
| Lifetime | $99 one-time | One-time product |

```dart
/// GumroadRepository — validates license keys against Gumroad's API.
/// Endpoint: POST https://api.gumroad.com/v2/licenses/verify
class GumroadRepository {
  static const String _verifyUrl = 'https://api.gumroad.com/v2/licenses/verify';

  Future<LicenseModel> verifyLicense({
    required String productId,
    required String licenseKey,
  }) async {
    final response = await http.post(
      Uri.parse(_verifyUrl),
      body: {
        'product_id': productId,
        'license_key': licenseKey,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, Object?>;
      return LicenseModel.fromGumroadResponse(data);
    } else {
      throw LicenseValidationException('Invalid license key');
    }
  }
}
```

**License status is cached locally** in `SharedPreferences` with a timestamp. Re-validate against Gumroad every 24 hours when online. If offline, trust the cached status for up to 7 days.

**Free trial:** Full functionality for a trial period (default to 7 days; I will confirm exact duration). No credit card at signup. When the trial expires, the app shows a non-dismissable upgrade screen with a link to the Gumroad checkout page.

### 3.4 What Auth Does NOT Do

- ❌ Does not sync chat history, API keys, skills, or any user content to the cloud.
- ❌ Does not gate features based on plan tier (all paid tiers get the same features for MVP).
- ❌ Does not require login to store API keys (keys are stored locally regardless).
- ❌ Does not use Google Sign-In, Apple Sign-In, or OAuth for MVP — email/password only.

---

## 4. UI/UX & Design Language

### 4.1 Design Philosophy

Premium UI/UX is a **core competitive advantage** for Briluxforge, not an afterthought. The target quality bar is **Claude Desktop / Linear / Raycast.** Every screen ships polished. Every interaction feels intentional. No "good enough for now" UI.

### 4.2 Theme Architecture

Define `AppTheme` in `core/theme/app_theme.dart`. Support **dark mode as primary, light mode as secondary** — both must be implemented for MVP, but dark mode is the default.

```dart
class AppTheme {
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: AppColors.primary,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.backgroundDark,
    // ... comprehensive overrides for cards, dialogs, inputs, etc.
  );

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: AppColors.primary,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.backgroundLight,
    // ...
  );
}
```

### 4.3 Layout Rules for Desktop

- **Minimum window size:** 900×600 pixels. Set via platform channel on startup.
- **Maximum content width:** Chat message column maxes at `~760px`, centered — matches the comfortable reading width of Claude/ChatGPT.
- **Sidebar:** Left-side, collapsible, 260px default width. Contains: conversation list, skills toggle, savings tracker, settings access.
- **No TabBar navigation.** Desktop apps use sidebars, not tab bars.
- **No responsive grid system.** Desktop-only for MVP. Build for ≥900px wide.
- **Keyboard shortcuts:** `Ctrl/Cmd+N` (new chat), `Ctrl/Cmd+Enter` (send), `Ctrl/Cmd+,` (settings), `Ctrl/Cmd+K` (model selector). Use `Shortcuts` + `Actions` widgets.

### 4.4 Widget Rules

- Use **Material 3** widgets (`FilledButton`, `SearchBar`, `NavigationDrawer`, etc.).
- **No Cupertino widgets.** Cross-platform desktop; Material 3 on all OSes for consistency.
- **No custom paint** unless explicitly approved. Prefer composition of existing Material widgets.
- **Animations:** Use only `AnimatedContainer`, `AnimatedOpacity`, `AnimatedSwitcher`, and implicit animations. No `AnimationController` unless I specifically request a custom animation.

### 4.5 Markdown Rendering in Chat

Chat messages from AI assistants **must** be rendered as rich markdown. This is essential for code blocks, lists, tables, bold/italic, and links. Users sending and receiving code will encounter large chunks of output — rendering as plain text would be a disqualifying UX failure.

**Implementation:**

```dart
/// Use flutter_markdown with code syntax highlighting.
/// Every assistant message passes through this renderer.
MarkdownBody(
  data: message.content,
  selectable: true,
  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
    codeblockDecoration: BoxDecoration(
      color: AppColors.codeBlockBackground,
      borderRadius: BorderRadius.circular(8),
    ),
    code: Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontFamily: 'JetBrains Mono',
    ),
  ),
  builders: {
    'code': CodeBlockBuilder(), // Custom builder with syntax highlighting + copy button
  },
  onTapLink: (text, href, title) {
    if (href != null) launchUrl(Uri.parse(href));
  },
)
```

**Rules for markdown rendering:**

- Assistant messages: **always** render as markdown.
- User messages: render as plain text (users don't write markdown).
- Code blocks must have a **copy button** in the top-right corner.
- Code blocks must have **syntax highlighting** via the `highlight` package.
- Links must be clickable and open in the system browser.
- Tables must render properly — if `flutter_markdown` struggles with complex tables, degrade gracefully to a code block.

### 4.6 Typography

Use **Inter** as the primary font (via `google_fonts`). Monospace uses system default or bundled **JetBrains Mono** for code blocks. Define a `TextTheme` extension:

- `titleLarge` — Screen titles
- `bodyLarge` — Chat messages
- `bodyMedium` — UI labels
- `labelSmall` — Metadata (timestamps, token counts, delegation badges)

Never use raw `TextStyle` with hardcoded sizes in widgets. Always reference `Theme.of(context).textTheme`.

---

## 5. The Skills System

### 5.1 What a Skill Is

A **skill** is a reusable system prompt (instruction set) that is injected into API calls to customize the model's behavior. This mirrors Claude's skills system. Examples:

- "Senior Flutter Developer" — instructs the model to write Flutter/Dart code with specific conventions
- "Academic Researcher" — instructs the model to cite sources and use formal tone
- "Email Copywriter" — instructs the model to write concise, persuasive emails

### 5.2 Skill Data Model

```dart
/// Stored in local SQLite via Drift.
@immutable
class SkillModel {
  final String id;                // UUID
  final String name;              // "Senior Flutter Developer"
  final String description;       // Short summary shown on the card
  final String systemPrompt;      // The actual instruction text injected into API calls
  final bool isEnabled;           // Whether this skill is active globally
  final bool isBuiltIn;           // true = shipped with app, false = user-created
  final List<String>? pinnedProviders;  // null = applies to all; ["deepseek", "anthropic"] = specific
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### 5.3 How Skills Are Applied

When a chat message is sent to an API, the `SkillInjectionService` collects all enabled skills and prepends them to the system prompt:

```dart
class SkillInjectionService {
  /// Builds the system prompt by combining all active skills.
  /// If a skill has pinnedProviders, only include it if the
  /// selected model's provider matches.
  String buildSystemPrompt({
    required List<SkillModel> enabledSkills,
    required String selectedProvider,
  }) {
    final applicableSkills = enabledSkills.where((skill) {
      if (skill.pinnedProviders == null) return true;
      return skill.pinnedProviders!.contains(selectedProvider);
    });

    if (applicableSkills.isEmpty) return '';

    return applicableSkills
        .map((s) => '## Skill: ${s.name}\n${s.systemPrompt}')
        .join('\n\n---\n\n');
  }
}
```

### 5.4 Skills UI

- **Skills Screen** — accessible from the sidebar. Lists all skills (built-in + user-created). Each skill has a toggle switch to enable/disable.
- **Skill Editor** — create or edit a skill. Fields: name, description, system prompt text area, provider pinning (optional), enable/disable toggle.
- **Skill Card** — compact display showing name, description, status badge, and provider tags.
- **Chat Input Integration** — a small skills indicator near the chat input shows how many skills are active: `"3 skills active"`. Tapping it opens a quick-toggle panel.

### 5.5 Built-In Skills Shipped with MVP

Ship 5 pre-built skills to demonstrate the feature's value immediately:

1. **"Concise Responder"** — "Keep responses brief and direct. No filler, no caveats, no disclaimers unless safety-critical."
2. **"Code Expert"** — "You are a senior software engineer. Always provide complete, production-ready code. Include error handling. No pseudocode."
3. **"Research Assistant"** — "Provide thorough, well-sourced answers. Cite specific data when available. Distinguish between facts and speculation."
4. **"Creative Writer"** — "Write with vivid, engaging prose. Use varied sentence structure. Show, don't tell."
5. **"ELI5 Explainer"** — "Explain concepts as if talking to a curious 10-year-old. Use analogies and simple language."

These are `isBuiltIn: true` and cannot be deleted (but can be disabled or have their prompt text customized).

---

## 6. The Delegation Engine — Three-Layer Architecture

This is Briluxforge's core competitive feature. It must be **fast, deterministic, and transparent.** The user must **always be informed** about what the engine is doing and must **always have a choice** when delegation is uncertain.

### 6.1 Overview

When the user sends a prompt, Briluxforge must decide which connected API model handles it. The decision flows through three layers, with **explicit user notification and choice at every failure point:**

```
User Prompt
    │
    ▼
┌─────────────────────────────────┐
│  LAYER 1: Local Rule Engine     │  ← Runs on-device, zero latency
│  (keyword matrix + heuristics)  │
│  Confidence threshold: ≥ 0.70   │
└───────────┬─────────────────────┘
            │ confidence < 0.70
            ▼
┌─────────────────────────────────────────────────────┐
│  DELEGATION FAILURE DIALOG                          │
│  "I'm not sure which model is best for this."       │
│                                                     │
│  ┌─────────────────┐  ┌──────────────────────────┐  │
│  │ Use Default (X)  │  │ Let [Best Model] Decide  │  │
│  │ (free, instant)  │  │ (costs a few tokens)     │  │
│  └─────────────────┘  └──────────────────────────┘  │
│                                                     │
│  ☐ Remember this choice for similar prompts         │
└───────────┬───────────────────────┬─────────────────┘
            │                       │
     User picks Default      User picks "Let AI Decide"
            │                       │
            ▼                       ▼
┌──────────────────────┐  ┌─────────────────────────────┐
│  LAYER 3: Default    │  │  LAYER 2: API-Assisted      │
│  (user-set default)  │  │  Triage (meta-prompt to      │
│  Always succeeds.    │  │  strongest connected model)  │
└──────────────────────┘  │  Confidence ≥ 0.50           │
                          └───────────┬─────────────────┘
                                      │ failure / confidence < 0.50
                                      ▼
                          ┌──────────────────────────────┐
                          │  NOTIFICATION BANNER          │
                          │  "AI routing was uncertain.   │
                          │   Falling back to [Default]." │
                          │  [OK] [Change Model ▾]        │
                          └──────────────────────────────┘
                                      │
                                      ▼
                          ┌──────────────────────┐
                          │  LAYER 3: Default    │
                          │  Fallback            │
                          └──────────────────────┘
```

**Key UX principles:**

- The user is **never left in the dark** about delegation failures. Every fallback is announced.
- The user **always has a choice** — they can pick the default, let AI decide, or manually select a model.
- The "Remember this choice" checkbox lets power users reduce interruptions over time.

### 6.2 Default Model Selection — Influenced by Onboarding

The user's default model is initially set based on their answer to the onboarding use-case question (see Section 9, Phase 2):

| Onboarding Choice | Default Model (if connected) | Reasoning |
|---|---|---|
| Coding & Debugging | DeepSeek V3 | Best cost-to-performance for code |
| Research & Analysis | Gemini Flash | Massive context window, good summarization |
| Writing & Creative | Claude Sonnet | Best for nuance, tone, instruction-following |
| Building Apps & Websites | DeepSeek V3 | Strong full-stack coding at lowest cost |
| A Little Bit of Everything | DeepSeek V3 | Best all-rounder at lowest cost |

The user can change their default at any time in Settings. Smart Brain Updates (Section 6.6) may adjust these recommendations as the model landscape changes.

### 6.3 Layer 1 — Local Rule Engine (Detail Spec)

This layer runs entirely in Dart. No ML model, no network call. It must return a result in **< 5ms**.

#### 6.3.1 Model Profiles (`assets/brain/model_profiles.json`)

A JSON file shipped with the app (and updatable via Smart Brain Updates) that defines each supported model:

```json
{
  "models": [
    {
      "id": "deepseek-chat",
      "provider": "deepseek",
      "displayName": "DeepSeek V3",
      "strengths": ["coding", "reasoning", "math", "debugging"],
      "contextWindow": 65536,
      "costPer1kInput": 0.00014,
      "costPer1kOutput": 0.00028,
      "tier": "workhorse"
    },
    {
      "id": "gemini-2.0-flash",
      "provider": "google",
      "displayName": "Gemini 2.0 Flash",
      "strengths": ["long_context", "summarization", "general", "speed"],
      "contextWindow": 1048576,
      "costPer1kInput": 0.0000375,
      "costPer1kOutput": 0.00015,
      "tier": "workhorse"
    },
    {
      "id": "claude-sonnet-4-20250514",
      "provider": "anthropic",
      "displayName": "Claude Sonnet 4",
      "strengths": ["writing", "analysis", "nuance", "instruction_following"],
      "contextWindow": 200000,
      "costPer1kInput": 0.003,
      "costPer1kOutput": 0.015,
      "tier": "premium"
    }
  ]
}
```

This file is the **single source of truth** for all model capabilities. The delegation engine reads it at startup and caches it in memory.

#### 6.3.2 Keyword Scoring Matrix

Define a `Map<String, List<WeightedKeyword>>` that maps task categories to weighted keywords/patterns:

```dart
const Map<String, List<WeightedKeyword>> keywordMatrix = {
  'coding': [
    WeightedKeyword('function',       0.6),
    WeightedKeyword('debug',          0.9),
    WeightedKeyword('error',          0.7),
    WeightedKeyword('code',           0.8),
    WeightedKeyword('implement',      0.7),
    WeightedKeyword('refactor',       0.8),
    WeightedKeyword('API',            0.5),
    WeightedKeyword('class',          0.5),
    WeightedKeyword('compile',        0.9),
    WeightedKeyword('runtime',        0.7),
    WeightedKeyword('syntax',         0.8),
    WeightedKeyword('algorithm',      0.7),
    WeightedKeyword('regex',          0.6),
    WeightedKeyword('SQL',            0.7),
    WeightedKeyword('Python',         0.8),
    WeightedKeyword('JavaScript',     0.8),
    WeightedKeyword('Dart',           0.8),
    WeightedKeyword('TypeScript',     0.8),
    WeightedKeyword('Rust',           0.8),
  ],
  'reasoning': [
    WeightedKeyword('explain',        0.5),
    WeightedKeyword('why',            0.4),
    WeightedKeyword('analyze',        0.7),
    WeightedKeyword('compare',        0.6),
    WeightedKeyword('evaluate',       0.6),
    WeightedKeyword('logic',          0.8),
    WeightedKeyword('proof',          0.7),
    WeightedKeyword('derive',         0.7),
    WeightedKeyword('tradeoff',       0.6),
  ],
  'math': [
    WeightedKeyword('calculate',      0.8),
    WeightedKeyword('equation',       0.9),
    WeightedKeyword('integral',       0.9),
    WeightedKeyword('derivative',     0.9),
    WeightedKeyword('matrix',         0.7),
    WeightedKeyword('probability',    0.8),
    WeightedKeyword('statistics',     0.7),
    WeightedKeyword('solve',          0.5),
  ],
  'writing': [
    WeightedKeyword('write',          0.6),
    WeightedKeyword('essay',          0.8),
    WeightedKeyword('draft',          0.7),
    WeightedKeyword('rewrite',        0.7),
    WeightedKeyword('tone',           0.6),
    WeightedKeyword('blog',           0.7),
    WeightedKeyword('email',          0.5),
    WeightedKeyword('story',          0.8),
    WeightedKeyword('creative',       0.7),
    WeightedKeyword('poem',           0.8),
  ],
  'summarization': [
    WeightedKeyword('summarize',      0.9),
    WeightedKeyword('TLDR',           0.9),
    WeightedKeyword('key points',     0.8),
    WeightedKeyword('overview',       0.6),
    WeightedKeyword('digest',         0.7),
    WeightedKeyword('condense',       0.8),
  ],
  'long_context': [
    // Triggered by context length, not keywords. See Section 6.3.3.
  ],
  'general': [
    // Default fallback category. Activates when no other category exceeds threshold.
  ],
};
```

#### 6.3.3 Context Length Heuristic

Before keyword scoring, estimate the total context size:

```dart
int estimateTokens(String text) {
  // Rough heuristic: 1 token ≈ 4 characters for English text.
  return (text.length / 4).ceil();
}
```

- If `estimateTokens(prompt) > 30000`, automatically boost `long_context` score to `1.0` and prefer models with `contextWindow > 200000`.
- If `estimateTokens(prompt) > 100000`, **force-select** a model with `contextWindow >= 1000000` if connected. If none connected, warn user before sending.

#### 6.3.4 Scoring Algorithm

```
For each connected model:
  1. Sum keyword weights that match the user's prompt → category_scores{}
  2. Rank categories by score
  3. For top category, check which models list it in their strengths
  4. Among matching models, prefer tier: "workhorse" for cost efficiency
  5. If top category score >= 0.70 → return that model with confidence = score
  6. If top category score < 0.70 → return null (triggers Delegation Failure Dialog)
```

**Critical constraints:**

- A model can only be selected if the user has a **verified, connected** API key for that provider.
- If only one model is connected, always use it. Skip scoring entirely. No dialog needed.
- The scoring runs synchronously. No async. No isolate needed at this scale.

#### 6.3.5 The DelegationResult Model

```dart
@immutable
class DelegationResult {
  final String selectedModelId;
  final String selectedProvider;
  final int layerUsed;           // 1, 2, or 3
  final double confidence;       // 0.0–1.0
  final String reasoning;        // "Routed to DeepSeek: coding keywords detected"
  final bool wasOverridden;      // True if user manually changed model
  final bool userChoseDefault;   // True if user picked default from failure dialog

  const DelegationResult({...});
}
```

This result is attached to every sent message so the user sees *why* a model was chosen.

### 6.4 Layer 2 — API-Assisted Triage

When the user selects "Let [Best Model] Decide" from the failure dialog, send a **classification meta-prompt** to the user's most capable connected model (`tier: premium` > `workhorse`):

```
System: You are a task classifier. Given the user's message below, respond with ONLY
a JSON object: {"category": "<one of: coding, reasoning, math, writing, summarization,
long_context, general>", "confidence": <0.0-1.0>}. Do not explain.

User: <the actual user prompt, truncated to first 500 characters>
```

**Rules:**

- Truncate prompt to 500 chars to minimize cost.
- Parse the JSON response. If `confidence >= 0.50`, map category to best available model.
- If JSON parsing fails or confidence < `0.50`, show notification banner: *"AI routing was uncertain. Falling back to [Default Model]."* with options to accept or change model.
- **Token cost for this meta-prompt is tracked** in the savings tracker.

### 6.5 Layer 3 — Default Fallback

The user's default model (initially set by onboarding, changeable in Settings). This layer **always succeeds** because it requires no decision logic.

### 6.6 Smart Brain Updates

`model_profiles.json` is shipped with the app but is designed to be **updatable.** For MVP, updates ship with app releases:

1. A new app version includes an updated `model_profiles.json` in `assets/brain/`.
2. On first launch after update, the app detects the version change and reloads the profile data.
3. The delegation engine immediately reflects new model capabilities, pricing, new models, or deprecated models.

This is a **core competitive feature** per product.md — not maintenance. Briluxforge's routing accuracy depends on these profiles staying current.

#### 6.6.1 Graceful Fallback on Model Removal (MANDATORY RULE)

A Smart Brain Update can remove a model from `model_profiles.json` — for example, when a provider deprecates a model, pricing changes drastically, or performance degrades. When this happens, **the app must never crash, never throw an unhandled exception, and never silently send prompts to a nonexistent model.**

**On every app launch**, after `model_profiles.json` is loaded, run a reconciliation step:

```dart
/// DefaultModelReconciler — runs on app startup AFTER model_profiles.json loads.
/// Guarantees the user's default model always points to a model that exists.
class DefaultModelReconciler {
  /// Priority-ordered list of safe, widely-available fallback model IDs.
  /// If the user's saved default no longer exists, try each of these in order.
  static const List<String> _safeFallbacks = [
    'gemini-2.0-flash',      // First choice: cheap, huge context, reliable
    'deepseek-chat',         // Second choice: best cost/performance
    'claude-sonnet-4-20250514', // Third choice: premium fallback
  ];

  Future<void> reconcile({
    required SettingsRepository settings,
    required List<ModelProfile> availableModels,
    required List<ApiKeyModel> connectedApis,
  }) async {
    final currentDefaultId = await settings.readDefaultModelId();
    final modelStillExists = availableModels.any((m) => m.id == currentDefaultId);

    if (modelStillExists) return; // Nothing to do.

    // The user's default was removed. Find a safe replacement.
    AppLogger.w('Reconciler',
        'Default model "$currentDefaultId" removed by Smart Brain Update. Reconciling.');

    // 1. Try safe fallbacks, preferring models the user has a connected API for.
    for (final fallbackId in _safeFallbacks) {
      final candidate = availableModels.firstWhereOrNull((m) => m.id == fallbackId);
      if (candidate == null) continue;
      final hasKey = connectedApis.any((k) => k.provider == candidate.provider && k.isVerified);
      if (hasKey) {
        await settings.writeDefaultModelId(candidate.id);
        await _notifyUser(candidate, reason: 'connected_fallback');
        return;
      }
    }

    // 2. No connected fallback. Pick any safe fallback that exists in the profile,
    //    even without a connected key (the user will be prompted to add one).
    for (final fallbackId in _safeFallbacks) {
      final candidate = availableModels.firstWhereOrNull((m) => m.id == fallbackId);
      if (candidate != null) {
        await settings.writeDefaultModelId(candidate.id);
        await _notifyUser(candidate, reason: 'no_connected_key');
        return;
      }
    }

    // 3. Absolute last resort: pick the first available model. Never leave null.
    final firstAvailable = availableModels.first;
    await settings.writeDefaultModelId(firstAvailable.id);
    await _notifyUser(firstAvailable, reason: 'last_resort');
  }

  Future<void> _notifyUser(ModelProfile newDefault, {required String reason}) async {
    // Queue a dismissable notification shown on next home screen render:
    // "Your previous default model is no longer supported. We've set [Gemini Flash]
    //  as your new default. You can change this anytime in Settings."
  }
}
```

**Rules this enforces:**

- `SettingsProvider.defaultModelId` is **never** allowed to hold a stale ID that doesn't exist in the current `model_profiles.json`.
- The reconciler runs **before** the chat UI becomes interactive, so the user cannot send a prompt to a phantom model.
- The user is **always notified** when their default changes due to a Smart Brain Update — silent changes are prohibited.
- Gemini Flash is the first-choice fallback because it is the cheapest, has the largest context window, and is one of the most reliably available APIs.
- If the reconciler cannot find any fallback (catastrophic `model_profiles.json` corruption), it picks the first model in the profile. It **never** leaves the default as null or the removed ID.

This same reconciliation logic also runs against any other code path that stores a model ID (e.g., per-conversation model overrides, skill provider pinning). Any stored model ID that no longer exists is reconciled to a safe equivalent on load.

### 6.7 Manual Override

After delegation decides, but before the API call fires, the user sees a small badge in the chat input area: `"→ DeepSeek V3 (coding detected)"`. Tapping the badge opens a model picker for manual override. Overrides are recorded in `DelegationResult.wasOverridden`.

---

## 7. Security & Privacy Protocols

### 7.1 API Key Storage

**Package:** `flutter_secure_storage` — wraps macOS Keychain, Windows Credential Manager (via DPAPI), and Linux libsecret. It is the **only** approved storage mechanism for API keys.

```dart
/// SecureStorageService — the ONLY class that touches API keys on disk.
/// No other file in the codebase may import flutter_secure_storage directly.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  static const _androidOptions = AndroidOptions(encryptedSharedPreferences: true);
  static const _linuxOptions = LinuxOptions();

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
            aOptions: _androidOptions,
            lOptions: _linuxOptions,
          );

  Future<void> storeKey(String provider, String key) async {
    await _storage.write(key: 'api_key_$provider', value: key);
  }

  Future<String?> readKey(String provider) async {
    return _storage.read(key: 'api_key_$provider');
  }

  Future<void> deleteKey(String provider) async {
    await _storage.delete(key: 'api_key_$provider');
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
```

### 7.2 Key Handling Rules (Memory Safety)

1. **Never log keys.** Not to console, not to files, not to any analytics. Not even partially.
2. **Never interpolate keys into strings** for debugging. No `print('Key: $apiKey')`.
3. **Keys in state must be ephemeral.** The Riverpod provider holds metadata only (provider name, connection status, last verified time) — NOT the key value. Read from `SecureStorageService` at call time, use it, let it fall out of scope.
4. **API key verification** calls the provider's cheapest endpoint. Error messages must never include the key.
5. **API request construction** — the `Authorization` header is built inside `ApiClientService` at the moment of the HTTP call. The key never passes through more than one function boundary.

### 7.3 API Client Security

```dart
class ApiClientService {
  final SecureStorageService _secureStorage;

  Future<ApiResponse> sendPrompt({
    required String provider,
    required String modelId,
    required List<Message> messages,
    required String systemPrompt,  // Includes injected skills
  }) async {
    final apiKey = await _secureStorage.readKey(provider);
    if (apiKey == null) throw ApiKeyNotFoundException(provider);

    final uri = _buildUri(provider, modelId);
    final headers = _buildHeaders(provider, apiKey);
    final body = _buildBody(provider, modelId, messages, systemPrompt);

    try {
      final response = await http.post(uri, headers: headers, body: body);
      return _parseResponse(provider, response);
    } catch (e) {
      throw ApiRequestException(
        provider: provider,
        statusCode: e is http.ClientException ? null : (e as dynamic).statusCode,
        message: _sanitizeError(e.toString(), apiKey),
      );
    }
  }

  String _sanitizeError(String error, String key) {
    return error.replaceAll(key, '[REDACTED]');
  }
}
```

### 7.4 Build Obfuscation

Every release build must use these flags:

```bash
flutter build windows --release --obfuscate --split-debug-info=build/debug-info/
flutter build macos --release --obfuscate --split-debug-info=build/debug-info/
flutter build linux --release --obfuscate --split-debug-info=build/debug-info/
```

- `--obfuscate` renames all Dart symbols to meaningless identifiers.
- `--split-debug-info` strips debug symbols into a separate directory — do NOT ship this.
- **Never ship debug builds. Never ship builds without obfuscation.**
- `build/debug-info/` must be in `.gitignore`.

### 7.5 Prohibited Practices

- ❌ Hardcoding any API key, token, or secret in source code.
- ❌ Storing keys in `SharedPreferences`, JSON files, SQLite, or any non-encrypted storage.
- ❌ Including keys in environment variables baked into the binary.
- ❌ Logging HTTP request headers in debug or release mode.
- ❌ Sending prompts, keys, or chat data to any server we control.

---

## 8. Development & Debugging Workflow

### 8.1 Code Output Format

When you produce code:

1. **Always give the full file.** First import to last closing brace.
2. **Include the file path** as a comment on line 1: `// lib/features/chat/data/models/message_model.dart`
3. **All imports must be explicit** — never say "import the usual packages."
4. **Generated files:** After producing any file with `part '*.g.dart'`, remind me to run `dart run build_runner build --delete-conflicting-outputs`.

### 8.2 Error Handling Architecture

```dart
// lib/core/errors/app_exception.dart

sealed class AppException implements Exception {
  final String message;
  final String? technicalDetail;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.technicalDetail,
    this.stackTrace,
  });
}

class ApiKeyNotFoundException extends AppException {
  final String provider;
  const ApiKeyNotFoundException(this.provider)
      : super(message: 'No API key found for $provider. Please add one in Settings.');
}

class ApiRequestException extends AppException {
  final String provider;
  final int? statusCode;
  const ApiRequestException({
    required this.provider,
    this.statusCode,
    required String message,
  }) : super(message: message, technicalDetail: 'Provider: $provider, Status: $statusCode');
}

class DelegationException extends AppException {
  const DelegationException(String message) : super(message: message);
}

class SecureStorageException extends AppException {
  const SecureStorageException(String message)
      : super(message: 'Secure storage error: $message');
}

class AuthException extends AppException {
  const AuthException(String message) : super(message: message);
}

class LicenseValidationException extends AppException {
  const LicenseValidationException(String message) : super(message: message);
}
```

### 8.3 Structured Logging

```dart
// lib/core/utils/logger.dart

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static LogLevel minimumLevel = LogLevel.debug;

  static void d(String tag, String message) => _log(LogLevel.debug, tag, message);
  static void i(String tag, String message) => _log(LogLevel.info, tag, message);
  static void w(String tag, String message) => _log(LogLevel.warning, tag, message);
  static void e(String tag, String message, [Object? error, StackTrace? stack]) {
    _log(LogLevel.error, tag, message);
    if (error != null) _log(LogLevel.error, tag, 'Error: $error');
    if (stack != null) _log(LogLevel.error, tag, 'Stack: $stack');
  }

  static void _log(LogLevel level, String tag, String message) {
    if (level.index < minimumLevel.index) return;
    final timestamp = DateTime.now().toIso8601String();
    final prefix = '[${level.name.toUpperCase()}][$tag]';
    debugPrint('$timestamp $prefix $message');
  }
}
```

### 8.4 Error Messages for Users

Every user-facing error must have:

1. **What happened** — plain English, no jargon.
2. **Why it likely happened** — the most common cause.
3. **What to do** — a concrete action.

Example: *"Couldn't connect to DeepSeek. This usually means your API key has expired or your account has no remaining credits. Open Settings → API Keys → DeepSeek and verify your key."*

Never show raw exception messages, stack traces, or HTTP status codes to users.

---

## 9. Execution Roadmap — Phase-by-Phase Build Order

**You must build in this exact order. Do not skip ahead. Do not start Phase N+1 until Phase N is confirmed complete by me.**

---

### Phase 1: Project Initialization & Skeleton

**Goal:** A compiling Flutter desktop app with the correct folder structure, dependencies, and theme — showing an empty shell with sidebar + main area.

**Deliverables:**

1. `pubspec.yaml` with all locked dependencies from Section 2.1.
2. `analysis_options.yaml` with strict linting.
3. Complete folder structure from Section 2.4 (empty placeholder files are fine).
4. `main.dart` → `ProviderScope` → Firebase init → `App` widget.
5. `app.dart` → `MaterialApp` with dark theme + light theme from Section 4.2.
6. A placeholder `HomeScreen` with a `Row`: left sidebar (260px, styled container) + expanded main area.
7. Minimum window size enforcement (900×600).
8. `AppDatabase` (Drift) — empty database class, configured for desktop SQLite.
9. Verify it compiles and runs on desktop.

---

### Phase 2: Authentication, Licensing & Onboarding

**Goal:** Users can sign up, log in, validate their license, and complete onboarding — including the use-case selection that sets their default model.

**Deliverables:**

1. Firebase project configuration (I will provide config files; Sonnet sets up Dart-side initialization).
2. `AuthRepository` (Section 3.2) — Firebase email/password sign-up, login, logout, password reset.
3. `AuthProvider` (Riverpod) — wraps `authStateChanges` stream, exposes current user.
4. `LoginScreen` — email + password fields, login button, link to signup, "Forgot password?" link. **Premium, polished UI.**
5. `SignupScreen` — email + password + confirm password. **No credit card field.** Clear messaging: *"Start your free trial — no credit card required."*
6. `GumroadRepository` (Section 3.3) — license key verification.
7. `LicenseProvider` — checks license status, caches locally, re-validates every 24h.
8. `LicenseStatusBanner` — subtle banner when trial is active showing days remaining.
9. **`LicenseKeyInputScreen`** — a dedicated screen (and also accessible from Settings post-onboarding) with:
   - A clearly labeled text input field: *"Paste your Gumroad License Key"*
   - A primary "Activate License" button that calls `GumroadRepository.verifyLicense()`
   - A secondary "Continue Free Trial" button for users who haven't purchased yet
   - A link: *"Don't have a license? Purchase at [briluxforge.app/buy]"* that opens the Gumroad checkout
   - Real-time validation feedback: loading spinner → green success card (*"License activated. Welcome!"*) or red error card with actionable advice (*"This license key wasn't recognized. Check that you copied the full key from your Gumroad purchase email."*)
   - Shown automatically when the free trial expires (non-dismissable at that point)
   - Accessible any time from Settings → License
10. **Onboarding flow (post-signup, first-run only):**
   - **Step 1: Welcome screen** — "Welcome to Briluxforge" with app branding.
   - **Step 2: Use-Case Selection screen** — *"What will you use Briluxforge for?"* with illustrated card options:
     - 🖥️ **Coding & Debugging** — "Writing, reviewing, and fixing code"
     - 🔬 **Research & Analysis** — "Deep dives, summaries, and fact-finding"
     - ✍️ **Writing & Creative** — "Essays, emails, stories, and content"
     - 🏗️ **Building Apps & Websites** — "Full-stack development and architecture"
     - 🌐 **A Little Bit of Everything** — "General assistant for all tasks"
     - Each card has an illustrated SVG icon and a one-line description. Single-select. Selection maps to default model per Section 6.2.
   - **Step 3: API Buying Guide** — Recommends which API keys to get based on use-case selection. Static content recommending DeepSeek + Gemini Flash as best-value starter combo.
   - **Step 4: Add First Key** — Direct to API Key entry screen.
   - **Step 5: Verify & Done** — Confirm key works, success animation, enter main app.
   - **Skip button** visible on steps 3–5 for power users.
11. `OnboardingProvider` — persists completion flag + use-case selection to `SharedPreferences`. Use-case feeds into `SettingsProvider` for initial default model.

---

### Phase 3: Secure Storage & API Key Management

**Goal:** Users can add, verify, view status of, and delete API keys stored in platform-native secure storage.

**Deliverables:**

1. `SecureStorageService` (Section 7.1) — complete, tested.
2. `ApiKeyModel` — immutable data class: `provider`, `displayName`, `isVerified`, `lastVerifiedAt`.
3. `ApiKeyRepository` — CRUD operations using `SecureStorageService`.
4. `ApiKeyProvider` (Riverpod) — state is `List<ApiKeyModel>` (metadata only, no key values).
5. `ApiKeyScreen` — UI for adding keys (text field + provider dropdown), with verify button. **Premium UI — not a boring form.**
6. `KeyStatusIndicator` — green checkmark (verified), red X (failed), grey dash (unverified).
7. Key verification: hit each provider's cheapest endpoint.
8. Actionable error messages on failure (per Section 8.4).
9. **Screenshot walkthrough placeholders** — UI containers in the API Key screen for step-by-step screenshots showing how to obtain keys from each provider. I will supply images.

---

### Phase 4: The Delegation Engine

**Goal:** The three-layer delegation system is functional and tested in isolation, including the failure dialog.

**Deliverables:**

1. `model_profiles.json` — initial dataset with at least DeepSeek, Gemini Flash, Claude Sonnet, GPT-4o, Llama (via Groq).
2. `ModelProfile` data class — parsed from JSON.
3. `KeywordMatrix` — full weighted keyword map from Section 6.3.2.
4. `ContextAnalyzer` — token estimation + context length routing.
5. `DelegationEngine` — Layer 1 scoring algorithm. Input: prompt + connected models. Output: `DelegationResult?`.
6. `FallbackHandler` — Layer 2 (API meta-prompt) + Layer 3 (default).
7. `DelegationFailureDialog` — interactive choice dialog from Section 6.1: "Use Default" vs "Let AI Decide" with "Remember" checkbox.
8. `DelegationProvider` — Riverpod provider exposing `delegate(String prompt)`.
9. Default model initialized from onboarding use-case selection (reads from `SettingsProvider`).
10. **`DefaultModelReconciler`** (Section 6.6.1) — runs on every app startup after `model_profiles.json` loads. Verifies the user's stored default model still exists in the current profile. If a Smart Brain Update has removed it, auto-selects a safe fallback (Gemini Flash → DeepSeek → Claude Sonnet in priority order) and shows a user-facing notification. Must run **before** the chat UI becomes interactive. No crashes, no silent swaps, no null defaults.
11. Unit tests: at least 12 test cases covering coding prompts, writing prompts, long context, single-model-connected, no-model-connected, override flag, failure dialog paths, default-from-onboarding, **reconciler when default was removed, reconciler when no connected fallback exists, reconciler catastrophic empty-profile case**.

---

### Phase 5: API Client Service

**Goal:** Briluxforge can send a prompt to any connected provider and receive a streamed response, with skills injected.

**Deliverables:**

1. `ApiClientService` (Section 7.3) — supports DeepSeek, Google (Gemini), Anthropic (Claude), OpenAI, Groq.
2. Provider-specific request builders (each API has different payload shapes).
3. Streaming support: SSE parsing for all supported providers.
4. `SkillInjectionService` (Section 5.3) — builds combined system prompt from active skills.
5. Error sanitization (key scrubbing per Section 7.3).
6. Response model: `ApiResponse` with `content`, `inputTokens`, `outputTokens`, `modelId`, `provider`.
7. Non-streaming fallback for any provider that fails mid-stream.

---

### Phase 6: Chat Interface & Local Database

**Goal:** Full chat UI with markdown rendering, Drift-backed persistence, delegation badge, model selector, and streaming responses.

**Database Architecture (Drift/SQLite):**

```dart
class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text().references(Conversations, #id)();
  TextColumn get role => text()();       // 'user' | 'assistant'
  TextColumn get content => text()();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get tokenCount => integer().withDefault(const Constant(0))();
  TextColumn get delegationJson => text().nullable()();
  TextColumn get provider => text().nullable()();
  TextColumn get modelId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Why Drift/SQLite instead of JSON files:**

- Conversations with hundreds of messages won't cause memory spikes.
- Searching and filtering conversations is instant (SQL vs. loading all JSON into memory).
- No UI jank from large file reads/writes on the main thread.
- Drift generates type-safe Dart — no manual JSON parsing for chat data.

**Deliverables:**

1. `Conversations` and `Messages` Drift table definitions.
2. `AppDatabase` updated with both tables + generated code.
3. `ChatRepository` — Drift-backed CRUD: create conversation, add message, load conversation, list conversations, delete conversation, search.
4. `MessageModel` and `ConversationModel` — domain models mapped from Drift rows.
5. `ChatProvider` — manages active conversation, message list, loading/error state. Streams from Drift for reactive updates.
6. `ChatScreen` — main chat view with scrollable message list + input bar.
7. `MessageBubble` — **renders assistant messages as rich markdown** (Section 4.5). Code blocks with syntax highlighting and copy button. User messages as styled plain text.
8. `ChatInputBar` — multi-line text field, send button, delegation badge, skills indicator.
9. `ModelSelector` — dropdown/popup for manual override.
10. `DelegationBadge` — shows which model was chosen and why.
11. Sidebar: conversation list with new chat button, search bar.
12. Streaming: assistant messages render token-by-token as they arrive.

---

### Phase 7: Skills System

**Goal:** Users can create, edit, enable/disable, and manage skills that customize AI behavior.

**Deliverables:**

1. `Skills` Drift table definition + database migration.
2. `SkillModel` (Section 5.2) — domain model.
3. `SkillsRepository` — Drift-backed CRUD.
4. `SkillsProvider` — exposes enabled skills, all skills, toggle, CRUD.
5. `SkillsScreen` — list with toggles. Built-in at top, user skills below. "Create Skill" button.
6. `SkillEditorScreen` — create/edit form: name, description, system prompt textarea, provider pinning, preview.
7. `SkillCard` — compact card with name, description, status, provider tags.
8. **Chat input integration** — indicator: `"3 skills active"`. Tapping opens quick-toggle popover.
9. **5 built-in skills** pre-populated (Section 5.5). `isBuiltIn: true`, cannot be deleted.
10. End-to-end verification: enable skill → send message → confirm system prompt includes skill text.

---

### Phase 8: Token Savings Tracker

**Goal:** A persistent, always-visible counter showing how much money the user is saving by running Briluxforge's multi-API strategy instead of routing every prompt through the industry's most premium flagship model. The number must grow monotonically with usage — the more the user uses Briluxforge, the larger the savings become.

---

#### 8.1 Why the Old Subscription-Baseline Logic Is Replaced

The initial spec compared actual API spend against a flat $20/month Claude Pro equivalent. This math is **architecturally broken** for the product's positioning:

- **It punishes power users.** A heavy DeepSeek user spending $25/month looks like they "lost $5" — directly contradicting the product's core pitch that BYOAPI is cheaper than any subscription.
- **It caps perceived value.** A subscription cost is a fixed ceiling. Our product's value grows with usage, but a flat baseline makes savings asymptote toward $20/month and then invert into "losses."
- **It compares the wrong things.** A subscription is a bundled flat rate; Briluxforge is a per-token usage model. The honest comparison is *"what would this exact token usage have cost on a premium alternative?"* — not *"what does a flat plan cost?"*

The new logic compares **exact token usage** against **what Claude Opus 4.6 (the industry's most expensive mainstream flagship) would have charged for the identical input/output tokens.** This is mathematically honest — the user genuinely had the option to send every prompt to Opus and chose not to — and the resulting savings number grows linearly and unboundedly with usage.

---

#### 8.2 CRITICAL ACCURACY RULE — Token Counting Source of Truth

The savings calculation **must** use the **exact `prompt_tokens` and `completion_tokens` values returned in the API provider's JSON response** — never the local `estimateTokens()` heuristic from `ContextAnalyzer`. The local heuristic exists only for pre-flight routing decisions (deciding which model can handle the context size); it is imprecise by design and **must not** be used for savings math.

Every provider returns token usage in their response JSON. Sonnet must extract these exact values at the `ApiClientService` layer:

| Provider | JSON Path for Input Tokens | JSON Path for Output Tokens |
|---|---|---|
| DeepSeek | `usage.prompt_tokens` | `usage.completion_tokens` |
| OpenAI | `usage.prompt_tokens` | `usage.completion_tokens` |
| Groq | `usage.prompt_tokens` | `usage.completion_tokens` |
| Anthropic Claude | `usage.input_tokens` | `usage.output_tokens` |
| Google Gemini | `usageMetadata.promptTokenCount` | `usageMetadata.candidatesTokenCount` |

`ApiResponse.inputTokens` and `ApiResponse.outputTokens` **must** be populated exclusively from these fields. If a provider's response is missing token counts (rare streaming edge case), log a warning and **skip** updating the savings tracker for that response — do **not** substitute with an estimate. A single visibly-wrong savings number would undermine the entire psychological hook.

---

#### 8.3 The Pricing Benchmark — Claude Opus 4.6

The benchmark is the **most expensive mainstream flagship** the user could plausibly have used instead. As of this document, that is **Claude Opus 4.6**:

| Metric | Value |
|---|---|
| Benchmark model ID | `claude-opus-4-6` |
| Input cost | **$5.00 per 1M tokens** (`$0.005 / 1K`) |
| Output cost | **$25.00 per 1M tokens** (`$0.025 / 1K`) |

The benchmark is stored as a dedicated entry in `assets/brain/model_profiles.json` with the flag `"isBenchmark": true`:

```json
{
  "models": [
    {
      "id": "claude-opus-4-6",
      "provider": "anthropic",
      "displayName": "Claude Opus 4.6",
      "costPer1kInput": 0.005,
      "costPer1kOutput": 0.025,
      "isBenchmark": true,
      "tier": "premium",
      "...": "..."
    }
  ]
}
```

**Why this benchmark works:**

1. **It's real.** Opus is an actual model the user could have routed every prompt to.
2. **It's universally recognized.** Anthropic's flagship is the category's reference point.
3. **It's expensive enough to guarantee positive savings** against every other model in the profile — DeepSeek, Gemini Flash, GPT-4o, Groq's Llama, and even Claude Sonnet are all dramatically cheaper per token.
4. **It's Smart-Brain-updatable.** When Anthropic releases a more expensive flagship (Opus 5, etc.), a `model_profiles.json` update swaps the `isBenchmark` flag onto the new model and every user's saved-dollar number recalculates automatically against the new ceiling.

**Fallback rule:** If `model_profiles.json` is missing the benchmark entry (corrupted or pre-update state), hard-code Opus 4.6's values as a constant fallback so the tracker never breaks. The benchmark being unavailable must never zero the display.

---

#### 8.4 The Savings Formula

For **every** successful API response the user receives, compute:

```
actualCost_thisCall    = (inputTokens × actualModel.costPer1kInput  / 1000)
                       + (outputTokens × actualModel.costPer1kOutput / 1000)

benchmarkCost_thisCall = (inputTokens × 0.005 / 1000)
                       + (outputTokens × 0.025 / 1000)

savings_thisCall       = benchmarkCost_thisCall − actualCost_thisCall
```

Cumulative savings is the sum across every call the user has ever made.

**Worked example** — user sends one prompt to DeepSeek V3:

- Input: 5,000 tokens / Output: 2,000 tokens
- DeepSeek actual cost: `(5000 × 0.00014 / 1000) + (2000 × 0.00028 / 1000)` = `$0.00126`
- Opus benchmark cost: `(5000 × 0.005 / 1000) + (2000 × 0.025 / 1000)` = `$0.075`
- Savings on this one call: **`$0.0737`**

That's a ~60× gap on a single routine prompt. Run 1,000 such prompts in a month and the user has saved ~$74. Run 10,000 and the display shows ~$740 saved. The number **has no ceiling** and grows in direct proportion to usage — which is exactly the psychological hook the product needs.

**Edge cases:**

- **User routes to Opus itself.** `savings_thisCall` = 0. That's correct — they chose the flagship, there's no counterfactual savings. Display stays stable; doesn't decrease.
- **User routes to a model more expensive than Opus** (unlikely but possible with future models). `savings_thisCall` could go negative for that call. **Rule: clamp per-call savings to a minimum of 0.** Never let the cumulative total decrease. This is framed honestly — we show savings, not losses; when there are none, we show zero.
- **Benchmark price changes via Smart Brain Update.** Because we store per-model cumulative token counts rather than a frozen dollar total (see 8.5), the entire savings number live-recalculates against the new benchmark on next launch. No migration needed.

---

#### 8.5 Data Model

The tracker stores **per-model cumulative token counts**, not pre-calculated dollar totals. This lets the savings number recalculate correctly whenever model pricing or the benchmark changes via a Smart Brain Update.

```dart
/// Persisted to SharedPreferences as JSON.
@immutable
class SavingsModel {
  /// Key: modelId (e.g. "deepseek-chat"). Value: cumulative usage for that model.
  final Map<String, ModelUsage> usageByModel;

  /// Timestamp of first-ever successful API call. Used for "saved per month" rate display.
  final DateTime? firstUsageAt;

  const SavingsModel({required this.usageByModel, this.firstUsageAt});
}

@immutable
class ModelUsage {
  final String modelId;
  final int cumulativeInputTokens;
  final int cumulativeOutputTokens;
  final int callCount;

  const ModelUsage({
    required this.modelId,
    required this.cumulativeInputTokens,
    required this.cumulativeOutputTokens,
    required this.callCount,
  });
}

/// Computed derived value — NOT persisted. Recalculated on every read from
/// the current model_profiles.json + the stored per-model token counts.
@immutable
class SavingsSnapshot {
  final double totalActualCost;       // Sum of what the user actually paid
  final double totalBenchmarkCost;    // Sum of what Opus would have charged
  final double totalSaved;            // benchmark − actual, clamped to ≥ 0
  final int totalCalls;
  final int totalInputTokens;
  final int totalOutputTokens;
  final double savingsMultiple;       // totalBenchmarkCost / totalActualCost (e.g. 47.3x)

  const SavingsSnapshot({...});
}
```

---

#### 8.6 Widget Behavior

The `SavingsTrackerWidget` lives in the sidebar footer and must feel premium:

- **Primary display:** `"You've saved $142.37"` — large, bold, with a subtle count-up animation when the value increases after a new API call.
- **Secondary line (smaller, muted):** `"47× cheaper than Claude Opus 4.6"` — shows the savings multiple, reinforcing *why* the number is so large.
- **Tertiary line (optional, smaller still):** `"That's ~7 months of Claude Pro ✨"` — a fun translation into subscription-months by dividing `totalSaved / $20`. This preserves the product.md psychological anchor without using the flawed flat-subscription math for the real calculation. Show only when `totalSaved >= $20`.
- **Tap target:** Tapping the widget opens a modal with transparent breakdown: per-model token totals, actual cost paid per model, benchmark cost per model, and a one-line explanation — *"We compare every prompt you send to what it would have cost on Claude Opus 4.6 ($5/$25 per 1M tokens), the industry's premium flagship."*

Transparency is mandatory. The number is honest because the math is visible. A user who opens the breakdown and audits the numbers should find them exactly correct.

---

#### 8.7 Deliverables

1. `SavingsModel` and `ModelUsage` — data classes as specified in Section 8.5. Serialized to `SharedPreferences` as JSON.
2. `SavingsSnapshot` — computed/derived class returned by `SavingsProvider`. Not persisted.
3. `SavingsRepository` — reads/writes the `SavingsModel` to `SharedPreferences`. Exposes: `recordCall(modelId, inputTokens, outputTokens)`, `loadSnapshot()`, `clear()` (for testing / settings "reset" option).
4. `SavingsProvider` — subscribes to every successful `ApiResponse` from `ApiClientService`. For each response: read `inputTokens`/`outputTokens` from the exact API JSON fields (Section 8.2), call `SavingsRepository.recordCall()`, recompute `SavingsSnapshot` from current pricing, emit state.
5. `SavingsCalculator` — pure utility class that computes `SavingsSnapshot` from `(SavingsModel, List<ModelProfile>, benchmark)`. Fully deterministic, no side effects, easy to unit test.
6. `SavingsTrackerWidget` — sidebar footer widget per Section 8.6. Premium feel with animated counter.
7. `SavingsBreakdownModal` — the transparent per-model breakdown shown on tap.
8. **Benchmark sourcing logic** — reads the `isBenchmark: true` entry from `model_profiles.json`. If missing or malformed, falls back to the hard-coded constant `PricingBenchmark(inputPer1k: 0.005, outputPer1k: 0.025, displayName: 'Claude Opus 4.6')`.
9. **Per-call clamping** — `max(0, benchmarkCost - actualCost)` on every recorded call. The cumulative savings number never decreases.

**Unit test requirements (mandatory):**

- Given a mocked DeepSeek response with `usage.prompt_tokens: 5000, usage.completion_tokens: 2000`, the calculator returns `savings ≈ $0.0737` (within floating-point tolerance).
- Given 1,000 such identical calls, cumulative savings is approximately `$73.74` — verifying linear scaling.
- Given a response routed to Opus itself (`claude-opus-4-6`), per-call savings is exactly `$0.00` and cumulative savings does not decrease.
- Given a hypothetical response to a model more expensive than Opus, per-call savings clamps to `$0.00` (not negative).
- Given the benchmark entry is missing from `model_profiles.json`, the calculator uses the hard-coded Opus 4.6 fallback and still returns a correct positive savings number.
- Given a Smart Brain Update changes Opus's input cost from `$0.005` to `$0.006` per 1K, the same stored `SavingsModel` now yields a **larger** `SavingsSnapshot.totalSaved` — confirming that stored token counts (not frozen dollar totals) let pricing updates flow through correctly.
- Verify the math uses the exact `usage.prompt_tokens` and `usage.completion_tokens` from the API JSON — **not** the local `estimateTokens()` heuristic.

---

### Phase 9: Settings & Polish

**Goal:** Settings screen, keyboard shortcuts, final UX polish.

**Deliverables:**

1. `SettingsScreen` — default model selection, use-case re-selection, theme toggle (dark/light), skills shortcut, API key management, about section, **license status section with "Enter / Update License Key" button that opens the `LicenseKeyInputScreen` from Phase 2**, logout.
2. Keyboard shortcuts (Section 4.3).
3. Window title: "Briluxforge" + current conversation title.
4. Loading/empty/error states for every screen — **no blank screens ever.**
5. Graceful offline behavior: if no network, show clear message. Don't crash. Key storage + chat history work offline.
6. **Video tutorial link placeholders** in onboarding and help sections. I will provide URLs.

---

### Phase 10: Build, Obfuscate, Package

**Goal:** Distributable binaries for Windows, macOS, and Linux.

**Deliverables:**

1. Release build commands with obfuscation (Section 7.4).
2. `.gitignore` updated (debug info, build artifacts, keys, `.g.dart`, Firebase config files).
3. App icon and metadata configured per platform.
4. Smoke test: install on clean machine → sign up → onboarding → add key → enable skill → send prompt → verify delegation + markdown + skills + savings all work.

---

## Appendix A: Supported API Providers (MVP)

| Provider | Auth Header | Streaming | Verify Endpoint |
|---|---|---|---|
| DeepSeek | `Authorization: Bearer <key>` | SSE (OpenAI-compatible) | `GET /models` |
| Google Gemini | `x-goog-api-key: <key>` | SSE | `GET /models` |
| Anthropic Claude | `x-api-key: <key>` | SSE (Messages API) | `POST /messages` (tiny prompt) |
| OpenAI | `Authorization: Bearer <key>` | SSE | `GET /models` |
| Groq | `Authorization: Bearer <key>` | SSE (OpenAI-compatible) | `GET /models` |

---

## Appendix B: Prohibited Features (Do Not Build)

- ❌ GitHub integration
- ❌ Knowledge graph / Obsidian / Graphify
- ❌ Web app version
- ❌ Mobile version
- ❌ Backend server for prompt processing (Firebase Auth + Gumroad are managed services, not our backend)
- ❌ Telemetry, analytics, or crash reporting
- ❌ Plugin/extension API for third-party developers
- ❌ Image generation, TTS, or STT
- ❌ File upload to AI providers
- ❌ Auto-update mechanism (manual distribution for MVP)
- ❌ Social login (Google/Apple/GitHub OAuth) — email/password only for MVP
- ❌ Multi-device sync of chat history or settings
- ❌ Collaborative/shared conversations

---

## Appendix C: Discrepancy Resolution Log (product.md ↔ claude.md)

| # | product.md Says | v1.0 claude.md Had | Resolution in v2.0 |
|---|---|---|---|
| 1 | "Skills Integration — Supports skills similar to Claude's skill system" | Completely missing | Added Section 5 (Skills System), feature module, Drift table, Phase 7 |
| 2 | Pricing: $9/mo, $59/yr, $99 lifetime | Not mentioned | Added to Section 3.3 with pricing table |
| 3 | "Screenshot Walkthroughs — Step-by-step image guides" | Not mentioned | Added placeholder containers in Phase 3 |
| 4 | "Video Tutorials — Screen-recorded guides" | Vague link placeholder | Explicit video link containers in Phase 2 + Phase 9 |
| 5 | "Founder-led customer support (first 4 weeks)" | Not mentioned | Operational concern, not code. No action needed. |
| 6 | "zero backend prompt processing" | Absolute "no backend of any kind" | Rewritten as ZERO-PROMPT-BACKEND LAW; Firebase + Gumroad permitted |
| 7 | Needs accounts for licensing | "User accounts" was in Prohibited list | Removed from prohibited. Auth is now Phase 2 |
| 8 | Premium UI is critical competitive advantage | Markdown rendering was Prohibited | Removed from prohibited. Now a core requirement (Section 4.5) |
| 9 | Design field in tech stack is blank | No design system guidance | Comprehensive Section 4 + Premium UX as Absolute Law #6 |
| 10 | "Smart Brain Updates" = core competitive feature | Only mentioned model_profiles.json | Added Section 6.6 with update mechanism |
| 11 | "displays exactly how much that would have cost on a single subscription like Claude Pro" | v2.1 used $20/month flat subscription baseline | **Intentional architectural evolution in v2.2.** The flat-subscription baseline was mathematically broken — it capped savings at $20/month and punished power users by showing "negative savings" once actual API spend exceeded the subscription cost, directly contradicting the product's core pitch. Replaced with a per-token counterfactual baseline against Claude Opus 4.6 ($5/$25 per 1M input/output tokens). Savings now scale linearly and unboundedly with usage. A secondary "X months of Claude Pro" line preserves the original psychological hook using `totalSaved / $20` without letting the flawed math drive the primary number. See Phase 8 in Section 9 for full logic. |

---

## Appendix D: Quick Reference Commands

```bash
# Create project
flutter create --platforms=windows,macos,linux briluxforge

# Run code generation (after any provider, model, or Drift table change)
dart run build_runner build --delete-conflicting-outputs

# Run in debug
flutter run -d windows   # or macos, linux

# Run tests
flutter test

# Release build (always with obfuscation)
flutter build windows --release --obfuscate --split-debug-info=build/debug-info/
flutter build macos --release --obfuscate --split-debug-info=build/debug-info/
flutter build linux --release --obfuscate --split-debug-info=build/debug-info/
```

---

# Briluxforge — Product Document
## What It Is
Briluxforge delivers the same polished, premium experience you'd expect from a single AI subscription — but instead of locking you into one model, it runs on multiple APIs simultaneously, each doing what it does best.
That means you get the simplicity and feel of Claude Pro, the versatility of every major AI provider, and a fraction of the cost — because cheap APIs like DeepSeek and Gemini give you far more tokens per dollar than any single subscription. You're not tied to one provider's pricing, one model's strengths, or one company's roadmap. If a model starts underperforming, you're not stuck with it. You swap it out. Briluxforge keeps working.
Users paste their own API keys. Briluxforge handles the rest — automatically routing each task to the right model, with zero setup and no technical knowledge required.
Briluxforge is **not** an IDE, **not** a token reseller, **not** open source, and **not** a hosted service. Everything runs locally on the user's device. We do not process prompts on our backend.
## Tech Stack
| Layer | Tool |
|---|---|
| UI Framework | Flutter |
| State Management | Riverpod |
| Design |  |
| Secure Storage | Platform-native (Keychain / Credential Manager / libsecret) |
| Build Assistance | Claude Pro, Gemini Pro |
## Platform
 * **MVP:** Desktop only (Windows, macOS, Linux via Flutter)
 * **Post-validation:** Mobile (Android first, then iOS)
 * **Future:** Web app
 * Philosophy: **User-first**, not mobile-first or desktop-first
## Features
### Core
 * **Bring Your Own API** — Users paste their own API keys; Briluxforge does the rest
 * **Automatic Task Delegation** — A local delegation engine runs on the user's device and automatically routes each task to the most suitable model based on what the task demands (e.g. high context → Gemini, coding/reasoning → DeepSeek). The engine makes this decision locally without sending anything to an external service first. If the local engine cannot confidently determine the best route, it falls back to the user's most capable connected API to make the delegation decision instead. If that also fails, the task is sent to a pre-set default API (e.g. DeepSeek or Gemini) as a final fallback. This three-layer fallback chain means delegation never silently breaks
 * **Manual Override** — Users can override any delegation decision and choose their preferred model at any time
 * **Token Savings Tracker** — Tracks total tokens used across all APIs and displays exactly how much that would have cost on a single subscription like Claude Pro. It's a running, always-visible proof of value — the longer you use Briluxforge, the bigger the number gets, and the harder it becomes to justify going back. Same psychological hook as Honey (showed you money saved at checkout) or a loyalty stamp card — except the reward compounds every single session
### Onboarding & Guidance
 * **API Buying Guide** — Recommends which APIs to buy based on use case before the user spends a cent
 * **Video Tutorials** — Screen-recorded guides (by the founder) showing how to sign up, purchase tokens, copy, and paste API keys into Briluxforge
 * **Screenshot Walkthroughs** — Step-by-step image guides as a companion to video tutorials
### API Key Management
 * **API Key Verification** — On entry, each key is tested live; a green checkmark confirms connection (e.g. *"DeepSeek API connected"*); on failure, specific, actionable debugging advice is shown — not just a generic error
 * **Secure Local Storage** — Keys are stored using platform-native secure storage; no external service, works offline, hardware-grade security when available
### Intelligence & Updates
 * **Smart Brain Updates** — Briluxforge is regularly updated with the latest information on every supported API: which models are available, how each model is currently performing, what each is best suited for right now, token-per-dollar value, and any changes in reliability or capability. This is a core competitive feature — not just maintenance. It means Briluxforge's delegation decisions stay accurate over time as the AI landscape shifts, new models drop, and older ones degrade. Users never have to track this themselves; Briluxforge stays current so they don't have to
 * **Skills Integration** — Supports skills similar to Claude's skill system, integrated directly into the chat interface
## Security & Privacy Practices
 * API keys are **never hardcoded**, never bundled with the app, and never present in source code
 * Keys are stored exclusively using **platform-native secure storage** (macOS Keychain, Windows Credential Manager, Linux libsecret)
 * **No backend processing** — prompts are sent directly from the user's device to their chosen API provider
 * Briluxforge **never sees, touches, or transmits** the user's API keys or prompts
 * Hardware-grade encryption leveraged where available
 * Full offline functionality for key storage
## What Briluxforge Is Not
 * ❌ Not a token reseller — we do not sell API credits
 * ❌ Not an IDE — not competing with Cursor, VS Code, or Zed
 * ❌ Not open source — the smart delegation engine and UI are proprietary
 * ❌ Not a hosted service — zero backend prompt processing
## Pricing
| Plan | Price |
|---|---|
| Monthly | $9 / month |
| Annual | $59 / year |
| Lifetime | $99 one-time |
## MVP Scope
 * Desktop app only
 * Core chat interface with automatic delegation
 * API key entry, verification, and secure storage
 * Onboarding guide + video tutorials
 * Token savings tracker
 * Founder-led customer support (first 4 weeks)
## Budget Constraints (MVP)
 * Total available: ~$20–$25
 * ~$3–$5 allocated for API key testing
 * Remaining for domain + distribution hosting
 * Zero paid marketing — organic only
## Prohibited for V1 (Out of Scope)
 * **GitHub Integration:** No auto-pushing code, pull requests, or repository management.
 * **Graphify / Obsidian Integration:** No building or integrating local knowledge graph routing.
 * **Web App:** No building a web version or web hosting for the application itself.

---

*End of document. Sonnet: if you are reading this, your scope is defined entirely within these pages. Build only what is described here. Build it well.*
