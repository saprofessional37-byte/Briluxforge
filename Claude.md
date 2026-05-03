# PHASE_13.MD — Delegation Recalibration & Admin Brain Management

> **Document Version:** 13.0
> **Parent Document:** `CLAUDE.MD` v2.2-MVP (this document extends, never overrides)
> **Companion Documents:** `CLAUDE_PHASE_11.MD` (OTA), `PHASE_12.MD` (Premium UX)
> **Target Executor:** Claude Sonnet 4.6 (Junior Coder)
> **Authored By:** Staff Architect / Lead Engineer
> **Status:** MANDATORY before public beta
> **Last Updated:** 2026-05-02

---

## 13.0 Preamble — Why This Phase Exists

The MVP routes. The MVP polishes. The MVP signs and ships. The MVP **routes wrong**, **looks wrong on its primary action surface**, **forces a broken scrollbar on the most important onboarding decision**, and **gives the maintainer no safe way to update the brain it depends on.**

These are not five unrelated bugs. They are one architectural pattern: every system the MVP shipped that should be *governable* is instead *frozen*. The keyword matrix is frozen at the values one engineer typed during Phase 4. The brain JSON is frozen at whatever was bundled into the last binary release until Phase 11 OTA pushes a new one — and Phase 11 has no authoring tool, so brain edits today are a manual JSON-typing exercise that has no validation gate before signing. The light theme is frozen as a half-implemented toggle that nobody has audited for contrast in five releases. The button is frozen as a `Stack`-with-a-Positioned-slab whose only job is to add a "lit edge" effect that, in practice, draws a hard horizontal line.

Phase 13 closes the governance gap. It does not add features. It does not expand MVP scope. It establishes the **operational tooling and recalibrated logic** the MVP needs in order to evolve safely after launch.

Every defect below is diagnosed with an architectural root cause and a concrete fix. No defect is treated as cosmetic. No defect is treated as "just configuration." Each one is a structural failure mode that the next ten Smart Brain pushes will compound into a support nightmare unless we fix it at the source.

**Scope discipline:** This phase does not introduce new user-facing features. The Admin Brain Management surface is **admin-only, gated, and invisible to non-admin users**. It is operational infrastructure, not product. If you catch yourself adding a "tip of the day" widget or an in-app feedback form because you happen to be in the admin namespace, stop.

---

## 13.1 Reaffirmation of Absolute Laws

All six Absolute Laws from `CLAUDE.MD` Section 1.2 apply to this phase without modification. The Phase 11 SIGNED-OR-DIE LAW also remains binding on every byte the brain editor produces. The four most relevant to this phase, restated because they are the most likely to be tested:

1. **ZERO-PROMPT-BACKEND LAW** — The Delegation Inspector's decision log stores **prompt hashes only**, never raw prompt text. The brain editor CLI runs on the maintainer's local machine and never transmits anything anywhere. The admin gate authenticates locally against a value held in `flutter_secure_storage`; no admin credentials cross a network boundary.
2. **LOCAL-FIRST LAW** — The decision log is an in-memory ring buffer with optional flush to a local SQLite table. The brain editor reads and writes local files. No telemetry. No analytics. No "send to support" affordance.
3. **SIGNED-OR-DIE LAW** (`CLAUDE_PHASE_11.MD` §1.2) — Every brain payload the editor emits is Ed25519-signed before it can be staged for upload. An unsigned brain.json never leaves the editor's working directory. The runtime hot-sync verification gate from Phase 11 §6.7 is unchanged and still rejects anything unsigned.
4. **SINGLE-FILE OUTPUT LAW** — Every Dart file produced for Phase 13 is delivered first-import to last-closing-brace. No partial diffs. No "add this block." The CLI tool ships as a single self-contained `bin/brain_editor.dart`, not as a fragmented multi-package layout.
5. **MVP-SCOPE LAW** — Admin tooling is the most seductive place to scope-creep into a full ops dashboard. There is no "schedule a brain release for Tuesday." There is no "A/B test two model profiles." There is no "rollback to v42 in one click." The CLI signs a JSON file. The inspector reads the engine's last 100 decisions. That is the entire surface area.

---

## 13.2 Syntax Enforcement — Non-Negotiable for This Phase

Sections 2.2 and 2.3 of `CLAUDE.MD` and Section 12.2 of `PHASE_12.MD` are **fully in force.** Restated for the files this phase will touch:

- **All state is Riverpod `@riverpod` codegen.** The new `decisionLogProvider`, `adminGateProvider`, and `delegationInspectorProvider` use annotation-based syntax with `part '*.g.dart';`. The `settingsNotifierProvider` is touched in this phase to remove the theme-mode field; the rewrite must remain `@riverpod`-annotated. Mixing legacy syntax during the rewrite is a critical failure.
- **All state classes are `@immutable`.** The `DelegationDecisionLogEntry`, `AdminGateState`, `BrainValidationReport`, and `BrainEditorSession` value objects use `const` constructors, final fields, and `copyWith`. The recalibrated `KeywordCategory` enum and `WeightedKeyword` class are likewise `@immutable`.
- **Named parameters with `required`** on every public widget and service constructor.
- **Pure Dart Material 3 widget composition** for every UI surface this phase introduces. The Delegation Inspector screen is built from `ConstrainedBox`, `ListView.builder`, `Card`, `FilledButton`, and the existing Phase 12 primitives (`AppCard`, `AppButton`, `AppDialog`). No new third-party UI packages.
- **No new dependencies.** This phase ships with the dependencies already locked in `CLAUDE.MD` §2.1 plus the four added in `CLAUDE_PHASE_11.MD` §2.1 (`desktop_updater`, `cryptography`, `package_info_plus`, `crypto`). The brain editor CLI uses `cryptography` for Ed25519 signing — identical to the runtime verifier — so admin-side signing and runtime verification share a single signature algorithm definition. Any other package request must be approved in writing.
- **`const` everywhere it compiles.** Same as `PHASE_12.MD` §12.2.
- **Generated files:** Run `dart run build_runner build --delete-conflicting-outputs` after every `@riverpod` provider or `json_serializable` model change.

