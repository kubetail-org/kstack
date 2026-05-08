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

# install --local mode: clones a kstack-owned upstream into $PWD/.kstack/
# and renders skills into $PWD/.<agent>/skills/<name>/ (bare by default,
# namespaced when --prefix is passed).
#
# setup_file stages the upstream + runs one baseline install into a shared
# PROJECT. Tests assert against that shared tree; the handful of tests that
# re-run install do so idempotently (the re-run is just another no-op against
# an already-installed project).

setup_file() {
  load '../test_helper.bash'
  common_setup_file

  stage_fake_upstream "$TMPDIR_FILE"

  # PROJECT is the user's project dir — where --local drops .kstack/.
  PROJECT="$TMPDIR_FILE/proj"
  mkdir -p "$PROJECT"
  export PROJECT

  RUN_INSTALL="$REPO_ROOT/scripts/install"
  export RUN_INSTALL

  # Baseline install — shared by every test that just reads output.
  (cd "$PROJECT" && "$RUN_INSTALL" --local --agent claude --quiet)
}

setup() {
  load '../test_helper.bash'
  cd "$PROJECT"
}

@test "install --local clones bare repo into \$PWD/.kstack/upstream at latest tag" {
  [ -d "$PROJECT/.kstack/upstream/.git" ]
  [ -f "$PROJECT/.kstack/manifest/version" ]
  run cat "$PROJECT/.kstack/manifest/version"
  [ "$output" = "v1.2.3" ]
}

@test "install --local renders skills into \$PWD/.claude/skills/kstack-<name> (kstack- prefix by default)" {
  assert_file_exists "$PROJECT/.claude/skills/kstack-demo/SKILL.md"
  [ ! -e "$PROJECT/.claude/skills/demo" ]
}

@test "install --local substitutes local install root and bin dir into template" {
  run grep -F "install_root: $PROJECT/.kstack" "$PROJECT/.claude/skills/kstack-demo/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -F "bin_dir: $PROJECT/.kstack/bin" "$PROJECT/.claude/skills/kstack-demo/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "install --local substitutes SKILL_DIR to the local rendered slot path" {
  run grep -F "skill_dir: $PROJECT/.claude/skills/kstack-demo" "$PROJECT/.claude/skills/kstack-demo/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "install --local substitutes SKILL_NAME with the kstack-prefixed slot name" {
  run grep -F "name: kstack-demo" "$PROJECT/.claude/skills/kstack-demo/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "install --local copies skills/<name>/scripts/ into rendered slot" {
  [ -x "$PROJECT/.claude/skills/kstack-demo/scripts/snapshot" ]
}

@test "install --local --agent pi renders into \$PWD/.pi/skills" {
  local pi_project="$BATS_TEST_TMPDIR/pi-proj"
  mkdir -p "$pi_project"
  run bash -c "cd '$pi_project' && '$RUN_INSTALL' --local --agent pi --quiet"
  [ "$status" -eq 0 ]
  assert_file_exists "$pi_project/.pi/skills/kstack-demo/SKILL.md"
}

@test "install --local copies bin/ helpers under \$PWD/.kstack/bin" {
  [ -x "$PROJECT/.kstack/bin/hello" ]
}

@test "install --local copies lib/ under \$PWD/.kstack/lib" {
  [ -f "$PROJECT/.kstack/lib/agents.sh" ]
  [ -f "$PROJECT/.kstack/lib/cache.sh" ]
}

@test "install --local re-run updates the existing upstream checkout" {
  run "$RUN_INSTALL" --local --agent claude --quiet
  [ "$status" -eq 0 ]
  assert_file_exists "$PROJECT/.claude/skills/kstack-demo/SKILL.md"
}

@test "install --local preserves non-kstack skill slot in the shared skills dir" {
  mkdir -p "$PROJECT/.claude/skills/user-own"
  echo "mine" > "$PROJECT/.claude/skills/user-own/SKILL.md"
  run "$RUN_INSTALL" --local --agent claude --quiet
  [ "$status" -eq 0 ]
  assert_file_exists "$PROJECT/.claude/skills/kstack-demo/SKILL.md"
  assert_file_exists "$PROJECT/.claude/skills/user-own/SKILL.md"
}

@test "install --local and --global are mutually exclusive" {
  run "$RUN_INSTALL" --local --global --agent claude --quiet
  [ "$status" -eq 1 ]
  [[ "$output" == *"mutually exclusive"* ]]
}
