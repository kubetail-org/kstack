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

  # Stage a fake global install: config dir, lib, bin, a manifest/skills
  # file, and the slot dirs the manifest references.
  mkdir -p "$HOME/.config/kstack/bin" "$HOME/.config/kstack/lib" \
           "$HOME/.config/kstack/manifest"
  cp "$SRC_ROOT/bin/uninstall" "$HOME/.config/kstack/bin/uninstall"
  cp "$SRC_ROOT/lib/agents.sh" "$HOME/.config/kstack/lib/agents.sh"
  cp "$SRC_ROOT/lib/manifest.sh" "$HOME/.config/kstack/lib/manifest.sh"
  chmod +x "$HOME/.config/kstack/bin/uninstall"
  printf '%s\n' kstack-demo kstack-other > "$HOME/.config/kstack/manifest/skills"

  mkdir -p "$HOME/.claude/skills/kstack-demo" "$HOME/.claude/skills/kstack-other"
  mkdir -p "$HOME/.claude/skills/non-kstack"  # must NOT be removed
  mkdir -p "$HOME/.codex/skills/kstack-demo"
  mkdir -p "$HOME/.pi/agent/skills/kstack-demo"

  UNINSTALL="$HOME/.config/kstack/bin/uninstall"
}

@test "uninstall --force removes every manifest-listed slot dir and config dir" {
  run "$UNINSTALL" --force
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.claude/skills/kstack-demo" ]
  [ ! -e "$HOME/.claude/skills/kstack-other" ]
  [ ! -e "$HOME/.codex/skills/kstack-demo" ]
  [ ! -e "$HOME/.pi/agent/skills/kstack-demo" ]
  [ ! -e "$HOME/.config/kstack" ]
}

@test "uninstall --force removes unprefixed slots when manifest lists them" {
  printf '%s\n' demo other > "$HOME/.config/kstack/manifest/skills"
  mkdir -p "$HOME/.claude/skills/demo" "$HOME/.claude/skills/other"
  run "$UNINSTALL" --force
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.claude/skills/demo" ]
  [ ! -e "$HOME/.claude/skills/other" ]
  # Dirs that happen to share the old prefix are NOT removed — they weren't
  # in the manifest, so they belong to someone else.
  [ -e "$HOME/.claude/skills/kstack-demo" ]
  [ ! -e "$HOME/.config/kstack" ]
}

@test "uninstall leaves kstack-* dirs alone when they are not in the manifest" {
  printf '%s\n' demo > "$HOME/.config/kstack/manifest/skills"
  mkdir -p "$HOME/.claude/skills/demo"
  run "$UNINSTALL" --force
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.claude/skills/demo" ]
  [ -d "$HOME/.claude/skills/kstack-demo" ]
  [ -d "$HOME/.claude/skills/kstack-other" ]
}

@test "uninstall with empty manifest removes only ROOT_DIR" {
  : > "$HOME/.config/kstack/manifest/skills"
  run "$UNINSTALL" --force
  [ "$status" -eq 0 ]
  [ -d "$HOME/.claude/skills/kstack-demo" ]
  [ ! -e "$HOME/.config/kstack" ]
}

@test "uninstall --force leaves non-kstack skills untouched" {
  run "$UNINSTALL" --force
  [ "$status" -eq 0 ]
  [ -d "$HOME/.claude/skills/non-kstack" ]
}

@test "uninstall --force --agent claude scopes to one agent" {
  run "$UNINSTALL" --force --agent claude
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.claude/skills/kstack-demo" ]
  # codex/pi dirs still exist as dirs (config dir is still removed though).
  [ -e "$HOME/.codex/skills/kstack-demo" ]
  [ -e "$HOME/.pi/agent/skills/kstack-demo" ]
}

@test "uninstall --force --agent pi removes pi global skill slots" {
  run "$UNINSTALL" --force --agent pi
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.pi/agent/skills/kstack-demo" ]
  [ -e "$HOME/.claude/skills/kstack-demo" ]
}

@test "uninstall --agent nosuch exits 1" {
  run "$UNINSTALL" --force --agent nosuch
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown agent: nosuch"* ]]
}

@test "uninstall interactive 'n' aborts without removing" {
  run bash -c "echo n | '$UNINSTALL'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Aborted."* ]]
  [ -e "$HOME/.claude/skills/kstack-demo" ]
  [ -e "$HOME/.config/kstack" ]
}