If a file currently in legacy syntax must be touched during a Phase 13 rewrite, **flag and fix in the same response.** Legacy syntax does not survive a Phase 13 edit pass.

---

## 13.3 Defect #1 — Delegation Engine Bias

### 13.3.1 Architectural Diagnosis

The current engine routes more than 80% of mixed prompts to DeepSeek or Gemini Flash. This is not because those models are objectively best for those prompts — it is because of three compounding implementation defects:

1. **Vocabulary mismatch between matrix categories and model strengths.** `KeywordMatrix` defines categories `coding`, `reasoning`, `math`, `writing`, `summarization`, `long_context`, `general`. `model_profiles.json` defines strengths using a partially overlapping but distinct vocabulary: `analysis`, `nuance`, `instruction_following`, `debugging`, `speed`. A model whose strengths are listed only as `["writing", "analysis", "nuance", "instruction_following"]` (the Claude Sonnet entry) cannot win for `analysis`, `nuance`, or `instruction_following` because **none of those are scoreable categories.** The matrix has no keywords that resolve to `analysis`. So Claude Sonnet's three of four strengths are unreachable from a user prompt. It can only win when `writing` clears the threshold, which requires explicit words like "essay" or "draft." Most prompts that should go to Claude — *"explain the tradeoffs between X and Y," "review this and tell me what's wrong"* — go to DeepSeek instead because they happen to contain `explain` or `analyze`, and the matrix maps both of those into `reasoning`, where DeepSeek wins.
2. **Unnormalized category sums.** `coding` has 19 keywords with a maximum-possible-match score of ~13.4. `summarization` has 6 keywords with a maximum of ~4.7. The threshold check at 0.70 is applied to the **raw sum of matched weights**, not to a normalized fraction. A prompt that matches three coding keywords scores ~2.4 — well above 0.70. A prompt that matches every summarization keyword scores 4.7 but had to clear a much higher relative bar to do so. The matrix is fundamentally biased toward whichever category has the most keywords listed, regardless of how well the prompt actually fits.
3. **Strengths are matched by exact string equality, with no synonym set.** A model lists `coding` and matches the `coding` category. A model lists `code` (singular) and matches nothing. A model lists `code_generation` and matches nothing. There is no canonical taxonomy — the JSON file's authors and the matrix's author have to telepathically agree on the spelling.

The combined effect is that every prompt routes to whichever model's strengths happen to spell the dominant category exactly. DeepSeek lists `coding` and wins. Gemini lists `long_context` and wins (when triggered by token count, not keywords). Claude Sonnet lists three things that aren't in the matrix at all. GPT-4o, Llama, and any other model the user has connected fall through silently because their strengths often live in `instruction_following`, `multimodal`, `tool_use`, `low_latency`, `multilingual` — none of which are categories.

### 13.3.2 Strategy — Canonical Taxonomy + Normalized Scoring + Tier-Aware Tiebreak

The fix is three orthogonal corrections:

**A. One canonical category taxonomy.** Define the full set of routable categories once, in a single `enum`, and use it as the single source of truth for both the keyword matrix's keys and the `strengths` arrays in every brain entry. The brain validator (Section 13.4.6) rejects any model whose `strengths` contain a string outside this enum. This eliminates vocabulary drift forever.

The Phase 13 canonical category set is:

| Category | Triggers When | Best-Suited Models (typical) |
|---|---|---|
| `coding` | imperative coding verbs, language names | DeepSeek, GPT-4o |
| `debugging` | "debug", "stack trace", "error in", "fix this" | DeepSeek, Claude Sonnet |
| `math_reasoning` | calculation, equation, proof, derivation | DeepSeek, GPT-4o, Claude Sonnet |
| `analysis` | "compare", "evaluate", "tradeoff", "review" | Claude Sonnet, GPT-4o |
| `creative_writing` | story, poem, fiction, character | Claude Sonnet, GPT-4o |
| `professional_writing` | email, memo, blog post, doc | Claude Sonnet, GPT-4o |
| `summarization` | TLDR, condense, key points | Gemini Flash, Claude Sonnet |
| `instruction_following` | multi-step, "follow exactly", structured output | Claude Sonnet, GPT-4o |
| `long_context` | token-count-driven, not keyword-driven | Gemini Flash, Claude Sonnet |
| `low_latency` | "quick", "fast", "right now", short prompt | Llama (Groq), Gemini Flash |
| `high_volume_cheap` | low-stakes routine prompts | DeepSeek, Gemini Flash |
| `multilingual` | non-English content detection | GPT-4o, Gemini Flash |
| `safety_critical` | medical, legal, financial advice contexts | Claude Sonnet |
| `general` | fallback when nothing else hits threshold | user's default |

**B. Normalized confidence scoring.** Every category contributes a `normalizedScore = matchedWeightSum / maxPossibleWeightSum` in `[0.0, 1.0]`. The matrix-vs-prompt scoring step computes this fraction per category. The selection threshold is checked against the normalized score, not the raw sum. A category with 6 keywords and a category with 19 keywords are now on the same scale.

**C. Tier-aware tiebreak with cost discipline.** When the top two normalized category scores differ by less than `0.10`, the engine inspects the tier of each candidate model:

- For categories `safety_critical`, `analysis`, `instruction_following`, `creative_writing` → prefer `tier: premium`.
- For categories `coding`, `debugging`, `summarization`, `math_reasoning`, `general` → prefer `tier: workhorse`.
- For category `low_latency` → prefer the model with the lowest published latency hint (new field; default 999ms; Groq Llama wins in practice).
- For category `high_volume_cheap` → prefer the model with the lowest `costPer1kInput + costPer1kOutput` sum.

The tiebreak runs **after** the normalized score check, never before. A workhorse model that wins on raw fit beats a premium model that ties — premium-tier preference is the tiebreaker, not the seed.

