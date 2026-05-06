#!/usr/bin/env bats

# Copyright 2026 The Kubetail Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

setup() {
  load '../test_helper.bash'
  common_setup

  # Global-mode install layout under $HOME.
  ROOT="$HOME/.config/kstack"
  mkdir -p "$ROOT/bin" "$ROOT/lib" "$ROOT/cache" "$ROOT/manifest"
  cp "$SRC_ROOT/bin/entrypoint"        "$ROOT/bin/entrypoint"
  cp "$SRC_ROOT/lib/cache.sh"          "$ROOT/lib/cache.sh"
  cp "$SRC_ROOT/lib/manifest.sh"       "$ROOT/lib/manifest.sh"
  cp "$SRC_ROOT/lib/update-check.sh"   "$ROOT/lib/update-check.sh"
  cp "$SRC_ROOT/lib/response.sh"       "$ROOT/lib/response.sh"
  cp "$SRC_ROOT/lib/kube-context.sh"   "$ROOT/lib/kube-context.sh"
  chmod +x "$ROOT/bin/entrypoint"
  CACHE_FILE="$ROOT/cache/update.json"
  EP="$ROOT/bin/entrypoint"

  # A rendered skill slot — what {{SKILL_DIR}} resolves to post-install.
  SKILL_DIR="$HOME/.claude/skills/demo"
  mkdir -p "$SKILL_DIR/references" "$SKILL_DIR/scripts"
  printf 'help body\n' > "$SKILL_DIR/references/help.md"
  printf 'https://kstack.sh/reference/skills/demo\n' > "$SKILL_DIR/references/docs-url.txt"

  # Installed version — non-main so the update check engages.
  echo "v1.0.0" > "$ROOT/manifest/version"

  # Satisfy the resolver for tests that don't exercise context resolution
  # explicitly. Tests that do override or unset this.
  export KSTACK_KUBE_CONTEXT="test-ctx"
}

# stub_git (and stub_git --fail) are provided by test_helper.bash.

# Tiny jq-free field extractor for bats assertions. Assumes simple envelopes
# with no nested objects (which is the whole schema).
envelope_field() {
  local json="$1" field="$2"
  printf '%s' "$json" | awk -v f="$field" '
    {
      s = $0
      pat = "\"" f "\":\""
      i = index(s, pat)
      if (i == 0) exit 0
      s = substr(s, i + length(pat))
      out = ""
      while (length(s) > 0) {
        c = substr(s, 1, 1)
        if (c == "\\") {
          n = substr(s, 2, 1)
          if (n == "n") out = out "\n"
          else if (n == "t") out = out "\t"
          else if (n == "r") out = out "\r"
          else out = out n
          s = substr(s, 3)
        } else if (c == "\"") {
          print out
          exit 0
        } else {
          out = out c
          s = substr(s, 2)
        }
      }
    }
  '
}

# ─── --help short-circuit ──────────────────────────────────────

@test "--help emits ok/verbatim envelope with docs URL" {
  run "$EP" --skill-dir="$SKILL_DIR" -- --help
  [ "$status" -eq 0 ]
  [[ "$output" == *'"kstack":"1"'* ]]
  [[ "$output" == *'"status":"ok"'* ]]
  [[ "$output" == *'"render":"verbatim"'* ]]
  content="$(envelope_field "$output" content)"
  [[ "$content" == *"Reference docs:"* ]]
  [[ "$content" == *"kstack.sh/reference/skills/demo"* ]]
}

@test "--help wins even when other flags are present" {
  run "$EP" --skill-dir="$SKILL_DIR" -- --context=foo --help
  [ "$status" -eq 0 ]
  [[ "$output" == *'"render":"verbatim"'* ]]
  content="$(envelope_field "$output" content)"
  [[ "$content" == *"Reference docs:"* ]]
}

@test "--help with missing docs-url.txt emits infra error envelope" {
  rm "$SKILL_DIR/references/docs-url.txt"
  run "$EP" --skill-dir="$SKILL_DIR" -- --help
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status":"error"'* ]]
  [[ "$output" == *'"kind":"infra"'* ]]
  msg="$(envelope_field "$output" message)"
  [[ "$msg" == *"Docs URL missing"* ]]
}

@test "--help skips the update check (no notice on help envelope)" {
  stub_git
  export MOCK_TAGS="v9.9.9"  # would produce a notice if update-check ran
  run "$EP" --skill-dir="$SKILL_DIR" -- --help
  [ "$status" -eq 0 ]
  [[ "$output" != *'"notice"'* ]]
}

# ─── update-check preamble (via envelope notice field) ─────────

