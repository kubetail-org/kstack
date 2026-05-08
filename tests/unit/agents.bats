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
  . "$SRC_ROOT/lib/agents.sh"
}

@test "agent_cli maps claude to claude" {
  run agent_cli claude
  [ "$status" -eq 0 ]
  [ "$output" = "claude" ]
}

@test "agent_cli maps factory to droid" {
  run agent_cli factory
  [ "$status" -eq 0 ]
  [ "$output" = "droid" ]
}

@test "agent_cli maps kiro to kiro-cli" {
  run agent_cli kiro
  [ "$status" -eq 0 ]
  [ "$output" = "kiro-cli" ]
}

@test "agent_cli maps pi to pi" {
  run agent_cli pi
  [ "$status" -eq 0 ]
  [ "$output" = "pi" ]
}

@test "agent_cli returns non-zero for unknown agent" {
  run agent_cli nosuch
  [ "$status" -ne 0 ]
}

@test "agent_skills_dir_global claude" {
  run agent_skills_dir_global claude
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.claude/skills" ]
}

@test "agent_skills_dir_global opencode uses \$HOME/.config/opencode" {
  run agent_skills_dir_global opencode
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.config/opencode/skills" ]
}

@test "agent_skills_dir_global pi" {
  run agent_skills_dir_global pi
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.pi/agent/skills" ]
}

@test "agent_skills_dir_global returns non-zero for unknown" {
  run agent_skills_dir_global nosuch
  [ "$status" -ne 0 ]
}

@test "agent_skills_dir_local uses passed repo root" {
  run agent_skills_dir_local /opt/kstack claude
  [ "$status" -eq 0 ]
  [ "$output" = "/opt/kstack/.claude/skills" ]
}

@test "agent_skills_dir_local opencode" {
  run agent_skills_dir_local /opt/kstack opencode
  [ "$status" -eq 0 ]
  [ "$output" = "/opt/kstack/.config/opencode/skills" ]
}

@test "agent_skills_dir_local pi" {
  run agent_skills_dir_local /opt/kstack pi
  [ "$status" -eq 0 ]
  [ "$output" = "/opt/kstack/.pi/skills" ]
}

@test "is_known_agent accepts all KNOWN_AGENTS" {
  for a in claude codex opencode cursor factory slate kiro hermes pi; do
    run is_known_agent "$a"
    [ "$status" -eq 0 ] || { echo "$a should be known"; return 1; }
  done
}

@test "is_known_agent rejects unknown" {
  run is_known_agent nosuch
  [ "$status" -ne 0 ]
}

@test "is_known_agent rejects prefix substring (claude-foo)" {
  run is_known_agent claude-foo
  [ "$status" -ne 0 ]
}

@test "KNOWN_AGENTS lists all nine agents" {
  set -- $KNOWN_AGENTS
  [ "$#" -eq 9 ]
}
