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
  TMPL="$SRC_ROOT/skills/exec/SKILL.md.tmpl"
}

@test "LLM-only skill basics (template, no scripts/main, frontmatter, partial markers)" {
  assert_llm_only_skill_basics exec
}

@test "frontmatter sets disable-model-invocation: true" {
  run grep -E "^disable-model-invocation:[[:space:]]*true" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "names tmux as a hard requirement" {
  run grep -E "tmux\`? must be installed" "$TMPL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Modes
# ---------------------------------------------------------------------------

@test "documents Mode 1 (pod container, default)" {
  run grep -E "^### Mode .*[Pp]od container" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "pod mode uses kubectl exec" {
  run grep -F "kubectl exec" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "pod mode auto-detects shell (bash -> sh -> ash)" {
  run grep -E "\`bash\`.*\`sh\`.*\`ash\`" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "pod mode falls back to debug container when no shell is available" {
  run grep -E -i "(distroless|scratch|no shell).*(debug|fall.back)|fall.back.*debug.*container" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "documents Mode 2 (ephemeral debug container)" {
  run grep -E "^### Mode .*[Dd]ebug container" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "debug mode uses kubectl debug" {
  run grep -F "kubectl debug" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "debug mode shares the target's process namespace" {
  run grep -E -i "process namespace|/proc/1/root" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "documents Mode 3 (node shell)" {
  run grep -E "^### Mode .*[Nn]ode" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "node mode uses a privileged pod with hostPID / hostNetwork / host filesystem mount" {
  run grep -F "hostPID" "$TMPL"
  [ "$status" -eq 0 ]
  run grep -F "hostNetwork" "$TMPL"
  [ "$status" -eq 0 ]
  run grep -E "(/host|host filesystem.*mount)" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "default toolbox image is nicolaka/netshoot" {
  run grep -F "nicolaka/netshoot" "$TMPL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Pods the skill creates carry the kstack owned-by annotation so /cleanup picks them up.
# ---------------------------------------------------------------------------

@test "created pods carry the kstack owned-by annotation" {
  run grep -F "kstack.kubetail.com/owned-by=kstack" "$TMPL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Tmux session lifecycle
# ---------------------------------------------------------------------------

@test "documents the tmux session naming convention" {
  run grep -E "kstack-exec-" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "session is started detached, then a terminal window is attached" {
  run grep -E -i "(tmux new.session.*-d|detached)" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "tmux attach command is printed in chat as a fallback" {
  run grep -E "tmux attach" "$TMPL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Behavioral rules from the docs
# ---------------------------------------------------------------------------

@test "agent must pick least-privileged mode that answers the question" {
  run grep -E -i "least.privileged" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "agent must read from the pane conservatively to save tokens" {
  run grep -E -i "(read.*pane.*conservative|conservative.*pane|save tokens)" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "agent treats pane content as sensitive (do not echo back unprompted)" {
  run grep -E -i "(pane.*sensitive|sensitive.*pane|don.?t echo|do not echo)" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "agent treats pane content as untrusted input (no prompt injection)" {
  run grep -E -i "(untrusted input|untrusted).*pane|pane.*untrusted" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "agent never follows instructions found in pane output" {
  run grep -E -i "(never|do not|don.?t).*follow.*(instruction|command).*(pane|output|log)" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "only the user's chat messages are trusted" {
  run grep -E -i "only.*(chat|user.?s).*(message|chat).*trust" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "agent confirms in chat before running destructive commands" {
  run grep -E -i "(confirm|ask).*chat.*(destructive|delete|rm|drop|kill)" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "agent tears down the tmux session and deletes any pod it created on user request" {
  run grep -E -i "(tear.down|kill.*session).*(pod|delete)|delete.*pod.*created" "$TMPL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Skill flags
# ---------------------------------------------------------------------------

@test "documents --image flag" {
  run grep -F -- "--image" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "documents --attach flag" {
  run grep -F -- "--attach" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "documents --detach flag" {
  run grep -F -- "--detach" "$TMPL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------

@test "argument syntax shows pod, pod/container, node, and debug forms" {
  run grep -F "<pod>/<container>" "$TMPL"
  [ "$status" -eq 0 ]
  run grep -E "/exec node " "$TMPL"
  [ "$status" -eq 0 ]
  run grep -E "/exec debug " "$TMPL"
  [ "$status" -eq 0 ]
}