**D. Connected-only filter, before scoring.** Phase 11 §7.4 already filters kill-switched models. The recalibrated engine extends this: every candidate model must additionally have a `verified, connected` API key for its provider. Models without a verified key are filtered **before** scoring runs. If only one model is connected, the engine returns it directly with `confidence = 1.0` and `layerUsed = 1` — no scoring, no dialog. This is unchanged from the original spec but explicitly preserved here.

### 13.3.3 Specification — Recalibrated Files

The recalibrated engine ships across three files. The split is identical to today; only the bodies change:

1. **`lib/features/delegation/data/keyword_matrix.dart`** — recalibrated weighted matrix using the canonical 14-category taxonomy. Every category has a coverage minimum (≥ 8 keywords) so no category is structurally underweight. Weights are tightened to a `[0.4, 1.0]` range with a new convention: `1.0` means "this keyword by itself is sufficient" (rare; reserved for unambiguous category markers like `TLDR`, `integral`, `compile error`); `0.4` means "weak signal, only useful when stacked with others." The previous `0.5–0.9` band was too narrow to differentiate strong from weak markers.
2. **`lib/features/delegation/data/delegation_engine.dart`** — recalibrated scoring using the normalize-then-tiebreak algorithm. The public API (`delegate(String prompt)`) is unchanged; callers do not need to update. The `DelegationResult` class gains two new fields: `normalizedScores: Map<KeywordCategory, double>` and `tieBreakerApplied: bool`. These exist primarily to feed the Delegation Inspector (Section 13.4) but are also surfaced in the existing Phase 12 routing footer.
3. **`assets/brain/model_profiles.json`** — every existing model entry's `strengths` array is rewritten to use canonical category names exclusively. Every model is also given a `latencyHintMs: int` field (used by `low_latency` tiebreak). Every model gains a `descriptionForAdmin: String` field — a one-sentence, non-user-facing rationale for *why* this model is in the brain at all. The schema version is bumped to `2`.

### 13.3.4 Acceptance — How We Know It's Fixed

The recalibration is correct when, on a fresh install with all five MVP providers connected:

- A prompt of *"explain the tradeoffs between Postgres and SQLite for an embedded desktop app"* routes to **Claude Sonnet** (analysis dominates, premium tier).
- A prompt of *"write a Python function that flattens a nested dict"* routes to **DeepSeek** (coding dominates, workhorse tier).
- A prompt of *"summarize this 80,000-token PDF"* routes to **Gemini Flash** (long_context auto-fires, workhorse tier).
- A prompt of *"draft a heartfelt thank-you note to my grandmother"* routes to **Claude Sonnet** (professional_writing + creative_writing tied at premium tier).
- A prompt of *"hey what's 2+2"* routes to **Llama (Groq)** if connected (low_latency dominates short, trivial prompts), else to the user's default.
- A prompt of *"can you check if this contract clause is enforceable"* routes to **Claude Sonnet** with a delegation-failure-dialog warning attached, because `safety_critical` categories always force a confirmation prompt regardless of confidence.

These are the six smoke tests in `test/features/delegation/recalibration_smoke_test.dart`. They must all pass before Phase 13 closes.

---

## 13.4 Defect #2 — Admin Brain Management (Phase 13's Headline Deliverable)

### 13.4.1 Architectural Diagnosis

`CLAUDE_PHASE_11.MD` shipped a complete signed-update transport but no authoring layer. Today, updating the brain looks like this: open `assets/brain/model_profiles.json` in a text editor, hand-edit JSON, save, commit, tag, push, hope the Ed25519 signing step in CI succeeds, hope the runtime parser doesn't reject the edit, hope the `DefaultModelReconciler` doesn't strand 5,000 users on a removed model. Every step in that chain is a place a typo can cause a production incident.

There are two distinct problems disguised as one:

1. **Authoring problem.** I (the maintainer) need a tool that lets me edit the brain without touching JSON syntax directly, validates my edit against the same schema the runtime enforces, and refuses to emit an output until the edit is structurally and semantically valid. Today there is no such tool.
2. **Observability problem.** I need to see how the engine is actually behaving in the field on my own machine, against my own prompts, with my own connected providers — to know whether a candidate brain edit will help or hurt before I sign and ship it. Today the engine's decisions are completely opaque.

These two problems share a substrate (the brain), so they share architectural principles. They do **not** share a delivery surface. The authoring tool is a developer-machine CLI. The observability surface is an in-app screen gated behind admin authentication.

### 13.4.2 Strategy — Two Surfaces, One Substrate

**Surface A: Delegation Inspector (in-app, admin-gated).**

A new screen at `lib/features/admin/presentation/admin_inspector_screen.dart`, reachable only via:

1. The user is signed in with the admin email (a single hardcoded value in `lib/core/constants/app_constants.dart`, `kAdminEmail`).
2. The user has previously entered the admin secret in Settings → "Developer" section. The secret is held in `flutter_secure_storage` under key `admin_secret_v1`. It does not unlock anything by itself; it is paired with the admin email at runtime to compute a SHA-256 hash that matches a hardcoded `kAdminGateHash` constant. This is a **defense-in-depth** measure, not security; the admin binary is not separately distributed and an attacker with source can compute the same hash. The gate exists to prevent accidental discovery by curious users, not to resist a determined attacker.
3. Both checks pass → the inspector menu item appears in Settings. Otherwise it does not exist in the widget tree.

The inspector is **read-only**. It surfaces:

