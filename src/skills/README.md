# Skill templates

Every kstack skill lives under `skills/<name>/` and is authored as a `SKILL.md.tmpl` file. The `install` script resolves placeholders into a concrete `SKILL.md` at install time and writes it into each agent's skill directory. `install` has three modes — dev (default; `./install` from a clone, writes into `<repo>/.<agent>/skills/kstack-<name>/` with helpers at `<repo>/.kstack/bin/`), local (`--local`; writes into `$PWD/.<agent>/skills/kstack-<name>/` with helpers at `$PWD/.kstack/bin/`), and global (`--global`; writes into `~/.<agent>/skills/kstack-<name>/` with helpers at `~/.config/kstack/bin/`). All three modes render slots under the same `kstack-<name>/` convention.

## Placeholders

| Placeholder         | Dev / Local resolve to                               | Global resolves to                        | Notes                                          |
|---------------------|------------------------------------------------------|-------------------------------------------|------------------------------------------------|
| `{{ROOT_DIR}}`      | `<repo>/.kstack` (dev) or `$PWD/.kstack` (local)     | `~/.config/kstack`                        | The install root (owns `bin/`, `lib/`, `cache/`) |
| `{{SKILL_DIR}}`     | `<ROOT>/.<agent>/skills/kstack-<name>`               | `~/.<agent>/skills/kstack-<name>`         | Absolute path to the rendered skill slot (owns `references/`, `scripts/`) |
| `{{SKILL_NAME}}`    | `kstack-<name>`                                      | `kstack-<name>`                           | e.g. `kstack-cluster-status` (drives slash command) |
| `{{AGENT}}`         | `claude` / `codex` / …                               | `claude` / `codex` / …                    | Target agent                                   |
| `{{GLOBAL_FLAGS}}`  | inlined partial content                              | inlined partial content                   | See Partials                                   |
| `{{ENTRYPOINT}}`    | inlined partial content                              | inlined partial content                   | See Partials                                   |

## Rules

1. `SKILL.md.tmpl` is the source of truth. `SKILL.md` is generated — never edit it by hand.
2. `install` inlines any partials, then runs literal `sed`-style substitution of the scalar placeholders, and writes the resolved `SKILL.md` directly into the agent's skill directory (no intermediate dist/ dir, no symlinks). Every mode writes to `<ROOT>/.<agent>/skills/kstack-<name>/SKILL.md`, with `<ROOT>` varying by mode (see above).
3. Agent install paths come from the table in the top-level `README.md`.
4. When a skill body shells out to a compiled helper, use `{{ROOT_DIR}}/bin/<tool>` so the absolute path is baked in at install time.
5. Dev-mode install artifacts (`<repo>/.<agent>/skills/kstack-<name>/`) are gitignored — only `.tmpl` sources are tracked.
6. For each skill, `install` renders `references/help.md` (next to `SKILL.md`) from the top-level `README.md`'s per-skill `<dt>/<dd>` section plus the global-flags table. On `--help`, `bin/entrypoint` opens the skill's docs URL (`references/docs-url.txt`) in the browser; if that isn't possible (headless, offline) it returns `help.md` plus the URL in a `render: verbatim` envelope. Skills need no per-skill wiring. Every skill directory listed in `skills/` must have a matching section in the top-level `README.md`; `install` aborts otherwise. The `references/` and (future) `scripts/` subdirectories follow Anthropic's recommended skill layout — auxiliary files the agent loads on demand, kept out of the main `SKILL.md`.

## Partials

Cross-cutting prose that every skill needs (e.g. the global-flags contract) lives under `skills/_partials/` and is inlined at render time via a dedicated placeholder.

- `_partials/` is **not** a skill directory — `install` enumerates only dirs that contain a `SKILL.md.tmpl`, so the underscore-prefixed folder is silently skipped.
- Each partial is referenced from a `SKILL.md.tmpl` via a `{{NAME}}` marker on its own line. `install` replaces the marker with the file's verbatim contents before running scalar substitutions.
- Current partials:
  - `_partials/global-flags.md` → `{{GLOBAL_FLAGS}}` (the four global flags documented in the top-level `README.md`).
  - `_partials/entrypoint.md` → `{{ENTRYPOINT}}` (directs the agent to invoke `bin/entrypoint` as its first action every turn — shared preamble that runs the update check, handles `--help`, and optionally dispatches to `{{SKILL_DIR}}/scripts/main`; also covers the NL handling for "upgrade kstack" / "dismiss").
- Partials are kept placeholder-free. If a future partial needs `{{ROOT_DIR}}` etc., that's fine — scalar substitution runs after the inline, so they resolve normally.

## Minimum template shape

```markdown
---
name: {{SKILL_NAME}}
description: <one-line outcome + differentiator>
---

{{ENTRYPOINT}}

{{GLOBAL_FLAGS}}

<body>
```

Follow `/cluster-status` as the reference implementation once it lands — its structure is the pattern the other skills copy.
