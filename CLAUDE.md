# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

kstack is a **skill pack** (not an app) distributed to Claude Code and other agent CLIs. The shipped artifacts are `SKILL.md` files plus a handful of helper shell scripts in `src/bin/`. There is no runtime service — everything is POSIX shell rendered/executed at install time or inside an agent session.

Shipped shell (`scripts/install`, everything under `src/bin/` and `src/lib/`, plus any skill `scripts/main`) must run on **bash 3.2+** — that's what macOS's `/usr/bin/bash` is, and we don't assume users have a newer bash on PATH. Concretely: no `declare -A`, no `${var,,}`/`${var^^}`, no `mapfile`/`readarray`, no `[[ =~ ]]` BASH_REMATCH patterns that rely on 4.x fixes, and no `&>` redirection. The big footgun is `set -u` + empty arrays: `"${arr[@]}"` raises *unbound variable* in 3.2 when `arr=()`. Either guard iteration with `[ ${#arr[@]} -eq 0 ] && continue`, or use `${arr[@]+"${arr[@]}"}` at the expansion site. Dev-only scripts (`scripts/*.sh`, `tests/**`) may assume a newer bash since they only run on CI/contributor machines.

## Layout

Split is: **`src/` = installer payload (what gets copied/rendered into an install root); everything else = dev infra.**

- `Makefile` — contributor dev entrypoint. Thin facade over `scripts/` (`make install`, `make test`, `make lint`, etc.).
- `src/{bin,lib,skills,schemas}/` — the payload: sources copied verbatim (`bin`, `lib`, `schemas`) or template-rendered (`skills`) into an install root.
- `scripts/install` — the installer. Reads from `src/` and writes outputs (`.kstack/`, `.<agent>/skills/`) at the repo root in dev mode.
- `scripts/bootstrap.sh` — the hosted `curl | bash` getter. Clones an upstream checkout, then execs `$UPSTREAM/scripts/install`.
- `scripts/{lint,test,test-e2e,test-evals,clean}.sh` — repo dev scripts.
- `tests/{unit,integration,e2e,evals,fixtures}/` — bats + eval harness. Dev-only; not part of the payload.
- `CLAUDE.md`, `TODO.md`, `README.md`, `LICENSE`, `assets/`, `.github/` — repo metadata.

All commands and paths below are relative to the repo root.

## Commands

- `./scripts/lint.sh` — run shellcheck across every linted shell file (severity=warning). Requires `shellcheck` (`brew install shellcheck` / `apt install shellcheck`). CI calls this script directly.
- `./scripts/test.sh` — run the fast bats tiers (`tests/unit` + `tests/integration`). Requires `bats-core` (`brew install bats-core` / `apt install bats`). Pass `--all` to also run the e2e tier.
- `./scripts/test-e2e.sh` — run the cluster-backed tier against a kind cluster named `kstack-test`. The kind lifecycle lives in `tests/e2e/lib/kind-cluster.sh` and is shared with the eval tier; the bats suite hook `tests/e2e/setup_suite.bash` is a thin wrapper around it. No prior `kind` state is required. Set `KSTACK_REUSE_CLUSTER=1` during dev loops to keep the cluster alive across runs. The Kubernetes version is pinned by `KSTACK_KIND_NODE_IMAGE` in that lib (override it to test another version); CI installs a matching `kubectl` via the `KUBECTL_VERSION` pin in `ci.yml`, so bump the two together. Requires `kind`, `kubectl`, and a running Docker daemon.
- `./scripts/test-evals.sh` — run the eval tier: plants fixtures in the kind cluster, invokes skills via `claude -p`, and scores the responses. Requires `ANTHROPIC_API_KEY`, `claude`, `jq`, and `yq` in addition to the e2e prerequisites. Exits 0 with a skip message when `ANTHROPIC_API_KEY` is unset. Env: `KSTACK_EVAL_MAX_RUNS` (override samples per scenario), `KSTACK_EVAL_BUDGET_USD` (hard cost cap). Flags: `--scenario <id>` to run one, `--include-placeholder` to run the smoke scenario.
- `bats tests/unit/<file>.bats` — run a single test file. Use `bats -f "<name pattern>" …` to run one test.
- `make install` (or `./scripts/install`) — dev mode. Renders skills into `<repo>/.<agent>/skills/<name>/…` for every agent CLI detected on `PATH`, reading sources from `src/` and writing outputs at the repo root. Slot names are bare by default; pass `--prefix=<p>` to render them as `<p><name>/`.
- `./scripts/install --local` — user-facing local install. Clones/updates `$PWD/.kstack/upstream/` at the latest release tag and renders into `$PWD/.<agent>/skills/<name>/…`. Normally driven by the hosted bootstrap (`curl … | bash -s -- --local`); the invoker's checkout is never used as the source.
- `./scripts/install --global` — clone/update `~/.config/kstack/upstream/` at the latest release tag and render into `~/.<agent>/skills/<name>/…`. Same canonical-upstream rule as `--local`.
- `make clean` (or `./scripts/clean.sh`) — remove gitignored dev-mode artifacts (`.claude/`, `.codex/`, `.kstack/`, etc.) so `make install` runs against a clean tree.

