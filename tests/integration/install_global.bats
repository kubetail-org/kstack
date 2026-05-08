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

# install --global mode: clones $KSTACK_REMOTE_URL at the latest v* tag into
# $HOME/.config/kstack/upstream and renders skills into $HOME/.<agent>/skills/.
#
# setup_file stages the upstream + runs one baseline install into a shared
# $HOME. Tests assert against that shared tree. Tests that would invalidate
# the baseline (e.g. re-installing with a different prefix, which prunes the
# existing demo/ slot) call common_setup to get their own per-test $HOME.

setup_file() {
  load '../test_helper.bash'
  common_setup_file

  stage_fake_upstream "$TMPDIR_FILE"

  RUN_INSTALL="$REPO_ROOT/scripts/install"
  export RUN_INSTALL

  # Baseline install — shared by every test that just reads output.
  "$RUN_INSTALL" --global --agent claude --quiet
}

setup() {
  load '../test_helper.bash'
}

@test "install --global clones bare repo at latest tag and writes manifest/version" {
  [ -f "$HOME/.config/kstack/manifest/version" ]
  run cat "$HOME/.config/kstack/manifest/version"
  [ "$output" = "v1.2.3" ]
}

@test "install --global renders skills into \$HOME/.claude/skills/kstack-<name> (kstack- prefix by default)" {
  assert_file_exists "$HOME/.claude/skills/kstack-demo/SKILL.md"
  run grep -F "install_root: $HOME/.config/kstack" "$HOME/.claude/skills/kstack-demo/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -F "bin_dir: $HOME/.config/kstack/bin" "$HOME/.claude/skills/kstack-demo/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "install --global substitutes SKILL_DIR to the rendered slot path" {
  run grep -F "skill_dir: $HOME/.claude/skills/kstack-demo" "$HOME/.claude/skills/kstack-demo/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "install --global substitutes SKILL_NAME to the kstack-prefixed slot name" {
  run grep -F "name: kstack-demo" "$HOME/.claude/skills/kstack-demo/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "install --global copies skills/<name>/scripts/ into rendered slot" {
  [ -x "$HOME/.claude/skills/kstack-demo/scripts/snapshot" ]
}

@test "install --global --agent pi renders into \$HOME/.pi/agent/skills" {
  common_setup
  run "$RUN_INSTALL" --global --agent pi --quiet
  [ "$status" -eq 0 ]
  assert_file_exists "$HOME/.pi/agent/skills/kstack-demo/SKILL.md"
}

@test "install --global copies bin/ helpers to \$HOME/.config/kstack/bin" {
  [ -x "$HOME/.config/kstack/bin/hello" ]
}

@test "install --global copies lib/ to \$HOME/.config/kstack/lib" {
  [ -f "$HOME/.config/kstack/lib/agents.sh" ]
  [ -f "$HOME/.config/kstack/lib/cache.sh" ]
}

@test "install --global re-run uses fetch+checkout path" {
  run "$RUN_INSTALL" --global --agent claude --quiet
  [ "$status" -eq 0 ]
  assert_file_exists "$HOME/.claude/skills/kstack-demo/SKILL.md"
}

@test "install --global reinstall with different prefix prunes prior-prefix slots" {
  # Isolated HOME — this test reinstalls with a non-empty prefix, which would
  # prune the shared baseline's demo/ slot and break later assertions.
  common_setup
  run "$RUN_INSTALL" --global --agent claude --prefix=old- --quiet
  [ "$status" -eq 0 ]
  assert_file_exists "$HOME/.claude/skills/old-demo/SKILL.md"
  run "$RUN_INSTALL" --global --agent claude --prefix=new- --quiet
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.claude/skills/old-demo" ]
  assert_file_exists "$HOME/.claude/skills/new-demo/SKILL.md"
}

@test "install --global preserves non-kstack skill slot in shared skills dir" {
  mkdir -p "$HOME/.claude/skills/user-own"
  echo "mine" > "$HOME/.claude/skills/user-own/SKILL.md"
  run "$RUN_INSTALL" --global --agent claude --quiet
  [ "$status" -eq 0 ]
  assert_file_exists "$HOME/.claude/skills/kstack-demo/SKILL.md"
  assert_file_exists "$HOME/.claude/skills/user-own/SKILL.md"
}

@test "install --global prunes orphan helper from \$HOME/.config/kstack/bin" {
  echo "#!/bin/sh" > "$HOME/.config/kstack/bin/ghost-helper"
  chmod +x "$HOME/.config/kstack/bin/ghost-helper"
  run "$RUN_INSTALL" --global --agent claude --quiet
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.config/kstack/bin/ghost-helper" ]
  [ -x "$HOME/.config/kstack/bin/hello" ]
}

@test "install --global prunes orphan .sh file from \$HOME/.config/kstack/lib" {
  echo "# stale" > "$HOME/.config/kstack/lib/ghost.sh"
  run "$RUN_INSTALL" --global --agent claude --quiet
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.config/kstack/lib/ghost.sh" ]
  [ -f "$HOME/.config/kstack/lib/agents.sh" ]
  [ -f "$HOME/.config/kstack/lib/cache.sh" ]
}
