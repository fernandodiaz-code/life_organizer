# Life Organizer App

Main Flutter application package for the Life Organizer monorepo.

This package depends on:

- `life_core` for shared configuration and infrastructure helpers.
- `wetface` for the WetFace alarm module.

Run from this directory with the required runtime configuration:

```bash
flutter run \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<anon-key> \
  --dart-define=N8N_WEBHOOK_URL=<worker-url> \
  --dart-define=CLOUDFLARE_BASE_URL=<worker-base-url>
```

