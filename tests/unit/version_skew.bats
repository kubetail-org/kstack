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

# Unit tests for src/skills/audit-outdated/scripts/lib/version-skew.sh.

setup() {
  load '../test_helper.bash'
  common_setup
  use_mocks

  SKILL_SCRIPTS="$SRC_ROOT/skills/audit-outdated/scripts"
  # shellcheck source=/dev/null
  . "$SKILL_SCRIPTS/lib/version-skew.sh"
}

# --- Fixture helpers ---

# _write_cluster_json <server_version>
#   Write a minimal cluster.json (kubectl version -o json) to $TMPDIR_TEST.
_write_cluster_json() {
  local ver="$1"
  cat > "$TMPDIR_TEST/cluster.json" <<EOF
{
  "serverVersion": {
    "major": "${ver%%.*}",
    "minor": "$(echo "$ver" | cut -d. -f2)",
    "gitVersion": "v${ver}"
  }
}
EOF
}

# _write_nodes_json <version>...
#   Write a minimal nodes.json with one node per version argument.
_write_nodes_json() {
  local items=""
  local i=0
  for ver in "$@"; do
    [ $i -gt 0 ] && items+=","
    items+="$(cat <<EOF
{
  "metadata": {"name": "node-$i"},
  "status": {
    "nodeInfo": {
      "kubeletVersion": "v${ver}"
    }
  }
}
EOF
)"
    i=$(( i + 1 ))
  done
  cat > "$TMPDIR_TEST/nodes.json" <<EOF
{"kind":"NodeList","items":[$items]}
EOF
}

# _stub_curl_endoflife <json_body>
#   Stub curl to return the given JSON for endoflife.date requests.
_stub_curl_endoflife() {
  local body="$1"
  write_stub curl "
printf '%s' '$body'
"
}

# _stub_curl_fail
#   Stub curl to fail (simulates unreachable API).
_stub_curl_fail() {
  write_stub curl "exit 1"
}

# --- Tests ---

@test "render: all nodes match control plane -- reports no skew" {
  _write_cluster_json "1.31.2"
  _write_nodes_json "1.31.2" "1.31.2" "1.31.2"
  _stub_curl_endoflife '{"name":"1.31","eolFrom":"2025-10","isEol":false}'

  run version_skew::render "$TMPDIR_TEST/cluster.json" "$TMPDIR_TEST/nodes.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"v1.31.2"* ]]
  [[ "$output" == *"3/3 match"* ]]
}

@test "render: one node behind -- reports skew" {
  _write_cluster_json "1.31.2"
  _write_nodes_json "1.31.2" "1.30.1" "1.31.2"
  _stub_curl_endoflife '{"name":"1.31","eolFrom":"2025-10","isEol":false}'

  run version_skew::render "$TMPDIR_TEST/cluster.json" "$TMPDIR_TEST/nodes.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"1 behind"* ]]
}

@test "render: multiple nodes behind -- reports count" {
  _write_cluster_json "1.31.0"
  _write_nodes_json "1.30.0" "1.29.5" "1.31.0"
  _stub_curl_endoflife '{"name":"1.31","eolFrom":"2025-10","isEol":false}'

  run version_skew::render "$TMPDIR_TEST/cluster.json" "$TMPDIR_TEST/nodes.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"2 behind"* ]]
}

@test "render: EOL version -- shows end-of-life from API data" {
  _write_cluster_json "1.27.0"
  _write_nodes_json "1.27.0"
  _stub_curl_endoflife '{"name":"1.27","eolFrom":"2024-06-28","isEol":true}'

  run version_skew::render "$TMPDIR_TEST/cluster.json" "$TMPDIR_TEST/nodes.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"End-of-life"* ]] || [[ "$output" == *"end-of-life"* ]]
  [[ "$output" == *"2024-06"* ]]
}

@test "render: supported version -- shows support date from API data" {
  _write_cluster_json "1.34.0"
  _write_nodes_json "1.34.0"
  _stub_curl_endoflife '{"name":"1.34","eolFrom":"2026-10-28","isEol":false}'

  run version_skew::render "$TMPDIR_TEST/cluster.json" "$TMPDIR_TEST/nodes.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Supported"* ]] || [[ "$output" == *"supported"* ]]
  [[ "$output" == *"2026-10"* ]]
}

