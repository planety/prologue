(# GitHub Copilot instructions for Prologue)

Purpose: Help contributors and Copilot produce precise, idiomatic, and test-backed changes for the Prologue Nim web framework.

- Repo summary: Prologue is a small web framework and tooling written in Nim. Prioritize clarity, minimalism, and compatibility with existing APIs.
- Primary languages: Nim (core), shell (scripts for CI/tasks).

Guidelines for suggestions and edits
- Prefer small, well-tested changes. Avoid large rewrites unless the user explicitly requests them.
- Keep public APIs stable: do not change function signatures or remove exported symbols without a clear migration plan.
- Match repository conventions: follow existing naming, module layout, and style used across `src/` and `examples/`.
- Include or update tests for behavioral changes. Run the project's test task locally before proposing merges.

Commands the contributor should run locally
- Run tests: `nimble tests` (or the repository's documented test command).

Commit & PR guidance
- Make focused commits with clear messages describing *why* the change was made.
- Each PR should include tests or a clear justification if tests cannot be added.
- Update `README.md` or `docs/` only when behavior or public usage changes.

When writing code suggestions
- Provide minimal reproducible examples when proposing API changes.
- Explain potential breaking changes and migration steps in PR descriptions.
- Prefer idiomatic Nim over clever shortcuts; prefer readability.

If unsure
- Ask for clarification in the PR or an issue. When requested, provide multiple alternatives and tradeoffs.

Helpful links
- README: [README.md](README.md)
- Docs: [docs/index.md](docs/index.md)

Thank you for contributing — aim for safe, test-covered improvements.