CI (`.github/workflows/ci.yml`) runs four jobs. `lint` runs `scripts/lint.sh`, which shellchecks `scripts/install` plus everything under `src/bin/` (including `entrypoint`), `src/lib/`, `scripts/*.sh`, the `scripts/main` (and any `scripts/lib/*.sh`) of every skill that ships shell, `tests/test_helper.bash`, `tests/e2e/{setup_suite.bash,lib/*.sh}`, `tests/evals/lib/*.sh`, and every `.bats` file under `tests/` (severity=warning, external-sources on). `.bats` files run as a second shellcheck pass with an explicit `--shell=bash`, since their `#!/usr/bin/env bats` shebang names no dialect. `bats` runs `scripts/test.sh` on Linux, macOS, and Windows (amd64+arm64) for every PR. `bats-e2e` runs `scripts/test-e2e.sh` on Linux amd64 only (kind cluster required) and is a required status check. `evals` runs `scripts/test-evals.sh` but is `workflow_dispatch`-only — trigger it manually via `gh workflow run ci.yml`.

## Architecture

### Templates → SKILL.md rendering

Skills are authored as `src/skills/<name>/SKILL.md.tmpl`. The `scripts/install` script renders each skill slot in two passes:

1. **`render_skill`** — inlines partials at `{{GLOBAL_FLAGS}}` and `{{ENTRYPOINT}}` markers from `src/skills/_partials/`, then substitutes scalar placeholders `{{ROOT_DIR}}`, `{{SKILL_DIR}}`, `{{SKILL_NAME}}`, `{{AGENT}}`. Writes the resolved `SKILL.md` into the agent-specific skills dir (no intermediate dist/).
2. **`render_help`** — extracts the `<dt>/<dd>` block for `#### /<skill>` from the repo-root `README.md`, appends the `**Global flags**` section, and writes the result to `<skill-slot>/references/help.md` (reachable via `{{SKILL_DIR}}/references/help.md` in templates). The entrypoint handles `--help` on the skill's behalf: it opens the skill's docs URL (`references/docs-url.txt`) in the browser and returns the URL in a `render: verbatim` envelope. When the URL can't be opened (headless, offline, no opener), it returns this `help.md` plus the URL instead, so every skill gets a consistent help page sourced from the README without per-skill wiring.

`SKILL.md.tmpl` and the README section are the sources of truth — rendered `SKILL.md` and `references/help.md` files are gitignored and must never be hand-edited. Cross-cutting prose (global flags, update notices, preamble dispatch) belongs in a partial, not duplicated into every skill. A new skill needs both a `SKILL.md.tmpl` and a matching `#### /<skill>` section in `README.md`, or `render_help` will exit non-zero during install.

When a skill body needs to invoke a helper, reference it as `{{ROOT_DIR}}/bin/<tool>` so the absolute path is baked in at render time (this is how the same template works across all three install modes).

### Agent table (src/lib/agents.sh)

`src/lib/agents.sh` is the single source of truth mapping agent name → CLI binary to probe → global skills dir → local skills dir. The `scripts/install` script, `src/bin/uninstall`, and the test suite all source it. When adding a new agent, update this file and the table in `README.md`.

### Three install modes

All modes materialize a symmetric `{{ROOT_DIR}}/{bin,lib,cache,manifest}/` layout and render slots as `<prefix><name>/` (prefix comes from `--prefix`, empty by default). What varies is where `{{ROOT_DIR}}` sits, whether an `upstream/` checkout lives alongside `bin/`, and which agent skills dir receives the rendered `SKILL.md`.