- **Engine state header** — current brain source path (local-override vs bundled-asset), brain schema version, brain content version, total models loaded, total models killed by current manifest.
- **Live preview tester** — a single text input. As the admin types, the engine runs `delegate()` against the input and renders the full `DelegationResult` including all normalized category scores, the winning model, the tiebreak indicator, and the layer used. No prompt is sent to any provider. This is the primary diagnostic tool.
- **Decision log** — the most recent 100 actual `delegate()` calls made during this session, in reverse chronological order. Each entry shows: timestamp, **prompt SHA-256 truncated to 12 chars** (never raw text), winning model, normalized score for the winning category, layer used, tiebreak flag. The log is an in-memory ring buffer (`Queue<DelegationDecisionLogEntry>`); it is **not persisted** by default. A "Flush to local file" button writes the buffer to `<appSupportDir>/Briluxforge/admin/decisions_<isoDate>.jsonl` for offline analysis.
- **Brain diff view** — if a local-override brain is present (Phase 11 §7.2 path 1), shows a per-model diff against the bundled asset (Phase 11 §7.2 path 2). Added models highlighted in `statusSuccessFg`, removed in `statusErrorFg`, repriced in `statusWarnFg`. This lets the admin verify that an OTA brain push actually delivered the expected delta.

**Surface B: Brain Editor CLI (developer machine only).**

A new pure-Dart CLI at `tools/brain_editor/bin/brain_editor.dart`. Run via `dart run tools/brain_editor/bin/brain_editor.dart <command>`. Not shipped in any user binary. Not referenced from any `lib/` import. The `tools/` directory is excluded from `pubspec.yaml`'s asset and source paths.

Commands:

- `validate <path>` — parses the file at `<path>` against the canonical brain schema. Reports every error with line/column when possible. Exit code `0` iff valid. Used both by the maintainer manually and by GitHub Actions in the release workflow before signing.
- `diff <oldPath> <newPath>` — prints a human-readable diff: added models, removed models, strength changes per model, price changes per model, version bump. Used in PR review.
- `bump <path>` — rewrites the file with `version: <existing> + 1`. Refuses if the schema is invalid.
- `sign <path> --key <keyPath>` — produces `<path>.sig` containing the base64-encoded Ed25519 signature of the exact bytes of `<path>`. Refuses if validation fails. Refuses if the key file is not exactly 32 bytes. The key is read into memory, used, and zeroed (`Uint8List.fillRange(0, 32, 0)`) before the function returns. The same key the GitHub Actions workflow uses lives in the maintainer's local `~/.briluxforge/keys/brain_signing_ed25519.key` (gitignored, mode `0600`).
- `release <path>` — composite command: validate → bump → sign → emit `<path>` and `<path>.sig` to `tools/brain_editor/out/<utcTimestamp>/`, ready to upload to GitHub Pages or attach to a GitHub Release. Prints the SHA-256 of the signed payload and the signature's base64 form to stdout for inclusion in the manifest.

The CLI is **the only sanctioned path** for emitting a signed brain payload locally. The GitHub Actions workflow can use the same logic; the workflow simply invokes `dart run tools/brain_editor/bin/brain_editor.dart release …` with the secret-mounted key file.

### 13.4.3 Why This Doesn't Violate Phase 11

Phase 11 §6.7 specifies the **runtime verification contract**: every payload the user's installed app applies must be Ed25519-verified against the bundled public key. That contract is unchanged. The brain editor produces signatures using the **same algorithm and the same key pair** that GitHub Actions uses today. The runtime never knows the difference between a CLI-signed brain and a CI-signed brain because the signature is identical bytes.

What changes is the *authoring* path, not the *verification* path. The runtime still rejects unsigned, malformed, or wrongly-signed payloads. The only thing the editor adds is a pre-signing validation gate so that **broken brains never get signed in the first place.** Defense in depth.

The Delegation Inspector adds zero new network calls, zero new outbound data flows, and zero new persistent storage by default. It reads engine state already in memory and renders it. The optional flush-to-disk path writes to local app-support storage, owned by the user, deletable manually. ZERO-PROMPT-BACKEND remains intact.

### 13.4.4 Specification — Decision Log Ring Buffer

`lib/features/admin/data/decision_log.dart`:

- Single class `DelegationDecisionLog`, a thin wrapper over a `ListQueue<DelegationDecisionLogEntry>` with a hard cap (`kDecisionLogCap = 100`).
- API: `void record(DelegationDecisionLogEntry entry)`, `List<DelegationDecisionLogEntry> snapshot()`, `void clear()`, `Future<File> flushToFile()`.
- `record()` is O(1) amortized: pushes to the end, evicts from the front when over cap.
- `snapshot()` returns an unmodifiable list. Callers cannot mutate the log through the returned reference.
- `flushToFile()` writes JSONL (one JSON object per line) to `<appSupportDir>/Briluxforge/admin/decisions_<utc-iso>.jsonl`. Returns the `File` handle. Refuses to overwrite an existing file (timestamps to second granularity make this rare; on collision the file gets a `_2`, `_3` suffix).
- The class is **not** a Riverpod provider directly. It is exposed via `decisionLogProvider` in `admin_provider.dart` so consumers can `ref.watch` it and rebuild on every new entry.

`DelegationDecisionLogEntry` is `@immutable` with `final` fields:

```dart
final DateTime timestamp;
final String promptHashPrefix; // first 12 hex chars of SHA-256 of prompt
final int promptCharLength;    // length, not content — useful for context analysis
final String winningModelId;
final KeywordCategory winningCategory;
final double normalizedScore;
final int layerUsed; // 1, 2, or 3
final bool tieBreakerApplied;
```

The engine is modified in **exactly one place** to call `decisionLog.record(...)` after every `delegate()` returns a non-null result. The hash is computed on the full prompt; the prompt itself is **discarded** before the entry is constructed. There is no path in the codebase that puts raw prompt text into the log entry.

### 13.4.5 Specification — Admin Gate

`lib/features/admin/data/admin_gate.dart` exposes `AdminGate.unlock({required String email, required String secret})` which:

1. Computes `sha256(email + ":" + secret)` (fixed delimiter, lowercase email).
2. Compares constant-time against `kAdminGateHash` from `app_constants.dart`.
3. On match, writes `email` and `secret` into `flutter_secure_storage` under `admin_email_v1` and `admin_secret_v1` and returns `true`.
4. On mismatch, **does not write anything**, does not increment a counter, does not log the failure with details — just returns `false`. Brute-forcing is not prevented at this layer (it is a four-character-of-entropy gate, not a security boundary); we just don't help the attacker by leaking timing information beyond what `constant-time-compare` allows.

