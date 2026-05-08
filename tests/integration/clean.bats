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

  # Stage a fake repo with the script + some artifacts to clean.
  # Mirror the real layout: script lives at <repo>/scripts/clean.sh.
  FAKE_REPO="$TMPDIR_TEST/fake-repo"
  mkdir -p "$FAKE_REPO/scripts"
  cp "$REPO_ROOT/scripts/clean.sh" "$FAKE_REPO/scripts/clean.sh"
  chmod +x "$FAKE_REPO/scripts/clean.sh"
  CLEAN="$FAKE_REPO/scripts/clean.sh"
}

@test "clean.sh removes every listed path that exists" {
  mkdir -p "$FAKE_REPO/.claude/skills" "$FAKE_REPO/.kstack/cache" "$FAKE_REPO/.codex" "$FAKE_REPO/.pi/skills"

  run "$CLEAN"
  [ "$status" -eq 0 ]
  [ ! -e "$FAKE_REPO/.claude" ]
  [ ! -e "$FAKE_REPO/.kstack" ]
  [ ! -e "$FAKE_REPO/.codex" ]
  [ ! -e "$FAKE_REPO/.pi/skills" ]
}

@test "clean.sh reports 'Nothing to clean.' when nothing present" {
  run "$CLEAN"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Nothing to clean."* ]]
}

@test "clean.sh leaves non-listed paths alone" {
  mkdir -p "$FAKE_REPO/src" "$FAKE_REPO/.claude" "$FAKE_REPO/.pi/extensions"
  echo '{}' > "$FAKE_REPO/.pi/settings.json"
  run "$CLEAN"
  [ "$status" -eq 0 ]
  [ -d "$FAKE_REPO/src" ]
  [ ! -e "$FAKE_REPO/.claude" ]
  [ -d "$FAKE_REPO/.pi/extensions" ]
  [ -f "$FAKE_REPO/.pi/settings.json" ]
}

@test "clean.sh prints 'removed' line per path" {
  mkdir -p "$FAKE_REPO/.claude" "$FAKE_REPO/.codex" "$FAKE_REPO/.pi/skills"
  run "$CLEAN"
  [ "$status" -eq 0 ]
  [[ "$output" == *"removed .claude"* ]]
  [[ "$output" == *"removed .codex"* ]]
  [[ "$output" == *"removed .pi/skills"* ]]
}