- **Dev** (`make install` / `./scripts/install` from a clone): copies `src/bin/` → `<repo>/.kstack/bin/` and `src/lib/` → `<repo>/.kstack/lib/` (recursive — per-skill helper trees at `src/lib/<skill>/` are supported), writes `<repo>/.kstack/manifest/version` from `git describe --tags --exact-match HEAD` (or current branch name), and renders skills into `<repo>/.<agent>/skills/<prefix><name>/SKILL.md`. `{{ROOT_DIR}}` = `<repo>/.kstack`. No `upstream/` dir. Upgrade via `git pull && make install` (the `bin/upgrade` helper only handles managed modes).
- **Local** (`./scripts/install --local` or the hosted bootstrap): maintains `$PWD/.kstack/upstream/` at the latest `v*` tag and renders into `$PWD/.<agent>/skills/<prefix><name>/SKILL.md`. `{{ROOT_DIR}}` = `$PWD/.kstack`. Upgrade via `$PWD/.kstack/bin/upgrade`.
- **Global** (`./scripts/install --global`): maintains `~/.config/kstack/upstream/` at the latest `v*` tag and renders into `~/.<agent>/skills/<prefix><name>/SKILL.md`. `{{ROOT_DIR}}` = `~/.config/kstack`. Upgrade via `~/.config/kstack/bin/upgrade`.

Install ownership is tracked via `{{ROOT_DIR}}/manifest/skills` — a newline-separated list of rendered slot names (prefix included) written at the end of each install. Re-installs diff the previous list against the new set and remove the dropped slots from every target agent's skills dir; `bin/uninstall` reads the same file to know what to delete. User-authored skills in the same skills dir are never touched because they never appear in the manifest. The installed version (tag or branch) lives alongside at `{{ROOT_DIR}}/manifest/version` and is read by the update check. Both files are plain single-fact text files — no JSON, no headers — and are managed via `src/lib/manifest.sh`.

The `bin/` helpers (`check-update`, `upgrade`, `uninstall`, `dismiss-update`, `entrypoint`) assume they sit at `{{ROOT_DIR}}/bin/<name>` and derive `ROOT_DIR` as `dirname "$SCRIPT_DIR"`. Running a helper directly from the source tree (`./src/bin/check-update`) without installing first is unsupported — paths resolve to the repo root rather than `.kstack/`. Keep that invariant when adding helpers.

### Skill entrypoint and `scripts/main` contract