@test "notice field is attached when a newer tag exists" {
  stub_git
  export MOCK_TAGS="v1.0.0 v2.0.0"
  cat > "$CACHE_FILE" <<EOF
{
  "last_check": "2000-01-01T00:00:00Z",
  "latest_known": "v1.0.0"
}
EOF
  run "$EP" --skill-dir="$SKILL_DIR" --
  [ "$status" -eq 0 ]
  [[ "$output" == *'"notice"'* ]]
  notice="$(envelope_field "$output" notice)"
  [[ "$notice" == *"kstack v2.0.0 is available"* ]]
}

@test "no notice when cache shows up-to-date" {
  stub_git
  export MOCK_TAGS=""
  now_iso="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  cat > "$CACHE_FILE" <<EOF
{
  "last_check": "$now_iso",
  "latest_known": "v1.0.0"
}
EOF
  run "$EP" --skill-dir="$SKILL_DIR" --
  [ "$status" -eq 0 ]
  [[ "$output" != *'"notice"'* ]]
}

@test "git ls-remote failure leaves invocation silent (envelope still valid)" {
  stub_git --fail
  rm -f "$CACHE_FILE"
  run "$EP" --skill-dir="$SKILL_DIR" --
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status":"ok"'* ]]
  [[ "$output" != *'"notice"'* ]]
}

@test "no manifest/version -> silent preamble envelope" {
  rm "$ROOT/manifest/version"
  stub_git
  export MOCK_TAGS="v9.0.0"
  run "$EP" --skill-dir="$SKILL_DIR" --
  [ "$status" -eq 0 ]
  [[ "$output" != *'"notice"'* ]]
}

@test "manifest/version=main -> silent preamble (pre-release)" {
  echo "main" > "$ROOT/manifest/version"
  stub_git
  export MOCK_TAGS="v9.0.0"
  run "$EP" --skill-dir="$SKILL_DIR" --
  [ "$status" -eq 0 ]
  [[ "$output" != *'"notice"'* ]]
}

# ─── scripts/main dispatch ─────────────────────────────────────

@test "no scripts/main -> ok/agent envelope with empty content" {
  stub_git
  export MOCK_TAGS="v1.0.0"
  run "$EP" --skill-dir="$SKILL_DIR" --
  [ "$status" -eq 0 ]
  [[ "$output" == *'"render":"agent"'* ]]
  content="$(envelope_field "$output" content)"
  [ -z "$content" ]
}

@test "scripts/main output is passed through verbatim to stdout" {
  stub_git
  export MOCK_TAGS="v1.0.0"
  cat > "$SKILL_DIR/scripts/main" <<'EOF'
#!/usr/bin/env bash
printf '{"kstack":"1","status":"ok","render":"verbatim","content":"snapshot output"}\n'
exit 0
EOF
  chmod +x "$SKILL_DIR/scripts/main"
  run "$EP" --skill-dir="$SKILL_DIR" --
  [ "$status" -eq 0 ]
  [[ "$output" == *'"content":"snapshot output"'* ]]
}

@test "scripts/main receives KSTACK_NOTICE when one is due" {
  stub_git
  export MOCK_TAGS="v1.0.0 v2.0.0"
  cat > "$CACHE_FILE" <<EOF
{
  "last_check": "2000-01-01T00:00:00Z",
  "latest_known": "v1.0.0"
}
EOF
  cat > "$SKILL_DIR/scripts/main" <<'EOF'
#!/usr/bin/env bash
printf 'notice-was=%s\n' "${KSTACK_NOTICE:-<unset>}"
exit 0
EOF
  chmod +x "$SKILL_DIR/scripts/main"
  run "$EP" --skill-dir="$SKILL_DIR" --
  [ "$status" -eq 0 ]
  [[ "$output" == *"notice-was=kstack v2.0.0 is available"* ]]
}

@test "scripts/main non-executable -> infra error envelope" {
  stub_git
  export MOCK_TAGS="v1.0.0"
  : > "$SKILL_DIR/scripts/main"  # create but do not chmod +x
  run "$EP" --skill-dir="$SKILL_DIR" --
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status":"error"'* ]]
  [[ "$output" == *'"kind":"infra"'* ]]
  msg="$(envelope_field "$output" message)"
  [[ "$msg" == *"not executable"* ]]
}

@test "scripts/main sees KSTACK_* env vars + forwarded argv (--context stripped)" {
  cat > "$SKILL_DIR/scripts/main" <<'EOF'
#!/usr/bin/env bash
printf 'root=%s dir=%s name=%s kube=%s args=%s\n' \
  "${KSTACK_ROOT:-}" "${KSTACK_SKILL_DIR:-}" "${KSTACK_SKILL_NAME:-}" \
  "${KSTACK_KUBE_CONTEXT:-}" "$*"
exit 0
EOF
  chmod +x "$SKILL_DIR/scripts/main"
  stub_git
  export MOCK_TAGS="v1.0.0"
  run "$EP" --skill-dir="$SKILL_DIR" -- --context=dev foo bar
  [ "$status" -eq 0 ]
  [[ "$output" == *"root=$ROOT"* ]]
  [[ "$output" == *"dir=$SKILL_DIR"* ]]
  [[ "$output" == *"name=demo"* ]]
  [[ "$output" == *"kube=dev"* ]]
  # --context was stripped; remaining args forwarded in order.
  [[ "$output" == *"args=foo bar"* ]]
}

