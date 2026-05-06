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
  TMPL="$SRC_ROOT/skills/investigate/SKILL.md.tmpl"
}

@test "LLM-only skill basics (template, no scripts/main, frontmatter, partial markers)" {
  assert_llm_only_skill_basics investigate
}

@test "frontmatter description matches the README one-liner" {
  run grep -F "description: Root-cause analysis across events, logs, and related resources" "$TMPL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Initial bundle — what the skill gathers up-front
# ---------------------------------------------------------------------------

@test "documents the Initial bundle section" {
  run grep -E -i "^## .*[Ii]nitial bundle" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "bundle includes spec and status of the target resource" {
  run grep -E -i "spec.*(and|\\+).*status|status.*(and|\\+).*spec" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "bundle includes events on the target AND its owners (Pod -> ReplicaSet -> Deployment, Job -> CronJob)" {
  run grep -E -i "owner" "$TMPL"
  [ "$status" -eq 0 ]
  run grep -F "ReplicaSet" "$TMPL"
  [ "$status" -eq 0 ]
  run grep -F "CronJob" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "bundle includes current and previous container logs" {
  run grep -F -- "--previous" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "logs are truncated to the lines most likely to contain the failure" {
  run grep -E -i "truncat" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "bundle includes obvious related resources (Service, ConfigMap, Secret, PVC, ServiceAccount)" {
  for kind in Service ConfigMap Secret PVC ServiceAccount; do
    run grep -F "$kind" "$TMPL"
    [ "$status" -eq 0 ] || { echo "missing related-resource kind: $kind"; return 1; }
  done
}

@test "ConfigMap/Secret are referenced by name only -- contents are never read" {
  run grep -E -i "(name.*only|never read|contents).*(secret|configmap)|(secret|configmap).*(name.*only|never read|contents)" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "bundle includes node info (conditions, capacity, pressure) when relevant" {
  run grep -E -i "node" "$TMPL"
  [ "$status" -eq 0 ]
  run grep -E -i "condition" "$TMPL"
  [ "$status" -eq 0 ]
  run grep -E -i "(capacity|pressure)" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "data source is Kubernetes API only" {
  run grep -E -i "Kubernetes API only" "$TMPL"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Briefing — how the agent should read the data
# ---------------------------------------------------------------------------

@test "agent knows how to read the bundle (exit codes, event reasons, state combinations)" {
  run grep -E -i "exit code" "$TMPL"
  [ "$status" -eq 0 ]
  run grep -E -i "event reason" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "follow-ups that need current state re-fetch instead of reasoning from the stale bundle" {
  run grep -F "Don't reason from the stale bundle" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "scoped event watch is available for ongoing observation" {
  run grep -E "kubectl get events" "$TMPL"
  [ "$status" -eq 0 ]
  run grep -E -- "--watch" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "documents handoffs to /logs, /exec, and /metrics" {
  for skill in /logs /exec /metrics; do
    run grep -F "$skill" "$TMPL"
    [ "$status" -eq 0 ] || { echo "missing handoff to: $skill"; return 1; }
  done
}

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------

@test "documents target argument supporting kind/name and natural language" {
  run grep -E "<kind>/<name>|kind/name" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "target is optional -- skill prompts when omitted" {
  run grep -E -i "(prompt|ask).*(when|if).*omitted|optional" "$TMPL"
  [ "$status" -eq 0 ]
}

@test "no skill-specific flags (Options: none)" {
  run grep -E -i "no skill.specific flag|skill takes no flag|options:.*none" "$TMPL"
  [ "$status" -eq 0 ]
}