`adminGateProvider` is a `@riverpod` async provider that reads the stored email and secret on app start, recomputes the hash, and emits `AdminGateState.unlocked` or `AdminGateState.locked`. The Settings → Developer section watches this provider; the section renders only when unlocked. The inspector route is registered conditionally in the same provider chain, so the route does not exist in the navigator's table when locked.

### 13.4.6 Specification — Brain Validator (CLI Library)

`tools/brain_editor/lib/brain_validator.dart` defines `BrainValidator.validate(String jsonText)` returning `BrainValidationReport`:

- Parses the JSON.
- Checks top-level: required fields `version: int`, `models: List`, `schemaVersion: int`. `schemaVersion` must equal `2`.
- For each model: required fields `id, provider, displayName, strengths, contextWindow, costPer1kInput, costPer1kOutput, tier, latencyHintMs, descriptionForAdmin`. No extra unknown fields permitted at top level; unknown fields **per-model** are permitted (forward-compat with future Phase N additions). This asymmetry is intentional: schema-level changes need explicit version bumps; model-level extras don't.
- Validates `strengths`: every entry must be a member of the canonical `KeywordCategory` enum's string form. Any unknown string is a fatal error.
- Validates `tier`: must be `"workhorse"`, `"premium"`, or `"specialist"`. (`specialist` is a new tier introduced in this phase for narrow-purpose models like Llama on Groq used for low_latency.)
- Validates uniqueness: no two models share an `id`. No two models for the same `provider` share a `displayName` (prevents UI ambiguity).
- Validates `costPer1kInput >= 0`, `costPer1kOutput >= 0`, `contextWindow > 0`, `latencyHintMs >= 0`.
- Validates exactly **zero or one** model has `isBenchmark: true`. (Phase 8 contract.)
- Returns `BrainValidationReport.ok()` or `BrainValidationReport.errors(List<String> reasons)`.

The same validator is **invoked at runtime** by `model_profiles_loader.dart` when loading either the bundled asset or a local override. The runtime validator is the same code path. A brain that passes the editor cannot fail the runtime — and vice versa, a brain that the runtime would reject will be caught by the editor before signing.

### 13.4.7 Specification — Brain Signer (CLI Library)

`tools/brain_editor/lib/brain_signer.dart` exposes `BrainSigner.sign({required File payload, required File keyFile})`:

- Reads exactly 32 bytes from `keyFile`. Rejects if size differs.
- Reads the full bytes of `payload`.
- Uses `package:cryptography` `Ed25519().sign(...)` to produce a 64-byte signature.
- Writes base64-encoded signature to `<payload>.sig`.
- Zeroes the key buffer in memory before returning.
- Throws `BrainSigningException` on any error. The CLI catches and renders user-facing copy via `ErrorTranslator` (Phase 12 §12.7.3); raw stack traces never reach the terminal.

The CLI does not have a "verify your own signature" step. That's the runtime's job. The editor produces; the runtime verifies. Splitting concerns prevents a signing bug from being silently masked by a self-verification pass.

### 13.4.8 Acceptance — How We Know It Works

The admin tooling is correct when:

1. A non-admin user sees zero references to "admin," "developer," or "inspector" anywhere in the app — Settings, command palette, keyboard shortcuts, route table, build artifacts. Strings are absent from the binary's `.rodata` for non-admin builds. (Achieved by gating the strings behind `kReleaseMode` checks in tandem with the `adminGateProvider`.)
2. With admin gate unlocked, Settings → Developer reveals the "Open Delegation Inspector" entry, and tapping it opens the inspector screen.
3. The inspector's live preview tester renders the recalibrated engine's decision (winning model + normalized scores) within 50ms of the last keystroke for prompts up to 10,000 chars. (Re-uses the existing 5ms per-call budget × debounce.)
4. The decision log fills with real entries during normal app use (sending chat messages produces log records).
5. Running `dart run tools/brain_editor/bin/brain_editor.dart validate assets/brain/model_profiles.json` exits `0` on the recalibrated brain and exits non-zero with a clear error message on a deliberately corrupted brain.
6. Running `… release path/to/brain.json --key ~/.briluxforge/keys/brain_signing_ed25519.key` produces a signed payload that the runtime hot-sync accepts. Verified by manually staging the payload at the local-override path on a development build and observing successful application via the inspector's brain source header.

---

## 13.5 Defect #3 — Button Line Bug

### 13.5.1 Architectural Diagnosis

`PHASE_12.MD` §12.4.3 specified the primary button as a `Stack` with the `FilledButton` on top and a 1px `Container` at the top edge "inside the `ClipRRect`" to simulate a lit edge. The implementation produced a **visible horizontal line** at the top of every primary button across the app.

The root cause is a layout misunderstanding, not a styling bug: a 1px-tall `Container` at `top: 0` of a `Stack` clipped to a rounded rectangle does not render as a curved highlight. It renders as a perfectly horizontal 1px slab whose left and right pixels sit *on the curve* of the corner radius. At 12% white opacity over a saturated muted-purple fill, that slab reads as a hard horizontal line — the exact opposite of the intended "soft gloss." The corners look notched. The overall impression is a button with a printed sticker stuck across its top.

There is no clipping fix that turns a horizontal slab into a curved gloss. The geometry is wrong. The architectural fix is to replace the slab with a **vertical gradient inside the button's child stack**, anchored to the top, fading to transparent over ~40% of the button's height. A gradient by definition follows the rounded clip path because it is painted as a fill, not as a positioned subwidget. No corner artifacts. No edge line.

### 13.5.2 Strategy — Gradient-Based Highlight, No `Stack`

Rewrite `lib/core/widgets/app_button.dart` so that the primary variant:

1. Uses a single `FilledButton` with `backgroundColor: Colors.transparent` and `foregroundColor: AppColors.textPrimary(true)`.
2. Wraps the button's `child` (the label) in a `DecoratedBox` whose `decoration: BoxDecoration` carries: `color: brandPrimaryMuted`, `borderRadius: AppRadii.sm`, and a `gradient: LinearGradient` from `Colors.white.withOpacity(0.06)` at `Alignment.topCenter` to `Colors.transparent` at `Alignment(0, -0.2)`. (The negative-y stop ends the gradient ~40% down the button.)
3. Wraps the whole assembly in `AppElevation.subtle`'s `BoxShadow` for tactile depth.

The `Stack` is gone. The Positioned 1px Container is gone. The `ClipRRect` wrestling is gone. There is one `FilledButton` with one `DecoratedBox` child. The gradient paints inside the rounded clip naturally because it is a property of the same decoration that defines the radius. No corner artifacts are possible.

The secondary and ghost variants are unchanged from `PHASE_12.MD` §12.4.3 — they never had the highlight in the first place.

### 13.5.3 Acceptance

The button is correct when, at any window scale from 900×600 to 4K:

- Zero horizontal lines visible at the top edge of any primary button.
- A subtle top-to-bottom luminance gradient is visible only on inspection — the casual impression is "solid muted purple with a hint of warmth at the top."
- Corner radii read as continuous curves, not as notched/cropped corners.
- `dart analyze` reports zero issues on `app_button.dart`.

---

## 13.6 Defect #4 — Light Theme Removal

### 13.6.1 Architectural Diagnosis

`CLAUDE.MD` §4.2 specified dark-as-primary, light-as-secondary themes. Phase 9.5 §B.5 added a `SegmentedButton<ThemeMode>` to Settings with three segments. The light theme has been shipped through five releases without a contrast audit pass, without proper input-fill calibration in light mode, and without verifying the Phase 12 design tokens (`AppColors`, `AppTokens`) work end-to-end in light. Every screen will need a separate review before light is supportable. That review is not Phase 13's scope.

The simplest correct posture is to **lock the app to dark mode for now**, removing the light toggle from the user surface entirely while preserving the underlying `isDark`-parameterized theme infrastructure for trivial reintroduction later.

### 13.6.2 Strategy — Strip the Toggle, Keep the Plumbing

Three files change. No others should be touched.

1. **`lib/app.dart`** — `MaterialApp` is configured with `theme: AppTheme.darkTheme` and **no** `darkTheme` field, **no** `themeMode` field. The MaterialApp now has exactly one theme, period.
2. **`lib/core/theme/app_theme.dart`** — the `lightTheme` static getter is removed. The class exposes only `darkTheme`. The `app_colors.dart` `isDark` parameters are **retained** to minimize churn and keep the door open for a one-line reintroduction of light when we're ready. The cost of keeping `isDark` parameters when only `true` is ever passed is nil; the cost of stripping them is a multi-screen audit we don't need right now.
3. **`lib/features/settings/presentation/settings_screen.dart`** — the entire theme toggle row is removed. No `SegmentedButton<ThemeMode>`. No "Theme" section header. The Settings screen jumps from "Default Model" directly to "Skills" with no gap, no placeholder, no "Coming Soon" copy.
4. **`lib/features/settings/providers/settings_provider.dart`** — `SettingsState`'s `themeMode` field is deprecated (annotated `@Deprecated`) and frozen at `ThemeMode.dark`. The `setThemeMode` method becomes a no-op that logs a single warning at debug level (`AppLogger.w('Settings', 'setThemeMode called but theme is locked to dark in Phase 13')`). The persisted SharedPreferences key remains readable for backward compatibility — old installs upgrading to this build won't crash on legacy stored values.

The brand grain remaining: `isDark` plumbing through `app_colors.dart` stays alive. When light returns in a future phase, the work is: re-export `lightTheme`, restore the toggle row, restore `setThemeMode`. The `AppColors` tokens already accept `isDark`. Approximately 30 lines of work. Phase 13 leaves this door open intentionally.

### 13.6.3 Acceptance

Light theme is gone when:

- Launching the app, no system theme change ever flips the UI.
- Settings has no theme-related controls visible.
- `grep -rn "ThemeMode.light\|themeMode:\|lightTheme" lib/features/` returns zero matches.
- `grep -rn "lightTheme" lib/` returns zero matches outside of comments documenting the deprecation.
- A build flag flip (re-export `lightTheme`, restore the toggle) takes under 60 seconds to re-enable the feature in the future.

---

## 13.7 Defect #5 — Onboarding Use-Case Overflow & Broken Scroll

### 13.7.1 Architectural Diagnosis

The `UseCaseSelectionScreen` rendered five vertical cards inside a `Column` inside a `SingleChildScrollView` inside an unbounded vertical parent. Two compounding failures:

1. **Layout shape mismatch.** Phase 12 specced 96px illustrations + 16px gap + 16px title + 4px gap + 13px description per card, centered. Stacked vertically, five such cards measure approximately 5 × (96 + 16 + 16 + 4 + 13 + ~30 padding) = ~875 pixels of card content alone. Add a 64px header, 24px section spacing, and a 56px continue button → ~1020 vertical pixels demanded. The minimum window height is 600. Overflow is mathematically guaranteed regardless of whether scroll engages.
2. **Scroll non-functional.** The `SingleChildScrollView` was placed under a parent that did not pass bounded height constraints (a `Column` without `Expanded`/`Flexible`, or directly inside a `Container` with no `height`). Without bounded height, `SingleChildScrollView` lays out at the intrinsic height of its content — which exceeds the screen — and produces a scroll bar that points to nothing because the viewport is the full content height. The bar appears, the content overflows, the wheel/drag does nothing.

The fix is not "make the scroll work." The fix is to **restructure the layout so scroll is unnecessary**, because a six-item-or-fewer one-time decision should never require scrolling on a desktop screen. The user is making a single high-stakes choice; forcing a scroll on that decision is a UX failure regardless of whether the scroll mechanically functions.

