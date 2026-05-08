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

# install in dev mode: reads src/ from the fake checkout and renders into
# <root>/.kstack/ and <root>/.<agent>/skills/.
#
# setup_file stages one fake checkout at $BASELINE_ROOT and runs a baseline
# `install --agent claude --quiet`. Read-only tests and error-case tests
# (which exit before writing) assert against that shared tree. Tests that
# mutate src/, install with alternate flags, or need a pristine skills_dir
# call `isolate_dev_setup` to build a private fake root.

setup_file() {
  load '../test_helper.bash'
  common_setup_file

  BASELINE_ROOT="$TMPDIR_FILE/baseline"
  export BASELINE_ROOT
  stage_dev_source "$BASELINE_ROOT"
  "$BASELINE_ROOT/scripts/install" --agent claude --quiet
}

setup() {
  load '../test_helper.bash'
  FAKE_ROOT="$BASELINE_ROOT"
  RUN_INSTALL="$FAKE_ROOT/scripts/install"
}

# Opt-in helper for tests that need a private fake root they can mutate
# (src/ deletions, alternate --prefix/--agent flags, stale files in the
# skills slot, etc.).
isolate_dev_setup() {
  common_setup
  FAKE_ROOT="$TMPDIR_TEST/kstack"
  stage_dev_source "$FAKE_ROOT"
  RUN_INSTALL="$FAKE_ROOT/scripts/install"
}

@test "install --agent claude renders SKILL.md into .claude/skills/kstack-demo" {
  assert_file_exists "$FAKE_ROOT/.claude/skills/kstack-demo/SKILL.md"
}

@test "install (no --prefix) renders slots with kstack- prefix at kstack-<skill>/SKILL.md" {
  assert_file_exists "$FAKE_ROOT/.claude/skills/kstack-demo/SKILL.md"
  [ ! -e "$FAKE_ROOT/.claude/skills/demo" ]
}

