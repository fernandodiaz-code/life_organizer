# Life Organizer Monorepo

Flutter monorepo for Life Organizer, the shared core package, and the WetFace alarm module.

## Packages

- `packages/life_organizer`: main Flutter app.
- `packages/core`: shared configuration and base services.
- `packages/wetface`: WetFace alarm flow. Sprint 1 ships a mock validation flow while native alarm/camera/Gemini integration is prepared.

## Local Setup

```bash
dart pub get
dart run melos bootstrap
dart run melos exec --concurrency 1 -- "dart analyze ."
dart run melos exec --dir-exists=test --concurrency 1 -- "flutter test"
```

Run the app:

```bash
cd packages/life_organizer
flutter run \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<anon-key> \
  --dart-define=N8N_WEBHOOK_URL=<worker-url> \
  --dart-define=CLOUDFLARE_BASE_URL=<worker-base-url>
```

## Git Flow

- `main`: stable production branch.
- `develop`: integration branch.
- `feature/*`: one branch per sprint task.

Do not push directly to `main` or `develop`; use PRs with passing analysis/build checks.
