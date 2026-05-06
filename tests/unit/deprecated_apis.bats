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

# Unit tests for src/skills/audit-outdated/scripts/lib/deprecated-apis.sh.

setup() {
  load '../test_helper.bash'
  common_setup
  use_mocks

  export KSTACK_KUBE_CONTEXT="test-ctx"
  SKILL_SCRIPTS="$SRC_ROOT/skills/audit-outdated/scripts"
  # shellcheck source=/dev/null
  . "$SKILL_SCRIPTS/lib/deprecated-apis.sh"
}

# --- Fixture helpers ---

# _stub_kubectl_api_versions <versions...>
#   Stub kubectl to return the given api-versions list.
_stub_kubectl_api_versions() {
  local versions=""
  for v in "$@"; do
    versions+="$v"$'\n'
  done
  write_stub kubectl "
args=\"\$*\"
case \"\$args\" in
  *api-versions*)
    printf '%s' '$versions'
    ;;
  *)
    echo '{}' ;;
esac
"
}

# _stub_pluto <json_output>
#   Stub pluto to return JSON output.
_stub_pluto() {
  local body="$1"
  write_stub pluto "
args=\"\$*\"
case \"\$args\" in
  *detect-all-in-cluster*)
    printf '%s' '$body'
    ;;
  *)
    echo '{}' ;;
esac
"
}

# _stub_kubent <json_output>
#   Stub kubent to return JSON output.
_stub_kubent() {
  local body="$1"
  write_stub kubent "printf '%s' '$body'"
}

# _stub_curl_deprecation_guide <html_body>
#   Stub curl to return HTML for the deprecation guide page.
_stub_curl_deprecation_guide() {
  local body="$1"
  write_stub curl "printf '%s' '$body'"
}

# _remove_tool <name>
#   Remove a tool stub from MOCK_BIN so it's "not installed".
_remove_tool() {
  rm -f "$MOCK_BIN/$1"
}

# --- Backend detection tests ---

@test "detect: uses pluto when available" {
  _stub_kubectl_api_versions "apps/v1" "extensions/v1beta1"
  _stub_pluto '[{"name":"extensions/v1beta1","api":{"version":"extensions/v1beta1","kind":"Deployment"},"ruleSet":"","replaceWith":"apps/v1","removedIn":"1.22","deprecated":true,"removed":true}]'

  run deprecated_apis::render "1.31"
  [ "$status" -eq 0 ]
  [[ "$output" == *"extensions/v1beta1"* ]]
  [[ "$output" == *"pluto"* ]] || [[ "$output" == *"Pluto"* ]]
}

@test "detect: falls back to kubent when pluto unavailable" {
  _remove_tool pluto
  _stub_kubectl_api_versions "apps/v1" "extensions/v1beta1"
  _stub_kubent '[{"Name":"extensions/v1beta1","Namespace":"","Kind":"Deployment","ApiVersion":"extensions/v1beta1","RuleSet":"","ReplaceWith":"apps/v1","Since":"1.22"}]'

  run deprecated_apis::render "1.31"
  [ "$status" -eq 0 ]
  [[ "$output" == *"extensions/v1beta1"* ]]
  [[ "$output" == *"kubent"* ]] || [[ "$output" == *"Kubent"* ]]
}

@test "detect: falls back to web -- sets AGENT_NEEDED with raw data" {
  _remove_tool pluto
  _remove_tool kubent
  _stub_kubectl_api_versions "apps/v1" "extensions/v1beta1"
  _stub_curl_deprecation_guide '#### Deployment
The **extensions/v1beta1** API version of Deployment is no longer served as of v1.22.
* Migrate manifests and API clients to use the **apps/v1** API version, available since v1.9.'

  DEPRECATED_APIS_AGENT_NEEDED=""
  DEPRECATED_APIS_RAW_PAGE=""
  DEPRECATED_APIS_ACTIVE_VERSIONS=""
  deprecated_apis::render "1.31"
  [ "$DEPRECATED_APIS_AGENT_NEEDED" = "true" ]
  [[ "$DEPRECATED_APIS_RAW_PAGE" == *"extensions/v1beta1"* ]]
  [[ "$DEPRECATED_APIS_ACTIVE_VERSIONS" == *"apps/v1"* ]]
}

