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

# Source the update-check lib (and its cache.sh dependency) so the uc_*
# helpers are callable without running a CLI.

setup() {
  load '../test_helper.bash'
  common_setup
  # shellcheck source=../../lib/cache.sh
  . "$SRC_ROOT/lib/cache.sh"
  # shellcheck source=../../lib/manifest.sh
  . "$SRC_ROOT/lib/manifest.sh"
  # shellcheck source=../../lib/update-check.sh
  . "$SRC_ROOT/lib/update-check.sh"
}

@test "uc_is_newer: equal versions returns 1" {
  run uc_is_newer v1.0.0 v1.0.0
  [ "$status" -eq 1 ]
}

@test "uc_is_newer: newer returns 0" {
  run uc_is_newer v2.0.0 v1.0.0
  [ "$status" -eq 0 ]
}

@test "uc_is_newer: older returns 1" {
  run uc_is_newer v1.0.0 v2.0.0
  [ "$status" -eq 1 ]
}

@test "uc_is_newer: minor bump" {
  run uc_is_newer v1.2.0 v1.1.9
  [ "$status" -eq 0 ]
}

@test "uc_is_newer: patch bump" {
  run uc_is_newer v1.0.10 v1.0.2
  [ "$status" -eq 0 ]
}

@test "uc_is_newer: two-digit version segments" {
  run uc_is_newer v1.10.0 v1.9.0
  [ "$status" -eq 0 ]
}

@test "uc_compute_notice: installed < latest -> sets NOTICE" {
  uc_compute_notice v1.0.0 v2.0.0 ""
  [[ "$NOTICE" == *"kstack v2.0.0 is available"* ]]
  [[ "$NOTICE" == *"you're on v1.0.0"* ]]
}

@test "uc_compute_notice: installed == latest -> empty NOTICE" {
  uc_compute_notice v1.0.0 v1.0.0 ""
  [ -z "$NOTICE" ]
}

@test "uc_compute_notice: installed > latest -> empty NOTICE" {
  uc_compute_notice v3.0.0 v2.0.0 ""
  [ -z "$NOTICE" ]
}

@test "uc_compute_notice: dismissed == latest -> empty NOTICE" {
  uc_compute_notice v1.0.0 v2.0.0 v2.0.0
  [ -z "$NOTICE" ]
}

@test "uc_compute_notice: dismissed > latest -> empty NOTICE" {
  uc_compute_notice v1.0.0 v2.0.0 v2.5.0
  [ -z "$NOTICE" ]
}

@test "uc_compute_notice: dismissed < latest -> sets NOTICE" {
  uc_compute_notice v1.0.0 v2.5.0 v2.0.0
  [[ "$NOTICE" == *"kstack v2.5.0 is available"* ]]
}

@test "uc_compute_notice: empty installed -> empty NOTICE" {
  uc_compute_notice "" v2.0.0 ""
  [ -z "$NOTICE" ]
}

@test "uc_compute_notice: empty latest -> empty NOTICE" {
  uc_compute_notice v1.0.0 "" ""
  [ -z "$NOTICE" ]
}

@test "uc_resolve_installed_version: reads manifest/version" {
  mkdir -p "$HOME/root/manifest"
  echo "v1.2.3" > "$HOME/root/manifest/version"
  uc_resolve_installed_version "$HOME/root"
  [ "$INSTALLED" = "v1.2.3" ]
}

@test "uc_resolve_installed_version: missing file -> empty" {
  mkdir -p "$HOME/root"
  uc_resolve_installed_version "$HOME/root"
  [ -z "$INSTALLED" ]
}

@test "uc_resolve_installed_version: 'main' -> empty (pre-release)" {
  mkdir -p "$HOME/root/manifest"
  echo "main" > "$HOME/root/manifest/version"
  uc_resolve_installed_version "$HOME/root"
  [ -z "$INSTALLED" ]
}