# ─── kube context resolution ───────────────────────────────────

@test "kube_context: --context flag wins over env and kubectl" {
  stub_git
  export MOCK_TAGS="v1.0.0"
  export KSTACK_KUBE_CONTEXT="env-ctx"
  run "$EP" --skill-dir="$SKILL_DIR" -- --context=flag-ctx
  [ "$status" -eq 0 ]
  [[ "$output" == *'"kube_context":"flag-ctx"'* ]]
}

@test "kube_context: env var used when no flag" {
  stub_git
  export MOCK_TAGS="v1.0.0"
  export KSTACK_KUBE_CONTEXT="env-ctx"
  run "$EP" --skill-dir="$SKILL_DIR" --
  [ "$status" -eq 0 ]
  [[ "$output" == *'"kube_context":"env-ctx"'* ]]
}

@test "kube_context: falls back to kubectl current-context" {
  stub_git
  export MOCK_TAGS="v1.0.0"
  unset KSTACK_KUBE_CONTEXT
  write_stub kubectl '
case "$*" in
  "config current-context") printf "kc-live\n" ;;
  *) exit 2 ;;
esac
'
  run "$EP" --skill-dir="$SKILL_DIR" --
  [ "$status" -eq 0 ]
  [[ "$output" == *'"kube_context":"kc-live"'* ]]
}

@test "kube_context: unresolvable context yields user error envelope" {
  stub_git
  export MOCK_TAGS="v1.0.0"
  unset KSTACK_KUBE_CONTEXT
  # Stub kubectl to fail current-context (simulates no configured context).
  # Can't rely on removing kubectl from PATH: bash and kubectl commonly
  # share a bin dir (e.g. /opt/homebrew/bin), so pruning PATH to bash-only
  # would still expose a real kubectl and leak the host's context.
  write_stub kubectl 'exit 1'
  run "$EP" --skill-dir="$SKILL_DIR" --
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status":"error"'* ]]
  [[ "$output" == *'"kind":"user"'* ]]
  msg="$(envelope_field "$output" message)"
  [[ "$msg" == *"kube context"* ]]
}

@test "kube_context: empty --context value yields user error envelope" {
  stub_git
  export MOCK_TAGS="v1.0.0"
  run "$EP" --skill-dir="$SKILL_DIR" -- --context=
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status":"error"'* ]]
  [[ "$output" == *'"kind":"user"'* ]]
}

@test "kube_context: scripts/main inherits exported KSTACK_KUBE_CONTEXT" {
  cat > "$SKILL_DIR/scripts/main" <<'EOF'
#!/usr/bin/env bash
printf 'kube=%s\n' "${KSTACK_KUBE_CONTEXT:-<unset>}"
exit 0
EOF
  chmod +x "$SKILL_DIR/scripts/main"
  stub_git
  export MOCK_TAGS="v1.0.0"
  run "$EP" --skill-dir="$SKILL_DIR" -- --context=staging
  [ "$status" -eq 0 ]
  [[ "$output" == *"kube=staging"* ]]
}

@test "kube_context: preamble envelope (no scripts/main) carries kube_context" {
  stub_git
  export MOCK_TAGS="v1.0.0"
  export KSTACK_KUBE_CONTEXT="ambient"
  run "$EP" --skill-dir="$SKILL_DIR" --
  [ "$status" -eq 0 ]
  [[ "$output" == *'"render":"agent"'* ]]
  [[ "$output" == *'"kube_context":"ambient"'* ]]
}

# ─── parser errors ─────────────────────────────────────────────

@test "missing --skill-dir emits infra error envelope" {
  run "$EP" --
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status":"error"'* ]]
  [[ "$output" == *'"kind":"infra"'* ]]
}

@test "missing '--' separator emits infra error envelope" {
  run "$EP" --skill-dir="$SKILL_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status":"error"'* ]]
  [[ "$output" == *'"kind":"infra"'* ]]
}

@test "unexpected flag before '--' emits infra error envelope" {
  run "$EP" --skill-dir="$SKILL_DIR" --bogus -- --help
  [ "$status" -eq 0 ]
  [[ "$output" == *'"kind":"infra"'* ]]
  msg="$(envelope_field "$output" message)"
  [[ "$msg" == *"Unexpected flag"* ]]
}
