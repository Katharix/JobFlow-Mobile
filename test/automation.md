# JobFlow Mobile Automation

This repo uses Flutter test tooling for mobile automation.

## Commands

- `flutter test` for widget and unit tests.
- `flutter test integration_test` for integration tests.

## Seeded fixture notes

- See `integration_test/fixtures.seed.example.json`.
- For authenticated integration tests, pass values via `--dart-define` and CI secrets.

## Current integration coverage

- App boot smoke test.
- Login screen content and primary controls visible.

## Next workflow scenarios to automate

1. Employee login with seeded test account.
2. Assignments list fetch and render.
3. Assignment detail load.
4. Job tracking update submission.
5. ETA map launch action wiring.
6. Offline queue and sync behavior.