@test "render: API unreachable -- shows unable to fetch message" {
  _write_cluster_json "1.31.0"
  _write_nodes_json "1.31.0"
  _stub_curl_fail

  run version_skew::render "$TMPDIR_TEST/cluster.json" "$TMPDIR_TEST/nodes.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"unable to fetch"* ]] || [[ "$output" == *"Unable to fetch"* ]]
}

@test "render: missing cluster.json -- returns error" {
  _write_nodes_json "1.31.0"

  run version_skew::render "$TMPDIR_TEST/nonexistent.json" "$TMPDIR_TEST/nodes.json"
  [ "$status" -ne 0 ]
}

@test "render: single node -- no plural in output" {
  _write_cluster_json "1.31.0"
  _write_nodes_json "1.31.0"
  _stub_curl_endoflife '{"name":"1.31","eolFrom":"2025-10","isEol":false}'

  run version_skew::render "$TMPDIR_TEST/cluster.json" "$TMPDIR_TEST/nodes.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"1/1 match"* ]]
}

@test "render: version not in API response -- shows unable to determine" {
  _write_cluster_json "1.99.0"
  _write_nodes_json "1.99.0"
  # Per-cycle endpoint returns 404 for unknown versions (curl -f fails).
  _stub_curl_fail

  run version_skew::render "$TMPDIR_TEST/cluster.json" "$TMPDIR_TEST/nodes.json"
  [ "$status" -eq 0 ]
  # Should not crash, should indicate unknown support status
  [[ "$output" != *"End-of-life"* ]]
  [[ "$output" != *"Supported"* ]]
}

# ---------------------------------------------------------------------------
# Latest-patch check (docs Workflow 1: "control-plane minor vs latest patch
# on that minor"). The API response now also exposes a `latest` field per
# cycle; lib reports patches-behind when the cluster is older than `latest`.
# ---------------------------------------------------------------------------

@test "render: control plane behind latest patch -- reports count" {
  _write_cluster_json "1.31.2"
  _write_nodes_json "1.31.2"
  _stub_curl_endoflife '{"name":"1.31","eolFrom":"2025-10","isEol":false,"latest":"1.31.5"}'

  run version_skew::render "$TMPDIR_TEST/cluster.json" "$TMPDIR_TEST/nodes.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Latest patch"* ]]
  [[ "$output" == *"v1.31.5"* ]]
  [[ "$output" == *"3 patches behind"* ]]
}

@test "render: control plane on latest patch -- omits or marks 'on latest'" {
  _write_cluster_json "1.31.5"
  _write_nodes_json "1.31.5"
  _stub_curl_endoflife '{"name":"1.31","eolFrom":"2025-10","isEol":false,"latest":"1.31.5"}'

  run version_skew::render "$TMPDIR_TEST/cluster.json" "$TMPDIR_TEST/nodes.json"
  [ "$status" -eq 0 ]
  [[ "$output" != *"patches behind"* ]]
}

@test "render: API response without 'latest' field -- degrades gracefully" {
  _write_cluster_json "1.31.2"
  _write_nodes_json "1.31.2"
  _stub_curl_endoflife '{"name":"1.31","eolFrom":"2025-10","isEol":false}'

  run version_skew::render "$TMPDIR_TEST/cluster.json" "$TMPDIR_TEST/nodes.json"
  [ "$status" -eq 0 ]
  # Should not crash and should not invent a phantom "patches behind" claim.
  [[ "$output" != *"patches behind"* ]]
}

@test "render: control plane one patch ahead of 'latest' -- does not report behind" {
  # Edge case: a freshly-released patch where endoflife.date hasn't caught up.
  _write_cluster_json "1.31.6"
  _write_nodes_json "1.31.6"
  _stub_curl_endoflife '{"name":"1.31","eolFrom":"2025-10","isEol":false,"latest":"1.31.5"}'

  run version_skew::render "$TMPDIR_TEST/cluster.json" "$TMPDIR_TEST/nodes.json"
  [ "$status" -eq 0 ]
  [[ "$output" != *"patches behind"* ]]
}