@test "uninstall interactive 'y' removes" {
  run bash -c "echo y | '$UNINSTALL'"
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.claude/skills/kstack-demo" ]
  [ ! -e "$HOME/.config/kstack" ]
}

@test "uninstall exits 1 when not bundled into a recognized install root" {
  local elsewhere="$TMPDIR_TEST/elsewhere/bin"
  mkdir -p "$elsewhere" "$TMPDIR_TEST/elsewhere/lib"
  cp "$SRC_ROOT/bin/uninstall" "$elsewhere/uninstall"
  cp "$SRC_ROOT/lib/agents.sh" "$TMPDIR_TEST/elsewhere/lib/agents.sh"
  cp "$SRC_ROOT/lib/manifest.sh" "$TMPDIR_TEST/elsewhere/lib/manifest.sh"
  chmod +x "$elsewhere/uninstall"

  run "$elsewhere/uninstall" --force
  [ "$status" -eq 1 ]
  [[ "$output" == *"bundled install location"* ]]
}

@test "uninstall rejects unknown option" {
  run "$UNINSTALL" --bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown option: --bogus"* ]]
}

@test "uninstall --help prints usage and exits 0" {
  run "$UNINSTALL" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"kstack uninstall"* ]]
}

@test "uninstall --force --agent pi in local layout removes .pi/skills slots" {
  PROJECT="$TMPDIR_TEST/pi-proj"
  ROOT="$PROJECT/.kstack"
  mkdir -p "$ROOT/bin" "$ROOT/lib" "$ROOT/upstream" "$ROOT/manifest"
  git init --quiet "$ROOT/upstream"
  cp "$SRC_ROOT/bin/uninstall" "$ROOT/bin/uninstall"
  cp "$SRC_ROOT/lib/agents.sh" "$ROOT/lib/agents.sh"
  cp "$SRC_ROOT/lib/manifest.sh" "$ROOT/lib/manifest.sh"
  chmod +x "$ROOT/bin/uninstall"
  printf '%s\n' demo > "$ROOT/manifest/skills"

  mkdir -p "$PROJECT/.pi/skills/demo" "$PROJECT/.pi/skills/user-own"
  echo "kstack" > "$PROJECT/.pi/skills/demo/SKILL.md"
  echo "mine"   > "$PROJECT/.pi/skills/user-own/SKILL.md"

  run "$ROOT/bin/uninstall" --force --agent pi
  [ "$status" -eq 0 ]
  [ ! -e "$ROOT" ]
  [ ! -e "$PROJECT/.pi/skills/demo" ]
  [ -f "$PROJECT/.pi/skills/user-own/SKILL.md" ]
}

@test "uninstall --force in local layout removes .kstack and scoped skill slots" {
  # Stage a fake local install: <project>/.kstack/{bin,lib,upstream/.git,…}.
  # Mode detection only needs upstream/.git to exist; slot targets are read
  # from manifest/skills.
  PROJECT="$TMPDIR_TEST/proj"
  ROOT="$PROJECT/.kstack"
  mkdir -p "$ROOT/bin" "$ROOT/lib" "$ROOT/upstream" "$ROOT/manifest"
  git init --quiet "$ROOT/upstream"
  cp "$SRC_ROOT/bin/uninstall" "$ROOT/bin/uninstall"
  cp "$SRC_ROOT/lib/agents.sh" "$ROOT/lib/agents.sh"
  cp "$SRC_ROOT/lib/manifest.sh" "$ROOT/lib/manifest.sh"
  chmod +x "$ROOT/bin/uninstall"
  printf '%s\n' demo > "$ROOT/manifest/skills"

  mkdir -p "$PROJECT/.claude/skills/demo" "$PROJECT/.claude/skills/user-own"
  echo "kstack" > "$PROJECT/.claude/skills/demo/SKILL.md"
  echo "mine"   > "$PROJECT/.claude/skills/user-own/SKILL.md"

  run "$ROOT/bin/uninstall" --force
  [ "$status" -eq 0 ]
  [ ! -e "$ROOT" ]
  [ ! -e "$PROJECT/.claude/skills/demo" ]
  # User-authored skill in the same dir survives.
  [ -f "$PROJECT/.claude/skills/user-own/SKILL.md" ]
}