### 13.7.2 Strategy — `Wrap`-Based Grid, No Scroll, Bounded Card Dimensions

Rewrite `lib/features/onboarding/presentation/use_case_screen.dart` with this layout contract:

```
ConstrainedBox(maxWidth: 720)
  Column(
    Header (title + subtitle, fixed height ~120px)
    SizedBox 24
    Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.center,
      five UseCaseCard widgets each at fixed 200×200
    )
    SizedBox 24
    Continue button row (fixed height ~64px)
  )
```

Card dimensions are tightened from the implicit Phase 12 "full-width row" interpretation to a **fixed 200×200 square** containing: 80px illustration on top (down from 96px to fit), 12px gap, 14px semibold title, 4px gap, 12px secondary description (max 2 lines, ellipsis after). The illustration shrink is intentional — at 96px the card is necessarily portrait-shaped and forces the row layout. At 80px the card becomes square, and three squares fit per row at 720px content width with 16px gaps.

Layout math: 3 cards × 200 + 2 × 16 = 632px row width — fits in 720 (88px slack for centering). Two rows of cards: 2 × 200 + 16 = 416px height. Header + spacing + button: ~232px. Total: ~648px. **Fits in 600px minimum window with 0px slack** — and Phase 13 raises minimum window height to 640px to add a small buffer (a one-line change in the platform-channel window-config call). Larger windows simply have more whitespace above and below the card grid; the grid itself does not grow.

There is **no `SingleChildScrollView`** anywhere in this screen after Phase 13. If a future addition pushes content over the bounds, the answer is to restructure the grid (e.g., 2×3 instead of 3×2), not to reintroduce scroll.

The illustrations remain `SvgPicture.asset` from Phase 12 §12.6.2. The cards remain `AppCard` from Phase 12 §12.4.5. The selection state (2px `brandPrimary`-at-40%-opacity border) is unchanged. Only the screen-level layout and per-card dimensions change.

### 13.7.3 Acceptance

The onboarding use-case screen is correct when:

- At minimum window (900×640), all five cards visible without scrolling, centered horizontally and vertically.
- At 1080p, all five cards visible without scrolling, with proportional whitespace above and below.
- At 4K, content stays at 720px max width centered; the rest is whitespace.
- Mouse wheel over the screen produces no movement (no scrollable widget to react).
- `grep -rn "SingleChildScrollView\|ListView" lib/features/onboarding/presentation/use_case_screen.dart` returns zero matches.
- The continue button remains visible and clickable at every window size in the supported range.

---

## 13.8 File Inventory

**New files (8):**

```
lib/features/admin/data/admin_gate.dart
lib/features/admin/data/decision_log.dart
lib/features/admin/providers/admin_provider.dart
lib/features/admin/providers/admin_provider.g.dart        (generated; do not hand-write)
lib/features/admin/presentation/admin_inspector_screen.dart
tools/brain_editor/bin/brain_editor.dart
tools/brain_editor/lib/brain_validator.dart
tools/brain_editor/lib/brain_signer.dart
```

**Files refactored:**

```
lib/features/delegation/data/keyword_matrix.dart           — recalibrated taxonomy & weights
lib/features/delegation/data/delegation_engine.dart        — normalized scoring + tiebreak + decision log hook
assets/brain/model_profiles.json                           — strengths use canonical taxonomy; +latencyHintMs +descriptionForAdmin
lib/core/widgets/app_button.dart                           — gradient highlight, no Stack
lib/features/onboarding/presentation/use_case_screen.dart  — Wrap-based grid, no scroll
lib/app.dart                                               — dark theme only
lib/core/theme/app_theme.dart                              — lightTheme getter removed
lib/features/settings/presentation/settings_screen.dart    — theme toggle row removed
lib/features/settings/providers/settings_provider.dart     — themeMode field deprecated
lib/core/constants/app_constants.dart                      — kAdminEmail, kAdminGateHash, kDecisionLogCap
```

**Files NOT to be touched:**

- `lib/features/updater/` — Phase 11 OTA system. Untouched.
- `lib/core/theme/app_colors.dart` — `isDark` parameters preserved for trivial light-theme reintroduction.
- `lib/core/theme/app_tokens.dart` — Phase 12 token system. Untouched.
- `lib/features/auth/`, `lib/features/licensing/` — Untouched.
- All Phase 12 widget primitives (`app_card.dart`, `app_dialog.dart`, `app_status_card.dart`, `app_error_display.dart`, `app_success_graphic.dart`, `app_toggle.dart`) — Untouched.

---

## 13.9 Execution Order (Mandatory Sequence)

Execute in this order. Do **not** skip ahead. Each step depends on the previous step's output compiling cleanly.

1. `lib/core/constants/app_constants.dart` — add the three Phase 13 constants.
2. `assets/brain/model_profiles.json` — recalibrate to canonical taxonomy. The matrix and engine in steps 3–4 expect this format.
3. `lib/features/delegation/data/keyword_matrix.dart` — recalibrated matrix.
4. `lib/features/delegation/data/delegation_engine.dart` — recalibrated scoring with decision-log hook (the hook calls a provider that is wired in step 7; until then, the call site references a function that exists in step 5).
5. `lib/features/admin/data/decision_log.dart` — ring buffer, no Riverpod yet.
6. `lib/features/admin/data/admin_gate.dart` — admin authentication gate.
7. `lib/features/admin/providers/admin_provider.dart` — `@riverpod` providers wiring decision log + admin gate. **Run `dart run build_runner build --delete-conflicting-outputs` after this file.**
8. `lib/features/admin/presentation/admin_inspector_screen.dart` — the inspector UI.
9. `lib/core/widgets/app_button.dart` — gradient highlight rewrite.
10. `lib/features/onboarding/presentation/use_case_screen.dart` — Wrap-based layout.
11. `lib/app.dart` — dark theme only.
12. `lib/core/theme/app_theme.dart` — strip `lightTheme` getter.
13. `lib/features/settings/providers/settings_provider.dart` — deprecate themeMode. **Re-run build_runner.**
14. `lib/features/settings/presentation/settings_screen.dart` — strip theme toggle, add Developer section that conditionally surfaces the inspector.
15. `tools/brain_editor/lib/brain_validator.dart` — validator library.
16. `tools/brain_editor/lib/brain_signer.dart` — signer library.
17. `tools/brain_editor/bin/brain_editor.dart` — CLI entry point.
18. Run `dart analyze`. Resolve every warning. The codebase ships with **zero** analyzer warnings.
19. Run `flutter test`. The new `recalibration_smoke_test.dart` (six prompts from §13.3.4) must pass.
20. Manual smoke: launch the app, verify inspector hidden when locked, unlock with admin credentials, verify inspector reachable, verify recalibrated routing on the six smoke prompts, verify button has no line, verify onboarding fits in min window, verify no theme toggle in Settings.

