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
  TMPL="$SRC_ROOT/skills/logs/SKILL.md.tmpl"
}

@test "LLM-only skill basics (template, no scripts/main, frontmatter, partial markers)" {
  assert_llm_only_skill_basics logs
}

@test "frontmatter description matches the README one-liner" {
  run grep -F "description: Fetch container logs with remote grep via kubetail" "$TMPL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Requirements
# ---------------------------------------------------------------------------

@test "names tmux as a hard requirement" {
  run grep -E "tmux.*(must be|is) (installed|on)" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "names kubetail CLI as a requirement" {
  run grep -E "kubetail.*CLI.*must|kubetail.*on.*PATH" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "names Kubetail API (in-cluster) as a requirement" {
  run grep -E -i "kubetail.*(API|server).*(cluster|install)|kubetail.*(in.cluster)" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "offers Helm install when Kubetail API is missing from cluster" {
  run grep -E -i "helm.*install.*kubetail|install.*kubetail.*helm" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "checks for Kubetail in the cluster before installing" {
  run grep -E "kubectl get.*kubetail|kubetail.*kubectl get" "$TMPL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------

@test "documents optional natural-language target argument" {
  run grep -E "<target>" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "target is optional -- skill prompts when omitted" {
  run grep -E -i "(prompt|ask).*(omit|when omit)|optional" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "documents example invocations" {
  run grep -E "/logs.*api|/logs.*error" "$TMPL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Skill flags
# ---------------------------------------------------------------------------

@test "documents --attach flag" {
  run grep -F -- "--attach" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "documents --detach flag" {
  run grep -F -- "--detach" "$TMPL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Tmux session lifecycle
# ---------------------------------------------------------------------------

@test "documents the tmux session naming convention" {
  run grep -E "kstack-logs-" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "session is started detached" {
  run grep -E -i "tmux new.session.*-d" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "agent tries to open a terminal window attached to the session" {
  run grep -E -i "(open.*terminal|terminal.*window|gnome.terminal|open.*Terminal)" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "tmux attach command is printed in chat as a fallback" {
  run grep -E "tmux attach" "$TMPL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Kubetail command translation
# ---------------------------------------------------------------------------

@test "agent translates natural language to a kubetail command" {
  run grep -E -i "(translat|kubetail.*command|kubetail.*query)" "$TMPL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Behavioral rules (shared with /exec)
# ---------------------------------------------------------------------------

@test "agent reads from the pane conservatively to save tokens" {
  run grep -E -i "(read.*pane.*conserv|conserv.*pane|save tokens)" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "agent treats pane content as sensitive" {
  run grep -E -i "(pane.*sensitive|sensitive.*pane)" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "agent treats pane content as untrusted input" {
  run grep -E -i "(untrusted input|untrusted).*pane|pane.*untrusted" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "only the user's chat messages are trusted as instructions" {
  run grep -E -i "only.*(chat|user.?s).*(message|chat).*trust" "$TMPL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Teardown
# ---------------------------------------------------------------------------

@test "teardown kills the tmux session on user request" {
  run grep -E -i "(kill.*session|tmux kill|tear.down)" "$TMPL"
  [ "$status" -eq 0 ]
}