@test "install --prefix=foo- renders slots at foo-<skill>/SKILL.md" {
  isolate_dev_setup
  run "$RUN_INSTALL" --agent claude --prefix=foo- --quiet
  [ "$status" -eq 0 ]
  assert_file_exists "$FAKE_ROOT/.claude/skills/foo-demo/SKILL.md"
  run grep -F "name: foo-demo" "$FAKE_ROOT/.claude/skills/foo-demo/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -F "skill_dir: $FAKE_ROOT/.claude/skills/foo-demo" "$FAKE_ROOT/.claude/skills/foo-demo/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "install --prefix (no value) exits 1" {
  run "$RUN_INSTALL" --agent claude --prefix
  [ "$status" -eq 1 ]
  [[ "$output" == *"Missing value for --prefix"* ]]
}

@test "install --prefix=bad/slash rejects invalid prefix" {
  run "$RUN_INSTALL" --agent claude --prefix=bad/slash
  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid --prefix"* ]]
}

@test "install --agent claude uses local paths in template output" {
  run grep -F "install_root: $FAKE_ROOT/.kstack" "$FAKE_ROOT/.claude/skills/kstack-demo/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -F "bin_dir: $FAKE_ROOT/.kstack/bin" "$FAKE_ROOT/.claude/skills/kstack-demo/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "install materializes bin/ under .kstack" {
  [ -x "$FAKE_ROOT/.kstack/bin/hello" ]
}

@test "install materializes entrypoint into .kstack/bin with exec bit" {
  isolate_dev_setup
  cp "$SRC_ROOT/bin/entrypoint" "$FAKE_ROOT/src/bin/entrypoint"
  chmod +x "$FAKE_ROOT/src/bin/entrypoint"
  run "$RUN_INSTALL" --agent claude --quiet
  [ "$status" -eq 0 ]
  [ -x "$FAKE_ROOT/.kstack/bin/entrypoint" ]
}

@test "rendered SKILL.md contains the entrypoint invocation" {
  run grep -F "$FAKE_ROOT/.kstack/bin/entrypoint" "$FAKE_ROOT/.claude/skills/kstack-demo/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -F -- "--skill-dir=$FAKE_ROOT/.claude/skills/kstack-demo" "$FAKE_ROOT/.claude/skills/kstack-demo/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "install materializes lib/ under .kstack" {
  [ -f "$FAKE_ROOT/.kstack/lib/cache.sh" ]
}

@test "install writes manifest/version under .kstack" {
  [ -f "$FAKE_ROOT/.kstack/manifest/version" ]
}

@test "install writes manifest/skills with one sorted slot per line (default prefix)" {
  [ -f "$FAKE_ROOT/.kstack/manifest/skills" ]
  run cat "$FAKE_ROOT/.kstack/manifest/skills"
  [ "$output" = "kstack-demo" ]
}

@test "install --no-prefix renders slots unprefixed at <skill>/SKILL.md" {
  isolate_dev_setup
  run "$RUN_INSTALL" --agent claude --no-prefix --quiet
  [ "$status" -eq 0 ]
  assert_file_exists "$FAKE_ROOT/.claude/skills/demo/SKILL.md"
  [ ! -e "$FAKE_ROOT/.claude/skills/kstack-demo" ]
}

@test "install --prefix= writes unprefixed slot names to manifest/skills" {
  isolate_dev_setup
  run "$RUN_INSTALL" --agent claude --prefix= --quiet
  [ "$status" -eq 0 ]
  run cat "$FAKE_ROOT/.kstack/manifest/skills"
  [ "$output" = "demo" ]
}

@test "install --prefix=foo- writes foo-prefixed slot names to manifest/skills" {
  isolate_dev_setup
  run "$RUN_INSTALL" --agent claude --prefix=foo- --quiet
  [ "$status" -eq 0 ]
  run cat "$FAKE_ROOT/.kstack/manifest/skills"
  [ "$output" = "foo-demo" ]
}

@test "install --agent codex writes to .codex/skills/kstack-demo" {
  isolate_dev_setup
  run "$RUN_INSTALL" --agent codex --quiet
  [ "$status" -eq 0 ]
  assert_file_exists "$FAKE_ROOT/.codex/skills/kstack-demo/SKILL.md"
}

@test "install --agent=opencode writes to .config/opencode/skills" {
  isolate_dev_setup
  run "$RUN_INSTALL" --agent=opencode --quiet
  [ "$status" -eq 0 ]
  assert_file_exists "$FAKE_ROOT/.config/opencode/skills/kstack-demo/SKILL.md"
}

@test "install --agent pi writes to .pi/skills/kstack-demo" {
  isolate_dev_setup
  run "$RUN_INSTALL" --agent pi --quiet
  [ "$status" -eq 0 ]
  assert_file_exists "$FAKE_ROOT/.pi/skills/kstack-demo/SKILL.md"
}

@test "install --agent nosuch exits 1 with 'Unknown agent'" {
  run "$RUN_INSTALL" --agent nosuch
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown agent: nosuch"* ]]
}

@test "install --agent without value exits 1" {
  run "$RUN_INSTALL" --agent
  [ "$status" -eq 1 ]
  [[ "$output" == *"Missing value for --agent"* ]]
}

@test "install rejects unknown option" {
  run "$RUN_INSTALL" --bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown option: --bogus"* ]]
}

@test "install creates .kstack/cache in dev mode" {
  [ -d "$FAKE_ROOT/.kstack/cache" ]
}

@test "install with no skills/ directory exits 1" {
  isolate_dev_setup
  rm -rf "$FAKE_ROOT/src/skills"
  run "$RUN_INSTALL" --agent claude --quiet
  [ "$status" -eq 1 ]
  [[ "$output" == *"No skills/ directory"* ]]
}

@test "install with missing global-flags partial exits 1" {
  isolate_dev_setup
  rm "$FAKE_ROOT/src/skills/_partials/global-flags.md"
  run "$RUN_INSTALL" --agent claude --quiet
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing partial"* ]]
}

@test "install with no agents auto-detected falls back to claude" {
  isolate_dev_setup
  # Empty PATH: no agent CLIs visible.
  run env PATH="/usr/bin:/bin" "$RUN_INSTALL" --quiet
  [ "$status" -eq 0 ]
  assert_file_exists "$FAKE_ROOT/.claude/skills/kstack-demo/SKILL.md"
}

@test "install --help prints usage and exits 0" {
  run "$RUN_INSTALL" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"kstack install"* ]]
  [[ "$output" == *"Usage:"* ]]
}

@test "install replaces stale symlink in skill slot" {
  isolate_dev_setup
  mkdir -p "$FAKE_ROOT/.claude/skills"
  ln -s /nonexistent "$FAKE_ROOT/.claude/skills/kstack-demo" 2>/dev/null || skip "symlinks not supported"
  run "$RUN_INSTALL" --agent claude --quiet
  [ "$status" -eq 0 ]
  [ ! -L "$FAKE_ROOT/.claude/skills/kstack-demo" ]
  [ -f "$FAKE_ROOT/.claude/skills/kstack-demo/SKILL.md" ]
}

@test "install replaces stale file blocking skill slot" {
  isolate_dev_setup
  mkdir -p "$FAKE_ROOT/.claude/skills"
  echo "stale" > "$FAKE_ROOT/.claude/skills/kstack-demo"
  run "$RUN_INSTALL" --agent claude --quiet
  [ "$status" -eq 0 ]
  [ -f "$FAKE_ROOT/.claude/skills/kstack-demo/SKILL.md" ]
}

@test "install renders help.md under references/ alongside SKILL.md" {
  assert_file_exists "$FAKE_ROOT/.claude/skills/kstack-demo/references/help.md"
}

@test "install creates references/ directory next to SKILL.md" {
  [ -d "$FAKE_ROOT/.claude/skills/kstack-demo/references" ]
}

@test "help.md contains the README skill body" {
  run grep -F "A fixture skill used by tests." "$FAKE_ROOT/.claude/skills/kstack-demo/references/help.md"
  [ "$status" -eq 0 ]
}

@test "help.md contains the global flags table" {
  run grep -F -e "--context <ctx>" "$FAKE_ROOT/.claude/skills/kstack-demo/references/help.md"
  [ "$status" -eq 0 ]
}

@test "help.md does not carry the legacy END HELP sentinel" {
  run grep -F "=== END HELP ===" "$FAKE_ROOT/.claude/skills/kstack-demo/references/help.md"
  [ "$status" -ne 0 ]
}

@test "install copies response schema into ROOT_DIR/schemas" {
  [ -f "$FAKE_ROOT/.kstack/schemas/response.schema.json" ]
  run grep -F 'kstack script response envelope' "$FAKE_ROOT/.kstack/schemas/response.schema.json"
  [ "$status" -eq 0 ]
}

@test "SKILL.md skill_dir placeholder resolves to rendered slot path" {
  run grep -F "skill_dir: $FAKE_ROOT/.claude/skills/kstack-demo" "$FAKE_ROOT/.claude/skills/kstack-demo/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "install aborts when README has no section for a skill" {
  isolate_dev_setup
  rm "$FAKE_ROOT/README.md"
  : > "$FAKE_ROOT/README.md"
  run "$RUN_INSTALL" --agent claude --quiet
  [ "$status" -ne 0 ]
  [[ "$output" == *"no README section for /demo"* ]]
}

@test "reinstall with different prefix prunes stale slots from previous prefix" {
  isolate_dev_setup
  run "$RUN_INSTALL" --agent claude --prefix=old- --quiet
  [ "$status" -eq 0 ]
  assert_file_exists "$FAKE_ROOT/.claude/skills/old-demo/SKILL.md"
  run "$RUN_INSTALL" --agent claude --prefix=new- --quiet
  [ "$status" -eq 0 ]
  [ ! -e "$FAKE_ROOT/.claude/skills/old-demo" ]
  assert_file_exists "$FAKE_ROOT/.claude/skills/new-demo/SKILL.md"
}

@test "install with empty prefix does not remove unrelated skills in the same skills_dir" {
  isolate_dev_setup
  mkdir -p "$FAKE_ROOT/.claude/skills/my-skill"
  echo "mine" > "$FAKE_ROOT/.claude/skills/my-skill/SKILL.md"
  run "$RUN_INSTALL" --agent claude --prefix= --quiet
  [ "$status" -eq 0 ]
  assert_file_exists "$FAKE_ROOT/.claude/skills/demo/SKILL.md"
  assert_file_exists "$FAKE_ROOT/.claude/skills/my-skill/SKILL.md"
}

@test "reinstall prunes slot whose source template was removed" {
  isolate_dev_setup
  mkdir -p "$FAKE_ROOT/src/skills/goner"
  cp "$FAKE_ROOT/src/skills/demo/SKILL.md.tmpl" "$FAKE_ROOT/src/skills/goner/SKILL.md.tmpl"
  # README must have a section for /goner so render_help succeeds.
  cat >> "$FAKE_ROOT/README.md" <<'EOF'

### Goner

<dl><dt>

#### `/goner`

</dt><dd>

Temporary.

</dd></dl>

---
EOF
  run "$RUN_INSTALL" --agent claude --quiet
  [ "$status" -eq 0 ]
  assert_file_exists "$FAKE_ROOT/.claude/skills/kstack-goner/SKILL.md"
  rm -rf "$FAKE_ROOT/src/skills/goner"
  run "$RUN_INSTALL" --agent claude --quiet
  [ "$status" -eq 0 ]
  [ ! -e "$FAKE_ROOT/.claude/skills/kstack-goner" ]
  assert_file_exists "$FAKE_ROOT/.claude/skills/kstack-demo/SKILL.md"
}

@test "install preserves non-kstack skill slot in the shared skills dir" {
  isolate_dev_setup
  run "$RUN_INSTALL" --agent claude --quiet
  [ "$status" -eq 0 ]
  mkdir -p "$FAKE_ROOT/.claude/skills/user-own"
  echo "mine" > "$FAKE_ROOT/.claude/skills/user-own/SKILL.md"
  run "$RUN_INSTALL" --agent claude --quiet
  [ "$status" -eq 0 ]
  assert_file_exists "$FAKE_ROOT/.claude/skills/user-own/SKILL.md"
}

@test "install logs each pruned skill slot" {
  isolate_dev_setup
  run "$RUN_INSTALL" --agent claude --prefix=old- --quiet
  [ "$status" -eq 0 ]
  run "$RUN_INSTALL" --agent claude --prefix=new-
  [ "$status" -eq 0 ]
  [[ "$output" == *"pruned: old-demo"* ]]
}

@test "install leaves an unmanaged dir alone even when its name shares the active prefix" {
  isolate_dev_setup
  mkdir -p "$FAKE_ROOT/.claude/skills/foo-ghost"
  echo "stale" > "$FAKE_ROOT/.claude/skills/foo-ghost/SKILL.md"
  run "$RUN_INSTALL" --agent claude --prefix=foo- --quiet
  [ "$status" -eq 0 ]
  assert_file_exists "$FAKE_ROOT/.claude/skills/foo-ghost/SKILL.md"
}

@test "install leaves current skill slot intact on idempotent rerun" {
  run "$RUN_INSTALL" --agent claude --quiet
  [ "$status" -eq 0 ]
  assert_file_exists "$FAKE_ROOT/.claude/skills/kstack-demo/SKILL.md"
}

@test "install copies skills/<name>/scripts/ into rendered slot as executable" {
  isolate_dev_setup
  mkdir -p "$FAKE_ROOT/src/skills/demo/scripts"
  cat > "$FAKE_ROOT/src/skills/demo/scripts/snapshot" <<'EOF'
#!/usr/bin/env bash
echo snap
EOF
  chmod +x "$FAKE_ROOT/src/skills/demo/scripts/snapshot"
  run "$RUN_INSTALL" --agent claude --quiet
  [ "$status" -eq 0 ]
  [ -x "$FAKE_ROOT/.claude/skills/kstack-demo/scripts/snapshot" ]
}

@test "install mirrors skills/<name>/scripts/ subdirs (e.g. scripts/lib)" {
  isolate_dev_setup
  mkdir -p "$FAKE_ROOT/src/skills/demo/scripts/lib"
  echo "#!/usr/bin/env bash" > "$FAKE_ROOT/src/skills/demo/scripts/snapshot"
  chmod +x "$FAKE_ROOT/src/skills/demo/scripts/snapshot"
  echo "helper() { echo hi; }" > "$FAKE_ROOT/src/skills/demo/scripts/lib/helper.sh"
  run "$RUN_INSTALL" --agent claude --quiet
  [ "$status" -eq 0 ]
  [ -x "$FAKE_ROOT/.claude/skills/kstack-demo/scripts/snapshot" ]
  [ -f "$FAKE_ROOT/.claude/skills/kstack-demo/scripts/lib/helper.sh" ]
}

@test "install rebuilds scripts/ slot when source files are removed" {
  isolate_dev_setup
  mkdir -p "$FAKE_ROOT/src/skills/demo/scripts/lib"
  echo "#!/usr/bin/env bash" > "$FAKE_ROOT/src/skills/demo/scripts/snapshot"
  chmod +x "$FAKE_ROOT/src/skills/demo/scripts/snapshot"
  echo "x=1" > "$FAKE_ROOT/src/skills/demo/scripts/lib/helper.sh"
  run "$RUN_INSTALL" --agent claude --quiet
  [ "$status" -eq 0 ]
  [ -d "$FAKE_ROOT/.claude/skills/kstack-demo/scripts/lib" ]
  rm -rf "$FAKE_ROOT/src/skills/demo/scripts/lib"
  run "$RUN_INSTALL" --agent claude --quiet
  [ "$status" -eq 0 ]
  [ ! -e "$FAKE_ROOT/.claude/skills/kstack-demo/scripts/lib" ]
  [ -x "$FAKE_ROOT/.claude/skills/kstack-demo/scripts/snapshot" ]
}

@test "install omits scripts/ slot when source skill has no scripts dir" {
  [ ! -e "$FAKE_ROOT/.claude/skills/kstack-demo/scripts" ]
}

@test "install prunes stale scripts/ slot when source dir is removed" {
  isolate_dev_setup
  mkdir -p "$FAKE_ROOT/src/skills/demo/scripts"
  echo "#!/usr/bin/env bash" > "$FAKE_ROOT/src/skills/demo/scripts/snapshot"
  chmod +x "$FAKE_ROOT/src/skills/demo/scripts/snapshot"
  run "$RUN_INSTALL" --agent claude --quiet
  [ "$status" -eq 0 ]
  [ -x "$FAKE_ROOT/.claude/skills/kstack-demo/scripts/snapshot" ]
  rm -rf "$FAKE_ROOT/src/skills/demo/scripts"
  run "$RUN_INSTALL" --agent claude --quiet
  [ "$status" -eq 0 ]
  [ ! -e "$FAKE_ROOT/.claude/skills/kstack-demo/scripts" ]
}

@test "install prunes orphan scripts when source dir shrinks" {
  isolate_dev_setup
  mkdir -p "$FAKE_ROOT/src/skills/demo/scripts"
  echo "#!/usr/bin/env bash" > "$FAKE_ROOT/src/skills/demo/scripts/snapshot"
  echo "#!/usr/bin/env bash" > "$FAKE_ROOT/src/skills/demo/scripts/extra"
  chmod +x "$FAKE_ROOT/src/skills/demo/scripts/snapshot" "$FAKE_ROOT/src/skills/demo/scripts/extra"
  run "$RUN_INSTALL" --agent claude --quiet
  [ "$status" -eq 0 ]
  [ -x "$FAKE_ROOT/.claude/skills/kstack-demo/scripts/extra" ]
  rm "$FAKE_ROOT/src/skills/demo/scripts/extra"
  run "$RUN_INSTALL" --agent claude --quiet
  [ "$status" -eq 0 ]
  [ -x "$FAKE_ROOT/.claude/skills/kstack-demo/scripts/snapshot" ]
  [ ! -e "$FAKE_ROOT/.claude/skills/kstack-demo/scripts/extra" ]
}