If any step fails, stop and report. Do not proceed to step N+1 with step N broken.

---

## 13.10 Acceptance Criteria — Definition of Done

Phase 13 is complete when **every** item below is verifiable:

1. The six recalibration smoke tests in §13.3.4 pass on a fresh install with all five MVP providers connected.
2. The Delegation Inspector is reachable when admin gate is unlocked, and absent when not. Toggling the gate hides/reveals the entry without restart.
3. The inspector's live-preview renders the engine's full decision (winning model + every normalized category score) within 50ms of the last keystroke for prompts up to 10,000 chars.
4. The decision log captures real `delegate()` calls during normal app use. Capacity is exactly 100; entry 101 evicts entry 1.
5. `dart run tools/brain_editor/bin/brain_editor.dart validate assets/brain/model_profiles.json` exits 0.
6. `dart run tools/brain_editor/bin/brain_editor.dart release …` produces a payload+signature pair the runtime hot-sync accepts at the local-override path.
7. Zero horizontal lines visible at the top edge of any primary button at any tested window size.
8. `grep -rn "lightTheme\|ThemeMode.light\|setThemeMode" lib/` returns no actionable matches (only the deprecation marker in `settings_provider.dart`).
9. The onboarding use-case screen displays five cards in a 3+2 Wrap layout with no scroll widget anywhere. The continue button is visible at minimum window size (900×640).
10. `dart analyze` reports zero issues across `lib/` and `tools/`.
11. All providers touched in Phase 13 use `@riverpod` codegen. Zero legacy `StateNotifierProvider` / `ChangeNotifierProvider` / manual `Provider<T>((ref) => ...)` introduced or left behind.
12. `pubspec.yaml` is unchanged. No new dependencies were added by this phase.

---

## 13.11 Prohibited Patterns — Do Not Ship Any of These

- ❌ Persisting raw prompt text to the decision log under any condition.
- ❌ Surfacing admin tooling, decision log entries, or brain editor commands to a non-admin user — including via debug menus, gesture sequences, easter eggs, query strings, or environment variables that flip the gate at runtime.
- ❌ Any path that emits a brain.json without first calling `BrainValidator.validate()` and passing.
- ❌ Any path that emits a brain.json.sig without holding a 32-byte Ed25519 private key.
- ❌ Adding a "verify your own signature" step to the editor. The runtime is the verifier; bifurcating verification creates drift.
- ❌ Reintroducing a `Stack` with a positioned 1px slab inside `AppButton`. The gradient is the only sanctioned highlight mechanism.
- ❌ Restoring a `SingleChildScrollView` to the use-case screen "just in case future content needs it." If future content needs scroll, that's a separate spec.
- ❌ Re-enabling the light theme toggle in Settings until a dedicated phase audits every screen's light-mode contrast.
- ❌ Adding analytics, telemetry, crash reporting, or any outbound network call from the admin namespace. Inspector reads in-memory; CLI runs locally.
- ❌ Reading the admin secret across more than one function boundary. Same rule as the API-key memory-safety rule (`CLAUDE.MD` §7.2).

---

## Appendix A: Manifest of Changes to Existing Documents

For archival clarity, these are the textual changes Phase 13 requires to existing architecture docs. Apply in a single commit titled `docs: Phase 13 supersedes delegation matrix from §6.3.2 and adds admin tooling`.

1. **`CLAUDE.MD` §6.3.2** — prepend: *"See PHASE_13.MD §13.3 for the recalibrated 14-category taxonomy and normalized scoring algorithm that supersedes the matrix below. The pre-Phase-13 matrix in this section is preserved for archival reference only."*
2. **`CLAUDE.MD` §4.2** — prepend: *"Phase 13 locks the app to dark mode pending a per-screen light-theme audit. The `AppTheme.lightTheme` getter is removed. The `isDark`-parameterized `AppColors` getters are retained for trivial reintroduction. See PHASE_13.MD §13.6."*
3. **`CLAUDE.MD` §9 Phase 4 deliverables** — append to deliverable 3: *"As of Phase 13 the matrix uses the canonical category enum from `lib/features/delegation/data/keyword_category.dart`. See PHASE_13.MD §13.3.2."*
4. **`CLAUDE_PHASE_11.MD` §7** — append: *"Brain payloads consumed by this hot-sync mechanism are now produced by the Phase 13 brain editor CLI. See PHASE_13.MD §13.4 for the authoring contract. The runtime verification gate in §6.7 is unchanged."*
5. **`PHASE_12.MD` §12.4.3** — append: *"The `Stack`-with-positioned-1px-slab implementation produced a visible horizontal line on every primary button. Phase 13 §13.5 supersedes it with a gradient-based highlight. Do not reintroduce the Stack pattern."*

---

*End of document. Sonnet: your Phase 13 scope is defined entirely within these pages plus the still-binding portions of `CLAUDE.MD`, `CLAUDE_PHASE_11.MD`, and `PHASE_12.MD`. Build only what is described here. Build it in the order specified in §13.9. Ship it gated.*
