# kstack

*Skill-Paket für Claude Code, das dir hilft, deine K8s-Cluster superintelligent zu überwachen*

<a href="https://discord.gg/CmsmWAVkvX"><img src="https://img.shields.io/discord/1212031524216770650?logo=Discord&style=flat-square&logoColor=FFFFFF&labelColor=5B65F0&label=Discord&color=64B73A"></a>
[![Slack](https://img.shields.io/badge/Slack-kubetail-364954?logo=slack&labelColor=4D1C51)](https://kubernetes.slack.com/archives/C08SHG1GR37)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)
[![Contributor Resources](https://img.shields.io/badge/Contributor%20Resources-purple?style=flat-square)](https://github.com/kubetail-org)

[English](../README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | Deutsch | [Español](README.es.md) | [Português](README.pt-BR.md) | [Français](README.fr.md)

## Einführung

<img width="350" alt="kstack" src="https://github.com/user-attachments/assets/cfe998de-a85a-44bb-8eb2-5f5efe7449ea" />
<br>
<br>

**Kstack** ist ein Skill-Paket für Claude Code, das dir hilft, Überwachungs-, Fehlerbehebungs- und Audit-Aufgaben auf deinen K8s-Clustern auf intelligente und effiziente Weise durchzuführen. Zusätzlich zur Verwendung von Standardwerkzeugen wie kubectl übergibt es Shell-Arbeit an Tools wie [Kubetail](https://github.com/kubetail-org/kubetail), [Helm](https://helm.sh), [Trivy](https://github.com/aquasecurity/trivy), [Pluto](https://github.com/FairwindsOps/pluto), bevor Ergebnisse an Claude gesendet werden, wodurch Antworten schnell und token-effizient bleiben. Kstack erkennt auch die in deinem Cluster laufenden Services und verwendet deren spezielle Tools bei Bedarf (z. B. [Cilium](https://cilium.io), [Istio](https://istio.io)).

Nach der Installation von kstack stehen dir diese Skills in Claude Code zur Verfügung:

**Überwachung**
* `/cluster-status` — Gesundheits-Snapshot des Clusters (Pod-Neustarts, Knotenzustände, Ressourcendruck)
* `/events` — Aktuelle Ereignisse, nach Schweregrad gerankt

**Fehlerbehebung**
* `/investigate` — Ursachenanalyse über Ereignisse, Logs und verwandte Ressourcen
* `/logs` — Gemeinsame tmux-Session, die natürliche Sprache in Log-Abrufe und Analysen übersetzt (via [Kubetail](https://github.com/kubetail-org/kubetail))
* `/metrics` — CPU-, Speicher- und andere Ressourcenmetriken für Pods, Knoten und Workloads abrufen
* `/exec` — Gemeinsame tmux-Shell in einem Pod, Knoten oder ephemeren Debug-Container

**Audits**
* `/audit-security` — RBAC, Pod-Sicherheitslage, Rechteminimierung
* `/audit-network` — NetworkPolicy, Service, Ingress, GatewayAPI, DNS und Verschlüsselungsprüfungen
* `/audit-cost` — Anfragen vs. Nutzung, Überprovisionierung, Leerlaufkapazität
* `/audit-outdated` — Veraltete Services, bekannte CVEs, verfügbare Versions-Updates

**Sonstiges**
* `/cleanup` — Alle kstack-eigenen Ressourcen aus dem Cluster entfernen (Debug-Container, Pod-Klone, Watcher-Jobs)
* `/forget` — Lokalen kstack-Cache leeren und gelernte Cluster-Informationen verwerfen

Unser Ziel ist es, die Kraft der KI auf benutzerfreundliche und kostengünstige Weise in die K8s-Überwachung zu bringen und dabei die Kontrolle bei dir zu lassen. Wenn du einen Fehler bemerkst oder einen Vorschlag hast, erstelle bitte ein GitHub-Issue oder sende uns eine E-Mail (hello@kubetail.com)!

## Schnellstart

Um die kstack-Skills global zu installieren, führe diesen Befehl aus:

```console
curl -sS https://kstack.sh/install | bash
```

Alternativ kannst du sie lokal in einem bestimmten Projektverzeichnis installieren:

```console
curl -sS https://kstack.sh/install | bash -s -- --local
```

Nach der Installation sind die Skills in deinen Agenten-Sessions verfügbar:

```
───────────────────────────────────
❯ /kstack-cluster-status
───────────────────────────────────
```

Standardmäßig installiert das Skript die Skills mit einem kstack-* Namespace-Präfix, aber du kannst dies mit dem --no-prefix-Flag deaktivieren. Es installiert die Skills auch für alle verfügbaren Agenten (z. B. Claude, Codex, OpenCode), aber du kannst mit dem --agent-Flag einzelne Agenten auswählen (siehe [Installation](https://kstack.sh/concepts/installation)).

Kstack verwendet deine lokale `kubeconfig`-Datei zur Authentifizierung, sodass es deine RBAC-Berechtigungen verwenden kann, um in deinem Namen zu handeln. Bei Berechtigungsproblemen wird es dich benachrichtigen.

## Andere KI-Agenten

Kstack funktioniert mit jedem KI-Agenten, der Skills unterstützt, nicht nur mit Claude. Der curl-Bootstrap erkennt automatisch, welche Agenten-CLIs sich in deinem `PATH` befinden, und installiert für jeden. Du kannst mit `--agent <name>` einen bestimmten Agenten angeben:

| Agent            | Flag               | Globaler Installationspfad     |
|------------------|--------------------|--------------------------------|
| OpenAI Codex CLI | `--agent codex`    | `~/.codex/skills/`             |
| OpenCode         | `--agent opencode` | `~/.config/opencode/skills/`   |
| Cursor           | `--agent cursor`   | `~/.cursor/skills/`            |
| Factory Droid    | `--agent factory`  | `~/.factory/skills/`           |
| Slate            | `--agent slate`    | `~/.slate/skills/`             |
| Kiro             | `--agent kiro`     | `~/.kiro/skills/`              |
| Hermes           | `--agent hermes`   | `~/.hermes/skills/`            |
| Pi               | `--agent pi`       | `~/.pi/agent/skills/`          |

Lokale Installationen spiegeln diese Struktur unter dem Projektverzeichnis wider (z. B. `<project>/.codex/skills/`) und werden nur erfasst, wenn der Agent aus diesem Verzeichnis heraus ausgeführt wird. Pi ist die einzige Ausnahme — sein lokales Skills-Verzeichnis ist `<project>/.pi/skills/` (ohne `agent/`-Segment).

## Skills-Referenz

Jeder Skill wird mit `/<name>` in einer Agenten-Session aufgerufen. Alle Skills sind standardmäßig schreibgeschützt — jede Aktion, die den Cluster-Zustand mutiert, erfordert eine ausdrückliche Bestätigung. Skills respektieren deinen lokalen `kubeconfig`-Kontext und halten sich an RBAC.

**Globale Flags** (von jedem Skill unterstützt):

| Flag              | Beschreibung                                                              |
|-------------------|---------------------------------------------------------------------------|
| `--context <ctx>` | Den aktuellen kubeconfig-Kontext überschreiben                            |
| `--namespace <n>` | Den Lauf auf einen einzelnen Namespace beschränken (Standard: alle zugänglichen) |
| `--json`          | Strukturierte Ausgabe für Piping in andere Tools ausgeben                 |
| `--help`          | Die Referenzdokumentation für den Skill im Browser öffnen                 |

---

### Überwachung

<dl>
<dt>

#### `/cluster-status`

</dt>
<dd>

Ein dichter Gesundheits-Snapshot des Clusters — Knotenzustände, Pod-Aggregate und eine gerankte Liste der Probleme, die wirklich wichtig sind.

**Was geprüft wird:** Cluster-Identität (Kontext, Kubernetes-Version, Plattform), Knoten-`Ready`/`MemoryPressure`/`DiskPressure`/`PIDPressure`-Zustände und `SchedulingDisabled`, Aufteilung Control-Plane vs. Worker, Pod-Phasen und `Ready` in allen Namespaces, Pods mit nicht-null Restart-Zählern, und eine gerankte Top-Issues-Liste (Top 5 nach Schweregrad).

**Wie es funktioniert:** Fächert `kubectl version`, `kubectl get nodes -o json` und `kubectl get pods -A -o json` parallel aus und schreibt jeden in einen kontextbezogenen Cache (`cluster.json`, `nodes.json`, `pods.json`). Aggregation und Schweregrad-Ranking erfolgen clientseitig. Folgefragen ("Pods auflisten", "Pods auf <Knoten>", "welche Knoten sind mit Taints versehen") werden durch Lesen des Caches mit `jq` beantwortet, ohne den Skill erneut aufzurufen.

**Optionen:**
- `--refresh` — Neueste Daten abrufen, Cache umgehen und aktualisieren (Standard: `false`)
- `--ttl <duration>` — Cache nur aktualisieren, wenn älter als `<duration>` (Standard: `15m`)

**Referenz:** [kstack.sh/reference/skills/cluster-status](https://kstack.sh/reference/skills/cluster-status)

</dd>
<dt>

#### `/events`

</dt>
<dd>

Aktuelle Cluster-Ereignisse, nach Grund gruppiert und nach Schweregrad gerankt, damit das Signal nicht im `Pulled`/`Created`/`Started`-Rauschen untergeht.

**Was geprüft wird:** `Warning`-Ereignisse in allen Namespaces, gruppiert nach `(reason, involvedObject.kind, namespace)`; bemerkenswerte `Normal`-Ereignisse (`Killing`, `Preempting`, `NodeNotReady`, `Rebooted`, `FailedScheduling`) mit geschwätzigen Gründen (`Pulled`, `Created`, `Started`, `Scheduled`, `SuccessfulCreate`), die in einer Tail-Zeile zusammengefasst werden. Jede Gruppe enthält Anzahl, erste/letzte Zeitstempel, die aktuellste Nachricht und die beteiligten Objekte.

**Wie es funktioniert:** Ein einzelner `kubectl get events --all-namespaces`-Aufruf (gegen `events.k8s.io/v1`, serverseitig nach `lastTimestamp` sortiert), als `events.json` in den kontextbezogenen Cache geschrieben. Aggregation und Ranking erfolgen clientseitig. Folgefragen ("nur payments", "Ereignisse bei pod/checkout-7c9", "unterdrückte anzeigen") werden durch Lesen des Caches mit `jq` beantwortet — und traversieren Besitzer eine Ebene nach oben (`Pod` → `ReplicaSet` → `Deployment`), damit controller-ausgelöste Ereignisse nicht verpasst werden.

**Optionen:**
- `--refresh` — Neueste Daten abrufen, Cache umgehen und aktualisieren (Standard: `false`)
- `--ttl <duration>` — Cache nur aktualisieren, wenn älter als `<duration>` (Standard: `5m`)

**Referenz:** [kstack.sh/reference/skills/events](https://kstack.sh/reference/skills/events)

</dd>

---

### Fehlerbehebung

<dl>
<dt>

#### `/investigate`

</dt>
<dd>

Startet eine Ursachenuntersuchung für eine fehlerhafte oder verdächtige Ressource. Wenn der Skill aufgerufen wird, führt er ein Skript aus, um ein erstes Datenbündel zu sammeln, und briefed den Agenten. Von dort aus kannst du Folgefragen in natürlicher Sprache stellen, und der Agent entscheidet, ob er aus dem Vorhandenen antwortet, etwas Neues abruft oder ein anderes Tool verwendet.

**Was gesammelt wird:** Spec und Status der problematischen Ressourcen; Ereignisse bei diesen Ressourcen und ihren Besitzern (das `ReplicaSet` und `Deployment` eines `Pod`, der `CronJob` eines `Job` usw.); Logs aus aktuellen und vorherigen Containern, auf die Zeilen gekürzt, die am wahrscheinlichsten den Fehler enthalten; offensichtliche verwandte Ressourcen (stützender `Service`, gemountete `ConfigMap`/`Secret`-Namen, gebundene `PVC`s, referenzierter `ServiceAccount`); und der Knoten, auf dem die Pods geplant sind, wenn relevant.

**Wie es funktioniert:** Der Skill lädt das Bündel von der Kubernetes-API und briefed den Agenten, wie es zu lesen ist (Exitcodes, Ereignisgründe, häufige Zustandskombinationen), wann Folgefragen neu abrufen sollten statt aus dem veralteten Bündel zu schließen, und wann an [`/logs`](#logs), [`/exec`](#exec) oder [`/metrics`](#metrics) übergeben werden soll.

**Argumente:**
- `<target>` — `<kind>/<name>` (z. B. `pod/checkout-7c9`) oder natürliche Sprache (`das api-Deployment`, `warum checkout abstürzt`). Optional — der Skill fragt nach, wenn weggelassen.

**Optionen:** Keine. Logs, Zeitfenster oder Ressourcen über natürliche Sprache im Prompt oder in Folgefragen einschränken.

**Referenz:** [kstack.sh/reference/skills/investigate](https://kstack.sh/reference/skills/investigate)

</dd>
<dt>

#### `/logs`

</dt>
<dd>

Ein KI-gesteuerter Log-Abrufer. Beschreibe, wonach du suchst, in natürlicher Sprache, und der Agent findet die richtigen Pods, wählt das Zeitfenster und erstellt den Grep-Filter, um nur die wichtigen Zeilen abzurufen. Der Stream läuft in einem **tmux**-Fenster, mit dem sowohl du als auch der Agent verbunden sind.

**Wie es funktioniert:** Der Agent übersetzt deine Beschreibung in eine Kubetail-Abfrage, startet eine getrennte tmux-Session (z. B. `kstack-logs-api-server`), versucht ein neues Terminalfenster damit zu öffnen, und gibt den `tmux attach`-Befehl im Chat als Fallback aus. Du und der Agent teilen sich denselben Bereich — du kannst scrollen, suchen oder den Live-Tail beobachten; der Agent liest sparsam, um Token zu sparen.

**Anforderungen:** `tmux` im `$PATH` des Agenten und Kubetail im Cluster installiert (der Skill bietet an, es über Helm zu installieren, wenn es fehlt).

**Argumente:**
- `<target>` — Natürlichsprachige Beschreibung dessen, was abgerufen werden soll (`api`, `Fehler der letzten Stunde bei api`, `checkout nach "timeout" in den letzten 15m`). Optional — der Skill fragt nach, wenn weggelassen.

**Optionen:**
- `--attach` — Den Agenten an eine bestehende kstack-tmux-Session anhängen statt eine neue zu starten
- `--detach` — Eine neue Session getrennt starten (kein Terminalfenster öffnen, manuell anhängen)

**Referenz:** [kstack.sh/reference/skills/logs](https://kstack.sh/reference/skills/logs)

</dd>
<dt>

#### `/metrics`

</dt>
<dd>

Ein KI-gesteuerter Metriken-Abrufer. Beschreibe, was du sehen möchtest, und der Agent löst das richtige Ziel auf, wählt ein sinnvolles Zeitfenster und gibt eine kompakte Zusammenfassung zurück. Schreibgeschützt und mutiert niemals den Cluster-Zustand.

**Wie es funktioniert:** Der Agent übersetzt deine Beschreibung in eine Abfrage gegen die passende Quelle (`metrics-server` oder Prometheus), berichtet Zusammenfassungsstatistiken (p50, p95, Max) statt die vollständige Serie durch das Modell zu pipen, und zeigt die aufgelöste Abfrage vor der Ausführung an, wenn der Umfang breiter als beabsichtigt wirkt. Für das *Warum* einer Metrikbewegung wird an [`/logs`](#logs) übergeben; für Ursachenkontext an [`/investigate`](#investigate); für einen vollständigen Rightsizing-Sweep an [`/audit-cost`](#audit-cost).

**Argumente:**
- `<target>` — Natürlichsprachige Beschreibung (`api`, `Speicher bei checkout letzte 1h`, `Top-Pods nach CPU in payments`). Optional — der Skill fragt nach, wenn weggelassen.

**Optionen:** Keine. Ziel, Metrik und Zeitfenster über natürliche Sprache im Prompt oder in Folgefragen einschränken.

**Referenz:** [kstack.sh/reference/skills/metrics](https://kstack.sh/reference/skills/metrics)

</dd>
<dt>

#### `/exec`

</dt>
<dd>

Eine KI-gesteuerte Version von `kubectl exec`. Beschreibe das Ziel in natürlicher Sprache und der Agent wählt den richtigen Mechanismus: ein normaler `exec` in einen laufenden Container, ein ephemerer Debug-Container, wenn das Ziel keine verwendbare Shell hat, oder eine privilegierte Shell auf einem Knoten. Die Session läuft in einem **tmux**-Fenster, mit dem sowohl du als auch der Agent verbunden sind — jeder kann tippen, beide sehen die Ausgabe.

**Wie es funktioniert:** Der Agent startet eine getrennte tmux-Session (z. B. `kstack-exec-api-server`), versucht ein neues Terminalfenster damit zu öffnen, und gibt den `tmux attach`-Befehl im Chat als Fallback aus. Der Agent liest aus dem Bereich sparsam, um Token zu sparen. Sag ihm, es zu beenden, und es beendet die tmux-Session und löscht alle erstellten Pods.

**Anforderungen:** `tmux` im `$PATH` des Agenten.

**Sicherheit:** `/exec` wird mit `disable-model-invocation: true` ausgeliefert — der Agent startet angesichts der oben genannten privilegierten Modi nie selbstständig eine Shell. Es läuft nur, wenn du `/exec` eingibst, absichtlich.

**Argumente:**
- `<target>` — Natürlichsprachige Beschreibung (`api`, `api/sidecar`, `node worker-3`, `debug api`). Optional — der Skill fragt nach, wenn weggelassen.

**Optionen:**
- `--image <image>` — Image für Knoten- und Debug-Container-Modi (Standard `netshoot`)
- `--attach` — Den Agenten an eine bestehende kstack-tmux-Session anhängen statt eine neue zu starten
- `--detach` — Eine neue Session getrennt starten (kein Terminalfenster öffnen, manuell anhängen)

**Referenz:** [kstack.sh/reference/skills/exec](https://kstack.sh/reference/skills/exec)

</dd>
</dl>

---

### Audits

Alle Audit-Skills erzeugen eine gerankte Fundliste (Schweregrad + Evidenz + empfohlene Lösung).

<dl>
<dt>

#### `/audit-security`

</dt>
<dd>

RBAC-Überprüfung, Pod-Sicherheitslage und Empfehlungen zur Rechteminimierung. Sucht nach überprivilegierten Identitäten und Workloads — `ServiceAccounts` mit mehr Zugriff als sie nutzen, Pods, die als root laufen oder Host-Level-Escapes haben, und Bindings, die cluster-weite Befugnisse gewähren, wo eine namespace-begrenzte Rolle ausreichen würde.

**Wie es funktioniert:** Fragt nur die Kubernetes-API ab; kein exec, kein Log-Zugriff. Funde werden nach Blastradiusgrankt (cluster-weit Wildcards über namespace-weit, Host-Escapes über fehlenden seccomp). RBAC-Prüfungen sind **statisch** — sie finden, was `Roles` gewähren, nicht was Subjekte tatsächlich nutzen; die Erkennung wirklich ungenutzter Berechtigungen erfordert Audit-Log-Analyse, die dieser Skill nicht durchführt. `Secrets` werden nur nach Name, Namespace und Typ referenziert — Inhalte werden nie gelesen.

**Argumente:**
- `<scope>` — Natürlichsprachiger Umfang (`rbac`, `Pods in kube-system`). Optional — für einen vollständigen Sweep weglassen.

**Optionen:** Keine. Umfang über natürliche Sprache im Prompt oder in Folgefragen einschränken.

**Referenz:** [kstack.sh/reference/skills/audit-security](https://kstack.sh/reference/skills/audit-security)

</dd>
<dt>

#### `/audit-network`

</dt>
<dd>

NetworkPolicy-, Service-, Ingress-, Gateway-API-, DNS- und Verschlüsselungs-Sanity-Checks. Sucht nach kaputten oder fehlenden Teilen im Cluster-Netzwerk wie `NetworkPolicy`-Instanzen, die nichts abgleichen, `Services` ohne Endpoints, `Ingress`- und Gateway-API-Routen, die nicht aufgelöst werden, DNS-Probleme und Workloads, die im Klartext kommunizieren, obwohl ein Mesh verfügbar ist.

**Wie es funktioniert:** Fragt die Kubernetes-API plus CoreDNS-Metriken und Mesh-CRDs ab, wenn vorhanden. TLS-Prüfungen unterscheiden "Secret-Inhalte nicht lesbar wegen RBAC" von "abgelaufen" statt falsch-positive Meldungen zu berichten. Funde sind nach Workflow gruppiert und enthalten die Evidenz (Selektoren, Endpoints, ConfigMap-Schlüssel), nicht nur das Urteil.

**Argumente:**
- `<scope>` — Natürlichsprachiger Umfang (`policies`, `Ingress in prod`). Optional — für einen vollständigen Sweep weglassen.

**Optionen:** Keine. Umfang über natürliche Sprache im Prompt oder in Folgefragen einschränken.

**Referenz:** [kstack.sh/reference/skills/audit-network](https://kstack.sh/reference/skills/audit-network)

</dd>
<dt>

#### `/audit-cost`

</dt>
<dd>

Ressourcenverschwendung und Rightsizing-Empfehlungen. Sucht nach Workloads, die überprovisioniert, inaktiv oder mit Speicher und Load Balancern belegt sind, die niemand nutzt.

**Wie es funktioniert:** Führt mehrere Workflows parallel aus und verbindet `metrics-server`- und Prometheus-Lesungen mit der Kubernetes-API für `Job`/`CronJob`-Status, PV/PVC-Bindung und `LoadBalancer`-Endpoints. Funde sind nach potenzieller Auswirkung gerankt (große Anfrage-vs.-Nutzungs-Lücken und inaktive Workloads über nicht gemounteten PVCs und `Released`-PVs), und nur Anfrage-vs.-Nutzungs-Lücken, die in der Praxis wichtig genug sind, werden markiert — kleine Deltas sind Rauschen. Der Header gibt immer die Quelle an (`metrics-server` für Live, Prometheus für historisch) und das effektive Lookback, damit der Leser beurteilen kann, wie viel Gewicht er den Empfehlungen geben soll.

**Argumente:**
- `<scope>` — Natürlichsprachiger Umfang (`requests`, `inaktiv in staging`). Optional — für einen vollständigen Sweep weglassen.

**Optionen:** Keine. Umfang über natürliche Sprache im Prompt oder in Folgefragen einschränken.

**Referenz:** [kstack.sh/reference/skills/audit-cost](https://kstack.sh/reference/skills/audit-cost)

</dd>
<dt>

#### `/audit-outdated`

</dt>
<dd>

Veraltete Cluster-Komponenten, bekannte CVEs und verfügbare Versions-Updates. Sucht nach Versionsdrift bei Control Plane, Knoten, Container-Images, Helm-Charts, CRDs, Operatoren und der API-Oberfläche, auf die deine Manifeste abzielen.

**Wie es funktioniert:** Führt die Workflows parallel gegen die Kubernetes-API plus externe Indizes (Release-Zeitpläne, Registries, Helm-Repos, Trivy-DB, CVE-Feeds) aus. Funde werden nach Image-Digest dedupliziert, sodass ein veraltetes Image, das über viele Pods geteilt wird, den Bericht nicht dominiert. CVE-Einträge enthalten Schweregrad und CISA-KEV-Status, wenn verfügbar — KEV-Treffer werden höher gerankt als CVSS-high-Funde ohne bekannte Ausnutzung. "Drift innerhalb des unterstützten Fensters" wird separat von "EOL" gemeldet — ersteres ist routinemäßig, letzteres ist dringend. Für Registries außerhalb der unterstützten Liste sagt der Skill das, statt das Image stillschweigend zu überspringen.

**Argumente:**
- `<scope>` — Natürlichsprachiger Umfang (`images`, `CVEs in kube-system`). Optional — für einen vollständigen Sweep weglassen.

**Optionen:** Keine. Umfang über natürliche Sprache im Prompt oder in Folgefragen einschränken.

**Referenz:** [kstack.sh/reference/skills/audit-outdated](https://kstack.sh/reference/skills/audit-outdated)

</dd>
</dl>

---

### Sonstiges

<dl>
<dt>

#### `/cleanup`

</dt>
<dd>

Entfernt jede Ressource, die kstack im Cluster erstellt hat. Das Gegenstück zu [`/forget`](#forget), das lokalen Zustand löscht.

**Was entfernt wird:** Alles, was mit `kstack.kubetail.com/owned-by=kstack` annotiert ist — ephemere Debug-Container und privilegierte Node-Shell-Pods aus [`/exec`](#exec), kurzlebige Toolbox-Pods und alle temporären RBAC- oder ConfigMaps, die zu deren Unterstützung erstellt wurden. Ressourcen ohne die Annotation werden niemals berührt, auch wenn sie im selben Namespace leben.

**Wie es funktioniert:** Der Agent listet alles, was er gefunden hat, nach Namespace und Art gruppiert auf und bittet dich vor dem Löschen um Bestätigung. Du kannst den gesamten Satz genehmigen oder in natürlicher Sprache sagen, dass bestimmte Elemente übersprungen werden sollen. Wenn ein Löschvorgang fehlschlägt — normalerweise ein Finalizer- oder Berechtigungsproblem — berichtet der Agent, welche Ressourcen übrig bleiben und warum, statt blind zu wiederholen.

**Sicherheit:** `/cleanup` wird mit `disable-model-invocation: true` ausgeliefert — der Agent startet nie selbstständig eine Bereinigung. Es läuft nur, wenn du `/cleanup` eingibst, da es Cluster-Ressourcen löscht.

**Optionen:** Keine. Verwende das globale `--context <ctx>`-Flag, um einen anderen Cluster anzusprechen.

**Referenz:** [kstack.sh/reference/skills/cleanup](https://kstack.sh/reference/skills/cleanup)

</dd>
<dt>

#### `/forget`

</dt>
<dd>

Löscht kstacks lokalen Zustand auf deinem Rechner. Mit der Zeit baut kstack ein Arbeitsgedächtnis deiner Cluster auf — aktuelle Abfrageergebnisse, erkannte Integrationen, Ressourcen-Fingerabdrücke und Baselines, die es zur Anomalieerkennung verwendet. Dieser Skill erzwingt einen Neustart. Er berührt den Cluster selbst nicht; dafür siehe [`/cleanup`](#cleanup).

**Was gelöscht wird:** Zustand liegt unter `~/.config/kstack/`, aufgeteilt nach kubeconfig-Kontext.
- **Cache** (`~/.config/kstack/cache/<context>/`) — aktuelle Abfrageergebnisse, Log-Puffer, Deduplizierungstabellen, laufender Watcher-Zustand. Günstig neu aufzubauen; frei zu löschen.
- **Gelernter Zustand** (`~/.config/kstack/state/<context>/`) — erkannte Integrationen, Ressourcen-Fingerabdrücke, Baselines, cluster-spezifische Einstellungen. Wird bei nächster Verwendung neu aufgebaut, kann aber ein paar Interaktionen brauchen, um vollständig wiederhergestellt zu sein.

**Wie es funktioniert:** Standardmäßig werden Cache und gelernter Zustand für den aktuellen kubeconfig-Kontext gelöscht — das Vergessen von `staging` wirkt sich nie auf `prod` aus. Verwende das globale `--context <ctx>`-Flag, um einen anderen Cluster anzusprechen. Führe es nach einem Cluster-Neuaufbau oder einer Migration aus (damit kstack aufhört, veralteten Fingerabdrücken zu vertrauen), wenn Baselines sich veraltet anfühlen, wenn eine frühere Session etwas Falsches gelernt hat, oder wenn du den Rechner übergibst und keinen cluster-spezifischen Zustand hinterlassen möchtest.

**Sicherheit:** `/forget` wird mit `disable-model-invocation: true` ausgeliefert — der Agent löscht nie selbstständig lokalen Zustand. Es läuft nur, wenn du `/forget` eingibst, damit zwischengespeicherter Kontext nicht unerwartet verloren geht.

**Optionen:**
- `--all` — Cache und gelernten Zustand für jeden Kontext löschen, nicht nur für den aktuellen.

**Referenz:** [kstack.sh/reference/skills/forget](https://kstack.sh/reference/skills/forget)

</dd>
</dl>

## Upgrade

Wenn du einen kstack-Skill ausführst, prüft der Agent still, ob eine neuere kstack-Version verfügbar ist, und zeigt einen einzeiligen Hinweis oben in seiner Antwort an, wenn er eine findet. Sag einfach **"upgrade kstack"** und der Agent führt das kstack-Upgrade-Skript in deinem Namen aus; sag **"dismiss"**, um den Hinweis bis zum nächsten Release auszublenden. Dies funktioniert sowohl für globale als auch lokale Installationen.

Du kannst den Helper auch direkt ausführen:

```console
# Globale Installation
~/.config/kstack/bin/upgrade

# Lokale Installation (aus dem Projektverzeichnis)
./.kstack/bin/upgrade
```

Upgrades sind idempotent und können jederzeit sicher ausgeführt werden.

## Deinstallation

Führe den mit deiner Installation mitgelieferten Deinstallations-Helper aus:

```console
# Globale Installation
~/.config/kstack/bin/uninstall

# Lokale Installation (aus dem Projektverzeichnis)
./.kstack/bin/uninstall
```

Beide Helper fragen vor dem Entfernen nach. Sie löschen das Installationswurzelverzeichnis (`~/.config/kstack` oder `<project>/.kstack`) und jeden kstack-eigenen Skill-Slot und lassen benutzer-erstellte Skills in denselben Agenten-Verzeichnissen unberührt.

## Entwicklung

Das Installer-Payload liegt unter `src/` (Skills, Helper, Lib, Schemata). Dev-Tooling — `Makefile`, `scripts/`, `tests/`, CI — sitzt am Repository-Stammverzeichnis. Wenn du an kstack hackst, sieh `CONTRIBUTING.md` für den vollständigen Mitwirkenden-Leitfaden.

Häufige Mitwirkenden-Befehle über das Root-`Makefile`:

```console
make install      # Dev-Modus-Installation — rendert Skills in <repo>/.<agent>/skills/
make test         # Schnelle Bats-Stufen (Unit + Integration)
make test-e2e     # Cluster-gestützte Stufe (kind + docker)
make test-evals   # Eval-Harness (benötigt ANTHROPIC_API_KEY oder Claude CLI)
make lint         # shellcheck
make clean        # Dev-Modus-Artefakte entfernen
```

Jedes Ziel führt ein Skript unter `scripts/` aus, das auch direkt ausgeführt werden kann.

`make test` benötigt bats-core (`brew install bats-core` / `apt install bats`). Tests liegen in `tests/unit/` (Source-Funktions-Tests) und `tests/integration/` (End-to-End-CLI-Tests gegen isoliertes `$HOME` und lokale Bare-Git-Repos). CI führt die vollständige Suite auf Ubuntu, macOS und Windows für jeden PR aus — siehe `.github/workflows/ci.yml`.

## Mitmachen

Bei Kubetail bauen wir die **benutzerfreundlichste**, **kostengünstigste** und **sicherste** Logging-Plattform für Kubernetes und würden uns über deine Beiträge freuen! So kannst du helfen:

* UI/UX-Design
* React-Frontend-Entwicklung
* Fehler melden und Funktionen vorschlagen

Siehe [CONTRIBUTING.md](CONTRIBUTING.md) für Entwicklungssetup und Richtlinien. Erreichbar unter hello@kubetail.com oder tritt unserem [Discord-Server](https://discord.gg/CmsmWAVkvX) oder [Slack-Kanal](https://join.slack.com/t/kubetail/shared_invite/zt-2cq01cbm8-e1kbLT3EmcLPpHSeoFYm1w) bei.

## Hinweise

* Inspiriert von Garry Tans [gstack](https://github.com/garrytan/gstack)

Mit 🧿 in Istanbul gemacht