Every rendered `SKILL.md` invokes `{{ROOT_DIR}}/bin/entrypoint --skill-dir={{SKILL_DIR}} -- <user args>` as its first action. The entrypoint derives the skill name from `basename "$skill_dir"` — whatever slot name the installer rendered, which matches what the user typed as the slash command (bare by default, or `<prefix><name>` when `--prefix` was passed). The entrypoint owns three mechanical jobs: a cached update-check (lib: `src/lib/update-check.sh`), `--help` short-circuit (opens `{{SKILL_DIR}}/references/docs-url.txt` in a browser and returns the URL in a `render: verbatim` envelope, falling back to `{{SKILL_DIR}}/references/help.md` plus the URL when it can't be opened), and optional dispatch to `{{SKILL_DIR}}/scripts/main` when that script exists. The entrypoint is deliberately fail-tolerant: update-check runs in a guarded subshell so its failures never break a skill invocation.

**Response envelope contract.** Every kstack script (`bin/entrypoint` and each skill's `scripts/main`) exits 0 on a clean run and writes exactly one JSON object — the *response envelope* — to stdout. The schema lives at `src/schemas/response.schema.json` (installed to `{{ROOT_DIR}}/schemas/response.schema.json`) and helpers for emitting envelopes live in `src/lib/response.sh` (`response::ok_verbatim`, `response::ok_agent`, `response::user_error`, `response::infra_error`). The envelope carries `status` (`ok` | `error`), `render` (`verbatim` | `agent` — for `ok`), `kind` (`user` | `infra` — for `error`), `content`/`message`, and an optional `notice` field the entrypoint populates when an update is due. The agent-side dispatch rules live in `src/skills/_partials/entrypoint.md`. Exiting non-zero is reserved for unexpected crashes — all expected outcomes (success, user error, infra error, `--help`) go through the envelope so the host agent never renders a red "Error" banner for a normal response.

A skill opts into automatic shell dispatch by shipping an executable `scripts/main`. The entrypoint `exec`s it with the forwarded user args and exports `KSTACK_ROOT`, `KSTACK_SKILL_DIR`, `KSTACK_SKILL_NAME`, and `KSTACK_NOTICE` (the update banner, if any — so the main script can forward it on its own envelope). The script owns its own global-flag parsing (the `{{GLOBAL_FLAGS}}` partial stays Claude's contract, but Claude won't be reprocessing args when `scripts/main` handles the full response), sources `$KSTACK_ROOT/lib/response.sh`, and emits its envelope via the helpers. Skills without a `scripts/main` (LLM-reasoning skills like `/investigate`) get the preamble-only `ok/agent` envelope (with `notice` attached if due) and then run their SKILL.md body as usual.

### Bootstrap duplication

`scripts/bootstrap.sh` is the source for the `curl … | bash` bootstrap hosted at `https://kubestack.xyz/install.sh`. A verbatim copy lives in the `kubetail-website` repo's static assets and is **not automatically synced** — when you edit this file, copy it over manually.

### Install root layout

An install materializes `{{ROOT_DIR}}/{bin,lib,cache,state,manifest}` — `~/.config/kstack/...` globally, `$PWD/.kstack/...` for `--local`, `<repo>/.kstack/...` for dev mode. `bin/` and `lib/` are copies of the `src/` tree (rerun `./install` to pick up changes). `cache/` holds the update-check cache and is managed by `src/lib/cache.sh` (a single-branch function keyed off `dirname "$SCRIPT_DIR"`). `state/` holds per-context learned state. `manifest/` holds single-fact text files describing the install (`version`, `skills`) managed by `src/lib/manifest.sh`. The `/forget` skill clears the `cache/` and `state/` subtrees; `/cleanup-cluster` clears in-cluster resources (anything labeled `kstack.kubetail.com/owned-by=kstack`).

## Tests

- `tests/unit/` — sourced-function tests (e.g. `agents.bats` sources `src/lib/agents.sh`).
- `tests/integration/` — end-to-end CLI tests that build a fake kstack checkout under `$BATS_TEST_TMPDIR` and run `install` against it with an isolated `$HOME`. See `tests/test_helper.bash` (`common_setup`, `use_mocks`, `write_stub`). The fakes mirror the real repo layout: the `install` script at the fake root plus `src/lib/`, `src/bin/`, `src/skills/`, etc. underneath.
- `tests/e2e/` — cluster-backed tests. `tests/e2e/lib/kind-cluster.sh` owns the kind lifecycle (shared with the eval tier); `tests/e2e/setup_suite.bash` is the bats `setup_suite`/`teardown_suite` wrapper. Tests inherit `KUBECONFIG` and talk to the cluster directly. Only fires under `scripts/test-e2e.sh` — never under `scripts/test.sh`.
- `tests/evals/` — skill evaluation scenarios. Each `scenarios/<id>/` is a self-contained package: `scenario.yaml` (metadata + claude flags), `fixture.yaml` (kubectl manifests), `prompt.txt` (user turn), `expected.yaml` (keyword/structured/judge rubric), optional `wait.sh`. Runner libs live under `tests/evals/lib/` and are driven by `scripts/test-evals.sh`. Artifacts (transcripts, judge outputs, state snapshots) land under `tests/evals/artifacts/<id>/` and are gitignored. See `tests/evals/README.md` for the full authoring guide.
- `tests/fixtures/` — minimal skill + partial fixtures used by integration tests (so tests aren't coupled to real skill contents).

The bats helper `tests/test_helper.bash` exposes two root vars: `REPO_ROOT` resolves to the repo top (where `install`, `scripts/`, and `src/` live), and `SRC_ROOT` resolves to `$REPO_ROOT/src` — the installer payload that tests reference as `$SRC_ROOT/lib/…`, `$SRC_ROOT/bin/…`, etc.

When adding a helper under `src/bin/` or a partial under `src/skills/_partials/`, add a test that exercises it through `install`, not just via direct invocation — the rendering pipeline is where most regressions land.

## Contributing

[`CONTRIBUTING.md`](./CONTRIBUTING.md) is the source of truth. This summary exists because its "AI-Assisted Editors" section sends agents *here* for guidance, so an agent that reads only this file would otherwise miss the rules below — including the disclosure one.

- **Before proposing a change**, run `./scripts/lint.sh` and `./scripts/test.sh`; add `./scripts/test-e2e.sh` when the change touches cluster behavior.
- **Commits** use [Conventional Commits](https://www.conventionalcommits.org) with an all-lowercase title, and are signed off — the DCO check is required:

      git commit -s -m "<type>(<scope>): <title>"

- **AI assistance must be disclosed.** The AI policy does not accept contributions authored entirely by an LLM, and asks for a trailer on every commit an AI tool helped with:

      git commit -s --trailer "Assisted-by: AGENT_NAME:MODEL_VERSION" -m "<message>"

- **PR titles** carry a type emoji: 🎣 bug fix, 🐋 new feature, 📜 documentation, ✨ general improvement. The body follows `.github/pull_request_template.md` and links the issue (`Closes #N`).
- **Branches** are named `<type>/<short-description>`.
- **Issues** use the templates in `.github/ISSUE_TEMPLATE/`.

Adding a skill touches more places than the template alone: a `SKILL.md.tmpl`, a matching `#### /<skill>` section in the repo-root `README.md` (without it `render_help` fails the install), an entry in `scripts/lint.sh` if it ships a `scripts/main`, and integration tests that exercise it through `install` rather than by direct invocation.
