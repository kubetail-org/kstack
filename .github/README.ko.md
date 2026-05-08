# kstack

*K8s 클러스터를 초지능적으로 모니터링하는 Claude Code 스킬 팩*

<a href="https://discord.gg/CmsmWAVkvX"><img src="https://img.shields.io/discord/1212031524216770650?logo=Discord&style=flat-square&logoColor=FFFFFF&labelColor=5B65F0&label=Discord&color=64B73A"></a>
[![Slack](https://img.shields.io/badge/Slack-kubetail-364954?logo=slack&labelColor=4D1C51)](https://kubernetes.slack.com/archives/C08SHG1GR37)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)
[![Contributor Resources](https://img.shields.io/badge/Contributor%20Resources-purple?style=flat-square)](https://github.com/kubetail-org)

[English](../README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md) | 한국어 | [Deutsch](README.de.md) | [Español](README.es.md) | [Português](README.pt-BR.md) | [Français](README.fr.md)

## 소개

<img width="350" alt="kstack" src="https://github.com/user-attachments/assets/cfe998de-a85a-44bb-8eb2-5f5efe7449ea" />
<br>
<br>

**Kstack**은 Claude Code를 위한 스킬 팩으로, K8s 클러스터에서 모니터링, 트러블슈팅 및 감사 작업을 스마트하고 효율적으로 수행할 수 있도록 도와줍니다. kubectl 같은 표준 도구 외에도 [Kubetail](https://github.com/kubetail-org/kubetail), [Helm](https://helm.sh), [Trivy](https://github.com/aquasecurity/trivy), [Pluto](https://github.com/FairwindsOps/pluto) 같은 도구에 셸 작업을 위임한 후 결과를 Claude에 전송하여 응답을 빠르고 토큰 효율적으로 유지합니다. Kstack은 클러스터에서 실행 중인 서비스를 감지하고 필요할 때 해당 전용 도구를 사용합니다(예: [Cilium](https://cilium.io), [Istio](https://istio.io)).

kstack을 설치하면 Claude Code 내에서 다음 스킬을 사용할 수 있습니다:

**모니터링**
* `/cluster-status` — 클러스터 상태 스냅샷 (Pod 재시작, 노드 상태, 리소스 압력)
* `/events` — 최근 이벤트, 심각도 순으로 순위 매김

**트러블슈팅**
* `/investigate` — 이벤트, 로그, 관련 리소스에 걸친 근본 원인 분석
* `/logs` — 자연어를 로그 가져오기 및 분석으로 변환하는 공유 tmux 세션 ([Kubetail](https://github.com/kubetail-org/kubetail) 통해)
* `/metrics` — Pod, 노드 및 워크로드의 CPU, 메모리 및 기타 리소스 메트릭 가져오기
* `/exec` — Pod, 노드 또는 임시 디버그 컨테이너로의 공유 tmux 셸

**감사**
* `/audit-security` — RBAC, Pod 보안 자세, 권한 강화
* `/audit-network` — NetworkPolicy, Service, Ingress, GatewayAPI, DNS 및 암호화 검사
* `/audit-cost` — 요청 대비 사용량, 과다 프로비저닝, 유휴 용량
* `/audit-outdated` — 오래된 서비스, 알려진 CVE, 사용 가능한 버전 업그레이드

**기타**
* `/cleanup` — 클러스터에서 모든 kstack 소유 리소스 제거 (디버그 컨테이너, Pod 클론, watcher 작업)
* `/forget` — kstack의 로컬 캐시 지우기 및 클러스터에 대해 학습한 내용 삭제

우리의 목표는 사용자 친화적이고 비용 효율적인 방식으로 AI의 힘을 K8s 모니터링에 가져와 여러분이 제어권을 유지할 수 있도록 하는 것입니다. 버그를 발견하거나 제안이 있으면 GitHub Issue를 만들거나 hello@kubetail.com으로 이메일을 보내주세요!

## 빠른 시작

kstack 스킬을 전역으로 설치하려면 이 명령을 실행하세요:

```console
curl -sS https://kstack.sh/install | bash
```

또는 특정 프로젝트 디렉토리에 로컬로 설치할 수 있습니다:

```console
curl -sS https://kstack.sh/install | bash -s -- --local
```

설치 후 스킬은 에이전트 세션 내에서 사용할 수 있습니다:

```
───────────────────────────────────
❯ /kstack-cluster-status
───────────────────────────────────
```

기본적으로 스크립트는 kstack-* 네임스페이스 접두사로 스킬을 설치하지만 --no-prefix 플래그로 비활성화할 수 있습니다. 또한 사용 가능한 모든 에이전트(예: Claude, Codex, OpenCode)에 스킬을 설치하지만 --agent 플래그로 개별 에이전트를 선택할 수 있습니다([설치](https://kstack.sh/concepts/installation) 참조).

Kstack은 인증을 위해 로컬 `kubeconfig` 파일을 사용하므로 RBAC 권한을 사용하여 사용자를 대신하여 작업을 수행할 수 있습니다. 권한 문제가 발생하면 알려줄 것입니다.

## 다른 AI 에이전트

Kstack은 Claude뿐만 아니라 스킬을 지원하는 모든 AI 에이전트와 함께 작동합니다. curl 부트스트랩은 `PATH`에 있는 에이전트 CLI를 자동 감지하고 각각에 설치합니다. `--agent <name>`으로 특정 에이전트를 지정할 수 있습니다:

| 에이전트          | 플래그             | 전역 설치 경로                  |
|------------------|--------------------|-------------------------------|
| OpenAI Codex CLI | `--agent codex`    | `~/.codex/skills/`            |
| OpenCode         | `--agent opencode` | `~/.config/opencode/skills/`  |
| Cursor           | `--agent cursor`   | `~/.cursor/skills/`           |
| Factory Droid    | `--agent factory`  | `~/.factory/skills/`          |
| Slate            | `--agent slate`    | `~/.slate/skills/`            |
| Kiro             | `--agent kiro`     | `~/.kiro/skills/`             |
| Hermes           | `--agent hermes`   | `~/.hermes/skills/`           |
| Pi               | `--agent pi`       | `~/.pi/agent/skills/`         |

로컬 설치는 프로젝트 디렉토리 아래에 이 구조를 미러링하며(예: `<project>/.codex/skills/`) 해당 디렉토리 내에서 에이전트를 실행할 때만 선택됩니다. Pi만 예외로, 로컬 스킬 디렉토리는 `<project>/.pi/skills/`입니다(`agent/` 세그먼트 없음).

## 스킬 참조

각 스킬은 에이전트 세션 내에서 `/<name>`으로 호출됩니다. 모든 스킬은 기본적으로 읽기 전용입니다 — 클러스터 상태를 변경하는 모든 작업은 명시적인 확인이 필요합니다. 스킬은 로컬 `kubeconfig` 컨텍스트를 준수하고 RBAC을 존중합니다.

**전역 플래그** (모든 스킬에서 지원):

| 플래그            | 설명                                                                |
|-------------------|---------------------------------------------------------------------|
| `--context <ctx>` | 현재 kubeconfig 컨텍스트 재정의                                      |
| `--namespace <n>` | 실행 범위를 단일 네임스페이스로 제한 (기본값: 모든 접근 가능한 것)    |
| `--json`          | 다른 도구로 파이프하기 위한 구조화된 출력 내보내기                    |
| `--help`          | 브라우저에서 스킬의 참조 문서 열기                                    |

---

### 모니터링

<dl>
<dt>

#### `/cluster-status`

</dt>
<dd>

클러스터의 밀도 있는 상태 스냅샷 — 노드 상태, Pod 집계, 실제로 중요한 문제의 순위 목록.

**검사 내용:** 클러스터 ID (컨텍스트, Kubernetes 버전, 플랫폼), 노드 `Ready`/`MemoryPressure`/`DiskPressure`/`PIDPressure` 상태 및 `SchedulingDisabled`, 컨트롤 플레인 vs. 워커 분할, 모든 네임스페이스의 Pod 단계 및 `Ready` 상태, 0이 아닌 재시작 횟수를 가진 Pod, 순위별 상위 문제 목록 (심각도별 상위 5개).

**작동 방식:** `kubectl version`, `kubectl get nodes -o json`, `kubectl get pods -A -o json`을 병렬로 펼쳐 각각을 컨텍스트별 캐시(`cluster.json`, `nodes.json`, `pods.json`)에 씁니다. 집계 및 심각도 순위는 클라이언트 측에서 수행됩니다. 후속 질문("Pod 나열", "<노드>의 Pod", "테인트된 노드는 어느 것")은 스킬을 다시 호출하지 않고 `jq`로 캐시를 읽어 답합니다.

**옵션:**
- `--refresh` — 최신 데이터 가져오기, 캐시 우회 및 새로 고침 (기본값: `false`)
- `--ttl <duration>` — `<duration>`보다 오래된 경우에만 캐시 업데이트 (기본값: `15m`)

**참조:** [kstack.sh/reference/skills/cluster-status](https://kstack.sh/reference/skills/cluster-status)

</dd>
<dt>

#### `/events`

</dt>
<dd>

최근 클러스터 이벤트, 이유별로 그룹화되고 심각도별로 순위 매김 — `Pulled`/`Created`/`Started` 노이즈에 신호가 묻히지 않도록.

**검사 내용:** 모든 네임스페이스의 `Warning` 이벤트, `(reason, involvedObject.kind, namespace)`로 그룹화; 주목할 만한 `Normal` 이벤트 (`Killing`, `Preempting`, `NodeNotReady`, `Rebooted`, `FailedScheduling`), 수다스러운 이유 (`Pulled`, `Created`, `Started`, `Scheduled`, `SuccessfulCreate`)는 테일 줄로 축소됨. 각 그룹에는 횟수, 첫/마지막 타임스탬프, 가장 최근 메시지, 관련 개체가 포함됩니다.

**작동 방식:** 단일 `kubectl get events --all-namespaces` 호출 (`events.k8s.io/v1` 대상, `lastTimestamp`로 서버 측 정렬), `events.json`으로 컨텍스트별 캐시에 씁니다. 집계 및 순위는 클라이언트 측에서 수행됩니다. 후속 질문("payments만", "pod/checkout-7c9의 이벤트", "억제된 것 표시")은 `jq`로 캐시를 읽어 답합니다 — 소유자를 한 레벨 위 (`Pod` → `ReplicaSet` → `Deployment`)까지 추적하여 컨트롤러가 발생시킨 이벤트를 놓치지 않습니다.

**옵션:**
- `--refresh` — 최신 데이터 가져오기, 캐시 우회 및 새로 고침 (기본값: `false`)
- `--ttl <duration>` — `<duration>`보다 오래된 경우에만 캐시 업데이트 (기본값: `5m`)

**참조:** [kstack.sh/reference/skills/events](https://kstack.sh/reference/skills/events)

</dd>

---

### 트러블슈팅

<dl>
<dt>

#### `/investigate`

</dt>
<dd>

실패하거나 의심스러운 리소스에 대한 근본 원인 조사를 시작합니다. 스킬이 호출되면 스크립트를 실행하여 초기 데이터 번들을 수집하고 에이전트에게 브리핑합니다. 그 후 자연어로 후속 질문을 할 수 있으며 에이전트는 가진 것에서 답할지, 새로운 것을 가져올지, 다른 도구를 사용할지 결정합니다.

**수집 내용:** 문제 있는 리소스의 spec 및 status; 해당 리소스와 소유자(`Pod`의 `ReplicaSet` 및 `Deployment`, `Job`의 `CronJob` 등)의 이벤트; 현재 및 이전 컨테이너의 로그 (실패를 포함할 가능성이 가장 높은 줄로 잘림); 명백한 관련 리소스 (지원 `Service`, 마운트된 `ConfigMap`/`Secret` 이름, 바인딩된 `PVC`, 참조된 `ServiceAccount`); 관련 시 Pod가 스케줄된 노드.

**작동 방식:** 스킬은 Kubernetes API에서 번들을 로드하고 읽는 방법(종료 코드, 이벤트 이유, 일반적인 상태 조합), 후속 질문이 오래된 번들에서 추론하는 대신 다시 가져와야 할 때, [`/logs`](#logs), [`/exec`](#exec), 또는 [`/metrics`](#metrics)에 넘겨야 할 때에 대해 에이전트에게 브리핑합니다.

**인수:**
- `<target>` — `<kind>/<name>` (예: `pod/checkout-7c9`) 또는 자연어 (`api 배포`, `왜 checkout이 크래시하는지`). 선택 사항 — 생략하면 스킬이 프롬프트.

**옵션:** 없음. 프롬프트나 후속 질문의 자연어로 로그, 시간 창, 리소스 범위 지정.

**참조:** [kstack.sh/reference/skills/investigate](https://kstack.sh/reference/skills/investigate)

</dd>
<dt>

#### `/logs`

</dt>
<dd>

AI 기반 로그 가져오기. 자연어로 찾는 것을 설명하면 에이전트가 올바른 Pod를 찾고, 시간 창을 선택하고, 중요한 줄만 가져오는 grep 필터를 구성합니다. 스트림은 여러분과 에이전트 모두 연결된 **tmux** 창 내에서 실행됩니다.

**작동 방식:** 에이전트는 설명을 Kubetail 쿼리로 변환하고, 분리된 tmux 세션(예: `kstack-logs-api-server`)을 시작하고, 연결된 새 터미널 창을 열려고 시도하고, 폴백으로 채팅에 `tmux attach` 명령을 출력합니다. 여러분과 에이전트는 같은 창을 공유합니다 — 스크롤, 검색, 라이브 테일 보기; 에이전트는 토큰을 절약하기 위해 보수적으로 읽습니다.

**요구 사항:** 에이전트의 `$PATH`에 `tmux`, 클러스터에 Kubetail 설치 (없으면 스킬이 Helm으로 설치 제안).

**인수:**
- `<target>` — 가져올 내용의 자연어 설명 (`api`, `지난 1시간의 api 오류`, `지난 15분간 checkout의 "timeout"`). 선택 사항 — 생략하면 스킬이 프롬프트.

**옵션:**
- `--attach` — 새 세션 시작 대신 기존 kstack tmux 세션에 에이전트 연결
- `--detach` — 새 분리 세션 시작 (터미널 창 열지 않음, 수동으로 연결)

**참조:** [kstack.sh/reference/skills/logs](https://kstack.sh/reference/skills/logs)

</dd>
<dt>

#### `/metrics`

</dt>
<dd>

AI 기반 메트릭 가져오기. 보고 싶은 것을 설명하면 에이전트가 올바른 대상을 해결하고, 적절한 시간 창을 선택하고, 컴팩트한 요약을 반환합니다. 읽기 전용이며 클러스터 상태를 변경하지 않습니다.

**작동 방식:** 에이전트는 설명을 적합한 소스(`metrics-server` 또는 Prometheus)에 대한 쿼리로 변환하고, 전체 시리즈를 모델을 통해 파이프하는 대신 요약 통계 (p50, p95, 최대값)를 보고하고, 범위가 의도보다 넓어 보이면 실행 전에 해결된 쿼리를 표시합니다. 메트릭이 *왜* 변동했는지에 대해서는 [`/logs`](#logs)에 넘기고; 근본 원인 컨텍스트는 [`/investigate`](#investigate); 전체 적정 크기 조정 스윕은 [`/audit-cost`](#audit-cost).

**인수:**
- `<target>` — 자연어 설명 (`api`, `지난 1시간의 checkout 메모리`, `payments의 CPU별 상위 Pod`). 선택 사항 — 생략하면 스킬이 프롬프트.

**옵션:** 없음. 프롬프트나 후속 질문의 자연어로 대상, 메트릭, 시간 창 범위 지정.

**참조:** [kstack.sh/reference/skills/metrics](https://kstack.sh/reference/skills/metrics)

</dd>
<dt>

#### `/exec`

</dt>
<dd>

`kubectl exec`의 AI 기반 버전. 자연어로 대상을 설명하면 에이전트가 올바른 메커니즘을 선택합니다: 실행 중인 컨테이너로의 일반 `exec`, 대상에 사용 가능한 셸이 없을 때 임시 디버그 컨테이너, 또는 노드의 특권 셸. 세션은 여러분과 에이전트 모두 연결된 **tmux** 창 내에서 실행됩니다 — 둘 중 하나가 입력할 수 있고 둘 다 출력을 봅니다.

**작동 방식:** 에이전트는 분리된 tmux 세션(예: `kstack-exec-api-server`)을 시작하고, 연결된 새 터미널 창을 열려고 시도하고, 폴백으로 채팅에 `tmux attach` 명령을 출력합니다. 에이전트는 토큰을 절약하기 위해 창에서 보수적으로 읽습니다. 종료하라고 하면 tmux 세션을 종료하고 생성한 Pod를 삭제합니다.

**요구 사항:** 에이전트의 `$PATH`에 `tmux`.

**보안:** `/exec`는 `disable-model-invocation: true`로 출시 — 위의 특권 모드를 고려하여 에이전트는 스스로 셸을 시작하지 않습니다. 여러분이 `/exec`를 입력할 때만 실행됩니다.

**인수:**
- `<target>` — 자연어 설명 (`api`, `api/sidecar`, `node worker-3`, `debug api`). 선택 사항 — 생략하면 스킬이 프롬프트.

**옵션:**
- `--image <image>` — 노드 및 디버그 컨테이너 모드에 사용할 이미지 (기본값 `netshoot`)
- `--attach` — 새 세션 시작 대신 기존 kstack tmux 세션에 에이전트 연결
- `--detach` — 새 분리 세션 시작 (터미널 창 열지 않음, 수동으로 연결)

**참조:** [kstack.sh/reference/skills/exec](https://kstack.sh/reference/skills/exec)

</dd>
</dl>

---

### 감사

모든 감사 스킬은 순위가 매겨진 발견 목록 (심각도 + 증거 + 제안된 수정)을 생성합니다.

<dl>
<dt>

#### `/audit-security`

</dt>
<dd>

RBAC 검토, Pod 보안 자세, 권한 강화 권장 사항. 과도하게 권한 부여된 ID와 워크로드를 찾습니다 — 사용하는 것보다 더 많은 접근 권한을 가진 `ServiceAccount`, root로 실행되거나 호스트 수준 탈출이 있는 Pod, 네임스페이스 범위 역할로 충분한 곳에 클러스터 전체 권한을 부여하는 바인딩.

**작동 방식:** Kubernetes API만 쿼리; exec 없음, 로그 접근 없음. 발견은 블라스트 반경으로 순위 매김 (클러스터 범위 와일드카드가 네임스페이스 범위보다 위, 호스트 탈출이 seccomp 누락보다 위). RBAC 검사는 **정적** — `Role`이 무엇을 부여하는지 찾고, 주체가 실제로 무엇을 사용하는지가 아닙니다; 진정으로 미사용 권한 감지는 감사 로그 분석이 필요하며 이 스킬은 그것을 하지 않습니다. `Secret`은 이름, 네임스페이스, 타입으로만 참조됩니다 — 내용은 절대 읽지 않습니다.

**인수:**
- `<scope>` — 자연어 범위 (`rbac`, `kube-system의 Pod`). 선택 사항 — 전체 스윕을 위해 생략.

**옵션:** 없음. 프롬프트나 후속 질문의 자연어로 범위 지정.

**참조:** [kstack.sh/reference/skills/audit-security](https://kstack.sh/reference/skills/audit-security)

</dd>
<dt>

#### `/audit-network`

</dt>
<dd>

NetworkPolicy, Service, Ingress, Gateway API, DNS 및 암호화 건전성 검사. 클러스터 네트워킹에서 손상되거나 누락된 부분을 찾습니다 — 아무것도 일치하지 않는 `NetworkPolicy` 인스턴스, 엔드포인트가 없는 `Service`, 해결되지 않는 `Ingress` 및 Gateway API 경로, DNS 문제, 메시가 사용 가능한데 평문으로 통신하는 워크로드.

**작동 방식:** Kubernetes API와 함께 CoreDNS 메트릭 및 메시 CRD (존재할 경우)를 쿼리합니다. TLS 검사는 "RBAC로 인해 Secret 내용을 읽을 수 없음"과 "만료됨"을 구별하여 오탐을 보고하지 않습니다. 발견은 워크플로우별로 그룹화되며 증거 (셀렉터, 엔드포인트, ConfigMap 키)를 포함합니다 — 결론만이 아닙니다.

**인수:**
- `<scope>` — 자연어 범위 (`policies`, `prod의 ingress`). 선택 사항 — 전체 스윕을 위해 생략.

**옵션:** 없음. 프롬프트나 후속 질문의 자연어로 범위 지정.

**참조:** [kstack.sh/reference/skills/audit-network](https://kstack.sh/reference/skills/audit-network)

</dd>
<dt>

#### `/audit-cost`

</dt>
<dd>

리소스 낭비 및 적정 크기 조정 권장 사항. 과다 프로비저닝되거나, 유휴 상태이거나, 아무도 사용하지 않는 스토리지와 로드 밸런서를 보유한 워크로드를 찾습니다.

**작동 방식:** 여러 워크플로우를 병렬로 실행하여 `metrics-server` 및 Prometheus 읽기를 `Job`/`CronJob` 상태, PV/PVC 바인딩, `LoadBalancer` 엔드포인트에 대한 Kubernetes API와 연결합니다. 발견은 잠재적 영향으로 순위 매김 (대형 요청 대비 사용량 차이 및 유휴 워크로드가 마운트되지 않은 PVC 및 `Released` PV보다 위), 실제로 중요한 요청 대비 사용량 차이만 플래그 — 작은 차이는 노이즈. 헤더는 항상 소스 (실시간의 `metrics-server`, 기록의 Prometheus)와 유효 룩백을 명시하여 독자가 권장 사항에 얼마나 많은 무게를 줄지 판단할 수 있도록 합니다.

**인수:**
- `<scope>` — 자연어 범위 (`requests`, `staging의 유휴`). 선택 사항 — 전체 스윕을 위해 생략.

**옵션:** 없음. 프롬프트나 후속 질문의 자연어로 범위 지정.

**참조:** [kstack.sh/reference/skills/audit-cost](https://kstack.sh/reference/skills/audit-cost)

</dd>
<dt>

#### `/audit-outdated`

</dt>
<dd>

오래된 클러스터 구성 요소, 알려진 CVE, 사용 가능한 버전 업그레이드. 컨트롤 플레인, 노드, 컨테이너 이미지, Helm 차트, CRD, 오퍼레이터, 매니페스트가 대상으로 하는 API 표면의 버전 드리프트를 찾습니다.

**작동 방식:** Kubernetes API와 함께 외부 인덱스 (릴리스 일정, 레지스트리, Helm 리포, Trivy DB, CVE 피드)에 대해 워크플로우를 병렬로 실행합니다. 발견은 이미지 다이제스트로 중복 제거 — 많은 Pod에 걸쳐 공유되는 하나의 오래된 이미지가 보고서를 지배하지 않습니다. CVE 항목에는 심각도와 CISA KEV 상태 (사용 가능한 경우)가 포함됩니다 — KEV 히트는 알려진 악용이 없는 CVSS-high 발견보다 위에 순위 매김. "지원 창 내 드리프트"는 "EOL"과 별도로 보고 — 전자는 정기적, 후자는 긴급. 지원 목록 밖의 레지스트리에 대해서는 이미지를 조용히 건너뛰는 대신 스킬이 그렇게 말합니다.

**인수:**
- `<scope>` — 자연어 범위 (`images`, `kube-system의 cves`). 선택 사항 — 전체 스윕을 위해 생략.

**옵션:** 없음. 프롬프트나 후속 질문의 자연어로 범위 지정.

**참조:** [kstack.sh/reference/skills/audit-outdated](https://kstack.sh/reference/skills/audit-outdated)

</dd>
</dl>

---

### 기타

<dl>
<dt>

#### `/cleanup`

</dt>
<dd>

kstack이 클러스터에 생성한 모든 리소스를 제거합니다. 로컬 상태를 지우는 [`/forget`](#forget)의 대응물.

**제거 내용:** `kstack.kubetail.com/owned-by=kstack`으로 주석이 달린 모든 것 — [`/exec`](#exec)의 임시 디버그 컨테이너 및 특권 노드 셸 Pod, 단명 툴박스 Pod, 이를 지원하기 위해 생성된 임시 RBAC 또는 ConfigMap. 주석이 없는 리소스는 같은 네임스페이스에 있어도 절대 건드리지 않습니다.

**작동 방식:** 에이전트는 발견한 모든 것을 네임스페이스와 종류별로 그룹화하여 나열하고 삭제 전에 확인을 요청합니다. 전체 세트를 승인하거나 자연어로 특정 항목을 건너뛰도록 말할 수 있습니다. 삭제가 실패하면 — 보통 파이널라이저나 권한 문제 — 에이전트는 어떤 리소스가 남아 있고 그 이유를 보고합니다, 맹목적으로 재시도하지 않습니다.

**보안:** `/cleanup`은 `disable-model-invocation: true`로 출시 — 클러스터 리소스를 삭제하기 때문에 에이전트는 스스로 정리를 시작하지 않습니다. 여러분이 `/cleanup`을 입력할 때만 실행됩니다.

**옵션:** 없음. 다른 클러스터를 대상으로 하려면 전역 `--context <ctx>` 플래그 사용.

**참조:** [kstack.sh/reference/skills/cleanup](https://kstack.sh/reference/skills/cleanup)

</dd>
<dt>

#### `/forget`

</dt>
<dd>

머신의 kstack 로컬 상태를 지웁니다. 시간이 지남에 따라 kstack은 클러스터의 작업 메모리를 구축합니다 — 최근 쿼리 결과, 감지된 통합, 리소스 지문, 이상을 감지하는 데 사용하는 기준선. 이 스킬은 깨끗한 슬레이트를 강제합니다. 클러스터 자체는 건드리지 않습니다; 그것은 [`/cleanup`](#cleanup) 참조.

**지우는 내용:** 상태는 `~/.config/kstack/` 아래에 kubeconfig 컨텍스트별로 분할되어 있습니다.
- **캐시** (`~/.config/kstack/cache/<context>/`) — 최근 쿼리 결과, 로그 버퍼, 중복 제거 테이블, 진행 중인 watcher 상태. 재구축 비용이 저렴; 자유롭게 지움.
- **학습된 상태** (`~/.config/kstack/state/<context>/`) — 감지된 통합, 리소스 지문, 기준선, 클러스터별 기본 설정. 다음 사용 시 재구축되지만 완전히 재형성하는 데 몇 번의 상호 작용이 필요할 수 있습니다.

**작동 방식:** 기본적으로 현재 kubeconfig 컨텍스트의 캐시와 학습된 상태를 지웁니다 — `staging`을 잊어도 `prod`에는 절대 영향을 미치지 않습니다. 다른 클러스터를 대상으로 하려면 전역 `--context <ctx>` 플래그 사용. 클러스터가 재구축되거나 마이그레이션된 후(kstack이 오래된 지문을 신뢰하지 않도록), 기준선이 오래된 것 같을 때, 이전 세션이 잘못된 것을 가르쳤을 때, 또는 기계를 넘겨주고 클러스터별 상태를 남기지 않고 싶을 때 실행합니다.

**보안:** `/forget`은 `disable-model-invocation: true`로 출시 — 캐시된 컨텍스트가 예기치 않게 손실되지 않도록 에이전트는 스스로 로컬 상태를 지우지 않습니다. 여러분이 `/forget`을 입력할 때만 실행됩니다.

**옵션:**
- `--all` — 현재 컨텍스트만이 아닌 모든 컨텍스트의 캐시 및 학습된 상태 지우기.

**참조:** [kstack.sh/reference/skills/forget](https://kstack.sh/reference/skills/forget)

</dd>
</dl>

## 업그레이드

kstack 스킬을 실행하면 에이전트가 조용히 새 kstack 릴리스가 사용 가능한지 확인하고 발견하면 응답 맨 위에 한 줄 알림을 표시합니다. **"upgrade kstack"**이라고 말하면 에이전트가 여러분 대신 kstack 업그레이드 스크립트를 실행합니다; **"dismiss"**라고 말하면 다음 릴리스까지 알림을 숨깁니다. 이는 전역 및 로컬 설치 모두에서 동일하게 작동합니다.

헬퍼를 직접 실행할 수도 있습니다:

```console
# 전역 설치
~/.config/kstack/bin/upgrade

# 로컬 설치 (프로젝트 디렉토리에서)
./.kstack/bin/upgrade
```

업그레이드는 멱등성이 있으며 언제든지 안전하게 실행할 수 있습니다.

## 제거

설치에 번들된 제거 헬퍼를 실행합니다:

```console
# 전역 설치
~/.config/kstack/bin/uninstall

# 로컬 설치 (프로젝트 디렉토리에서)
./.kstack/bin/uninstall
```

두 헬퍼 모두 제거 전에 확인을 요청합니다. 설치 루트(`~/.config/kstack` 또는 `<project>/.kstack`)와 모든 kstack 소유 스킬 슬롯을 지우고, 같은 에이전트 디렉토리의 사용자 작성 스킬은 건드리지 않습니다.

## 개발

인스톨러 페이로드는 `src/`(스킬, 헬퍼, lib, 스키마) 아래에 있습니다. 개발 도구 — `Makefile`, `scripts/`, `tests/`, CI — 는 저장소 루트에 있습니다. kstack을 해킹하고 있다면 전체 기여자 가이드는 `CONTRIBUTING.md`를 참조하세요.

루트 `Makefile`을 통한 일반적인 기여자 명령:

```console
make install      # 개발 모드 설치 — 스킬을 <repo>/.<agent>/skills/에 렌더링
make test         # 빠른 bats 계층 (단위 + 통합)
make test-e2e     # 클러스터 지원 계층 (kind + docker)
make test-evals   # 평가 하네스 (ANTHROPIC_API_KEY 또는 Claude CLI 필요)
make lint         # shellcheck
make clean        # 개발 모드 아티팩트 제거
```

각 대상은 직접 실행 가능한 `scripts/` 아래의 스크립트에 쉘아웃합니다.

`make test`는 bats-core가 필요합니다 (`brew install bats-core` / `apt install bats`). 테스트는 `tests/unit/`(소스된 함수 테스트)과 `tests/integration/`(격리된 `$HOME` 및 로컬 베어 git 저장소에 대한 엔드투엔드 CLI 테스트)에 있습니다. CI는 모든 PR에 대해 Ubuntu, macOS, Windows에서 전체 스위트를 실행합니다 — `.github/workflows/ci.yml` 참조.

## 참여하기

Kubetail에서 우리는 Kubernetes를 위한 가장 **사용자 친화적**, **비용 효율적**, **안전한** 로깅 플랫폼을 구축하고 있으며 여러분의 기여를 환영합니다! 기여 방법:

* UI/UX 디자인
* React 프론트엔드 개발
* 이슈 보고 및 기능 제안

개발 설정 및 가이드라인은 [CONTRIBUTING.md](CONTRIBUTING.md) 참조. hello@kubetail.com으로 연락하거나 [Discord 서버](https://discord.gg/CmsmWAVkvX) 또는 [Slack 채널](https://join.slack.com/t/kubetail/shared_invite/zt-2cq01cbm8-e1kbLT3EmcLPpHSeoFYm1w)에 참여하세요.

## 참고

* Garry Tan의 [gstack](https://github.com/garrytan/gstack)에서 영감받음

이스탄불에서 🧿와 함께 만들어짐