@test "detect: all backends unavailable -- reports unable to detect" {
  _remove_tool pluto
  _remove_tool kubent
  _stub_kubectl_api_versions "apps/v1" "extensions/v1beta1"
  write_stub curl "exit 1"

  run deprecated_apis::render "1.31"
  [ "$status" -eq 0 ]
  [[ "$output" == *"unable"* ]] || [[ "$output" == *"Unable"* ]]
}

# --- Pluto backend tests ---

@test "pluto: no deprecated APIs -- reports clean" {
  _stub_kubectl_api_versions "apps/v1" "v1"
  _stub_pluto '[]'

  run deprecated_apis::render "1.31"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No deprecated APIs"* ]] || [[ "$output" == *"no deprecated"* ]] || [[ "$output" == *"None"* ]]
}

@test "pluto: multiple deprecated APIs -- reports count and details" {
  _stub_kubectl_api_versions "apps/v1" "extensions/v1beta1" "policy/v1beta1"
  _stub_pluto '[{"name":"extensions/v1beta1","api":{"version":"extensions/v1beta1","kind":"Deployment"},"ruleSet":"","replaceWith":"apps/v1","removedIn":"1.22","deprecated":true,"removed":true},{"name":"policy/v1beta1","api":{"version":"policy/v1beta1","kind":"PodSecurityPolicy"},"ruleSet":"","replaceWith":"policy/v1","removedIn":"1.25","deprecated":true,"removed":true}]'

  run deprecated_apis::render "1.31"
  [ "$status" -eq 0 ]
  [[ "$output" == *"extensions/v1beta1"* ]]
  [[ "$output" == *"policy/v1beta1"* ]]
}

@test "pluto: includes replacement info" {
  _stub_kubectl_api_versions "apps/v1" "extensions/v1beta1"
  _stub_pluto '[{"name":"extensions/v1beta1","api":{"version":"extensions/v1beta1","kind":"Deployment"},"ruleSet":"","replaceWith":"apps/v1","removedIn":"1.22","deprecated":true,"removed":true}]'

  run deprecated_apis::render "1.31"
  [ "$status" -eq 0 ]
  [[ "$output" == *"apps/v1"* ]]
}

# --- Kubent backend tests ---

@test "kubent: no deprecated APIs -- reports clean" {
  _remove_tool pluto
  _stub_kubectl_api_versions "apps/v1" "v1"
  _stub_kubent '[]'

  run deprecated_apis::render "1.31"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No deprecated APIs"* ]] || [[ "$output" == *"no deprecated"* ]] || [[ "$output" == *"None"* ]]
}

@test "kubent: includes replacement info" {
  _remove_tool pluto
  _stub_kubectl_api_versions "apps/v1" "extensions/v1beta1"
  _stub_kubent '[{"Name":"extensions/v1beta1","Namespace":"","Kind":"Deployment","ApiVersion":"extensions/v1beta1","RuleSet":"","ReplaceWith":"apps/v1","Since":"1.22"}]'

  run deprecated_apis::render "1.31"
  [ "$status" -eq 0 ]
  [[ "$output" == *"apps/v1"* ]]
}

# --- Web fallback backend tests ---

@test "web: sets AGENT_NEEDED regardless of cluster API match" {
  _remove_tool pluto
  _remove_tool kubent
  _stub_kubectl_api_versions "apps/v1" "v1"
  _stub_curl_deprecation_guide '#### Deployment
The **extensions/v1beta1** API version of Deployment is no longer served as of v1.22.
* Migrate manifests and API clients to use the **apps/v1** API version, available since v1.9.'

  DEPRECATED_APIS_AGENT_NEEDED=""
  DEPRECATED_APIS_RAW_PAGE=""
  DEPRECATED_APIS_ACTIVE_VERSIONS=""
  deprecated_apis::render "1.31"
  [ "$DEPRECATED_APIS_AGENT_NEEDED" = "true" ]
  # Raw page is passed through without bash parsing
  [[ "$DEPRECATED_APIS_RAW_PAGE" == *"extensions/v1beta1"* ]]
  # Active versions include what the cluster serves
  [[ "$DEPRECATED_APIS_ACTIVE_VERSIONS" == *"apps/v1"* ]]
}

# --- version_lt tests (preserved) ---

@test "version_lt: basic comparisons" {
  _deprecated_apis::version_lt "1.21" "1.22"
  ! _deprecated_apis::version_lt "1.22" "1.22"
  ! _deprecated_apis::version_lt "1.23" "1.22"
}
