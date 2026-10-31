# Regional sales report (demo app)

## Commands
- Install: npm ci
- Test: npm test
- Typecheck: npm run typecheck
- Build: npm run build

## Rules
- Work only in src/. Never edit .github/, deploy/, argocd/, scripts/ or Dockerfile.
- Add or update tests in src/*.test.ts for every change.
- Keep changes small. Do not add npm packages.
- Match the existing code style (TypeScript, React function components).

## Done means
- npm test and npm run typecheck both pass.
