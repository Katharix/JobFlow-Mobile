# JobFlow Mobile Integration Test Fixtures

Use seeded test identities for repeatable integration tests.

## Example run

```bash
flutter test integration_test \
  --dart-define=JOBFLOW_API_BASE_URL=https://api.example.com \
  --dart-define=JOBFLOW_TEST_EMAIL=employee+e2e@example.test \
  --dart-define=JOBFLOW_TEST_PASSWORD=***
```

## Recommended CI secrets

- `JOBFLOW_API_BASE_URL`
- `JOBFLOW_TEST_EMAIL`
- `JOBFLOW_TEST_PASSWORD`
