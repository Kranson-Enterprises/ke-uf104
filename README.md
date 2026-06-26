# Uniface 10 Workspace

This repository is a scaffold for a Uniface 10 project.

- Folders created: `components/`, `src/`, `scripts/`, `docs/`
- Place Uniface components in `components/` and sources in `src/`.

Next steps
1. Configure Uniface installation path in `scripts/setup-env.bat`.
2. Initialize a Git repository with `git init` (optional).
3. Ask me to add example components or CI scripts.

CI
- A basic GitHub Actions workflow is included at `.github/workflows/ci.yml`.
- The workflow runs `scripts/setup-env.bat` and `scripts/build.bat` on Windows runners.

Sample component
- A minimal placeholder component is in `components/sample_component.com`.
