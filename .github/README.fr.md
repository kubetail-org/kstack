# kstack

*Pack de compétences pour Claude Code qui vous aide à surveiller vos clusters K8s de manière superintelligente*

<a href="https://discord.gg/CmsmWAVkvX"><img src="https://img.shields.io/discord/1212031524216770650?logo=Discord&style=flat-square&logoColor=FFFFFF&labelColor=5B65F0&label=Discord&color=64B73A"></a>
[![Slack](https://img.shields.io/badge/Slack-kubetail-364954?logo=slack&labelColor=4D1C51)](https://kubernetes.slack.com/archives/C08SHG1GR37)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)
[![Contributor Resources](https://img.shields.io/badge/Contributor%20Resources-purple?style=flat-square)](https://github.com/kubetail-org)

[English](../README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Español](README.es.md) | [Português](README.pt-BR.md) | Français

## Introduction

<img width="350" alt="kstack" src="https://github.com/user-attachments/assets/cfe998de-a85a-44bb-8eb2-5f5efe7449ea" />
<br>
<br>

**Kstack** est un pack de compétences pour Claude Code qui vous aide à effectuer des tâches de surveillance, de dépannage et d'audit sur vos clusters K8s de manière intelligente et efficace. En plus d'utiliser des outils standard comme kubectl, il délègue le travail shell à des outils comme [Kubetail](https://github.com/kubetail-org/kubetail), [Helm](https://helm.sh), [Trivy](https://github.com/aquasecurity/trivy), [Pluto](https://github.com/FairwindsOps/pluto) avant d'envoyer les résultats à Claude, maintenant les réponses rapides et efficaces en tokens. Kstack détecte également les services en cours d'exécution dans votre cluster et utilise leurs outils spécialisés si nécessaire (p. ex., [Cilium](https://cilium.io), [Istio](https://istio.io)).

Une fois kstack installé, vous aurez accès à ces compétences dans Claude Code :

**Surveillance**
* `/cluster-status` — Instantané de santé du cluster (redémarrages de Pod, conditions des nœuds, pression des ressources)
* `/events` — Événements récents, classés par sévérité

**Dépannage**
* `/investigate` — Analyse des causes profondes à travers les événements, logs et ressources associées
* `/logs` — Session tmux partagée qui traduit le langage naturel en récupérations et analyses de logs (via [Kubetail](https://github.com/kubetail-org/kubetail))
* `/metrics` — Récupérer les métriques CPU, mémoire et autres ressources pour les pods, nœuds et charges de travail
* `/exec` — Shell tmux partagé dans un pod, nœud ou conteneur de débogage éphémère

**Audits**
* `/audit-security` — RBAC, posture de sécurité des pods, réduction des privilèges
* `/audit-network` — NetworkPolicy, Service, Ingress, GatewayAPI, DNS et vérifications du chiffrement
* `/audit-cost` — Demandes vs. utilisation, surprovisionment, capacité inactive
* `/audit-outdated` — Services obsolètes, CVEs connus, mises à jour de version disponibles

**Divers**
* `/cleanup` — Supprimer toutes les ressources appartenant à kstack du cluster (conteneurs de débogage, clones de pods, jobs watcher)
* `/forget` — Vider le cache local de kstack et supprimer ce qu'il a appris sur vos clusters

Notre objectif est d'apporter la puissance de l'IA à la surveillance K8s d'une manière conviviale et rentable qui vous maintient en contrôle. Si vous remarquez un bug ou avez une suggestion, créez un Issue GitHub ou envoyez-nous un e-mail (hello@kubetail.com) !

## Démarrage rapide

Pour installer les compétences kstack globalement, exécutez cette commande :

```console
curl -sS https://kstack.sh/install | bash
```

Alternativement, vous pouvez les installer localement dans un répertoire de projet spécifique :

```console
curl -sS https://kstack.sh/install | bash -s -- --local
```

Une fois installées, les compétences seront disponibles dans vos sessions d'agent :

```
───────────────────────────────────
❯ /kstack-cluster-status
───────────────────────────────────
```

Par défaut, le script installera les compétences avec un préfixe d'espace de noms kstack-* mais vous pouvez le désactiver avec le flag --no-prefix. Il installera également les compétences pour tous vos agents disponibles (p. ex., Claude, Codex, OpenCode), mais vous pouvez choisir des agents individuels avec le flag --agent (voir [Installation](https://kstack.sh/concepts/installation)).

Kstack utilise votre fichier `kubeconfig` local pour l'authentification, il pourra donc utiliser vos permissions RBAC pour effectuer des actions en votre nom. S'il rencontre des problèmes de permissions, il vous en informera.

## Autres agents IA

Kstack fonctionne avec n'importe quel agent IA qui supporte les compétences, pas seulement Claude. Le bootstrap curl détecte automatiquement quelles CLIs d'agents se trouvent dans votre `PATH` et installe pour chacune. Vous pouvez cibler un agent spécifique avec `--agent <name>` :

| Agent            | Flag               | Chemin d'installation global   |
|------------------|--------------------|--------------------------------|
| OpenAI Codex CLI | `--agent codex`    | `~/.codex/skills/`             |
| OpenCode         | `--agent opencode` | `~/.config/opencode/skills/`   |
| Cursor           | `--agent cursor`   | `~/.cursor/skills/`            |
| Factory Droid    | `--agent factory`  | `~/.factory/skills/`           |
| Slate            | `--agent slate`    | `~/.slate/skills/`             |
| Kiro             | `--agent kiro`     | `~/.kiro/skills/`              |
| Hermes           | `--agent hermes`   | `~/.hermes/skills/`            |
| Pi               | `--agent pi`       | `~/.pi/agent/skills/`          |

Les installations locales reflètent cette structure sous le répertoire du projet (p. ex., `<project>/.codex/skills/`) et ne sont détectées que lorsque l'agent est exécuté depuis ce répertoire. Pi est la seule exception — son répertoire de skills local est `<project>/.pi/skills/` (sans le segment `agent/`).

## Référence des compétences

Chaque compétence est invoquée avec `/<name>` dans une session d'agent. Toutes les compétences sont en lecture seule par défaut — toute action qui mute l'état du cluster nécessite une confirmation explicite. Les compétences respectent votre contexte `kubeconfig` local et le RBAC.

**Flags globaux** (supportés par chaque compétence) :

| Flag              | Description                                                              |
|-------------------|--------------------------------------------------------------------------|
| `--context <ctx>` | Remplacer le contexte kubeconfig actuel                                  |
| `--namespace <n>` | Limiter l'exécution à un seul namespace (par défaut tous les accessibles) |
| `--json`          | Émettre une sortie structurée pour la canaliser vers d'autres outils     |
| `--help`          | Ouvrir la documentation de référence de la compétence dans votre navigateur |

---

### Surveillance

<dl>
<dt>

#### `/cluster-status`

</dt>
<dd>

Un instantané dense de la santé du cluster — conditions des nœuds, agrégats de pods et une liste classée des problèmes qui importent vraiment.

**Ce qu'il vérifie :** identité du cluster (contexte, version Kubernetes, plateforme), conditions `Ready`/`MemoryPressure`/`DiskPressure`/`PIDPressure` des nœuds et `SchedulingDisabled`, répartition plan de contrôle vs. worker, phase du pod et `Ready` dans tous les namespaces, pods avec des compteurs de redémarrages non nuls, et une liste des principaux problèmes classés (top 5 par sévérité).

**Comment ça fonctionne :** déploie `kubectl version`, `kubectl get nodes -o json` et `kubectl get pods -A -o json` en parallèle, écrivant chacun dans un cache par contexte (`cluster.json`, `nodes.json`, `pods.json`). L'agrégation et le classement par sévérité se font côté client. Les questions de suivi ("lister les pods", "pods sur <nœud>", "quels nœuds ont des taints") sont répondues en lisant le cache avec `jq` plutôt qu'en réinvoquant la compétence.

**Options :**
- `--refresh` — récupérer les données les plus récentes, en contournant et actualisant le cache (par défaut : `false`)
- `--ttl <duration>` — mettre à jour le cache uniquement s'il est plus ancien que `<duration>` (par défaut : `15m`)

**Référence :** [kstack.sh/reference/skills/cluster-status](https://kstack.sh/reference/skills/cluster-status)

</dd>
<dt>

#### `/events`

</dt>
<dd>

Événements récents du cluster, regroupés par raison et classés par sévérité pour que le signal ne se noie pas dans le bruit `Pulled`/`Created`/`Started`.

**Ce qu'il vérifie :** événements `Warning` dans tous les namespaces, regroupés par `(reason, involvedObject.kind, namespace)` ; événements `Normal` notables (`Killing`, `Preempting`, `NodeNotReady`, `Rebooted`, `FailedScheduling`) avec des raisons bavards (`Pulled`, `Created`, `Started`, `Scheduled`, `SuccessfulCreate`) réduites en une ligne de queue. Chaque groupe comprend le compte, les horodatages premier/dernier, le message le plus récent et les objets impliqués.

**Comment ça fonctionne :** un seul appel `kubectl get events --all-namespaces` (contre `events.k8s.io/v1`, trié côté serveur par `lastTimestamp`), écrit dans le cache par contexte comme `events.json`. L'agrégation et le classement se font côté client. Les questions de suivi ("uniquement payments", "événements sur pod/checkout-7c9", "afficher les supprimés") sont répondues en lisant le cache avec `jq` — et remontent les propriétaires d'un niveau (`Pod` → `ReplicaSet` → `Deployment`) pour ne pas manquer les événements déclenchés par les contrôleurs.

**Options :**
- `--refresh` — récupérer les données les plus récentes, en contournant et actualisant le cache (par défaut : `false`)
- `--ttl <duration>` — mettre à jour le cache uniquement s'il est plus ancien que `<duration>` (par défaut : `5m`)

**Référence :** [kstack.sh/reference/skills/events](https://kstack.sh/reference/skills/events)

</dd>

---

### Dépannage

<dl>
<dt>

#### `/investigate`

</dt>
<dd>

Lance une investigation de cause profonde sur une ressource défaillante ou suspecte. Lorsque la compétence est invoquée, elle exécute un script pour recueillir un paquet de données initial et informe l'agent. À partir de là, vous pouvez poser des questions de suivi en langage naturel et l'agent décide de répondre depuis ce qu'il a, de récupérer quelque chose de nouveau ou d'utiliser un autre outil.

**Ce qu'il collecte :** spec et status des ressources problématiques ; événements sur ces ressources et leurs propriétaires (le `ReplicaSet` et `Deployment` d'un `Pod`, le `CronJob` d'un `Job`, etc.) ; logs des conteneurs actuels et précédents, tronqués aux lignes susceptibles de contenir la défaillance ; ressources associées évidentes (`Service` de support, noms de `ConfigMap`/`Secret` montés, `PVC`s liés, `ServiceAccount` référencé) ; et le nœud sur lequel les pods sont planifiés lorsque c'est pertinent.

**Comment ça fonctionne :** la compétence charge le paquet depuis l'API Kubernetes et informe l'agent sur comment le lire (codes de sortie, raisons d'événements, combinaisons d'états communes), quand les questions de suivi doivent refaire une récupération plutôt que raisonner depuis le paquet obsolète, et quand transférer vers [`/logs`](#logs), [`/exec`](#exec) ou [`/metrics`](#metrics).

**Arguments :**
- `<target>` — `<kind>/<name>` (p. ex., `pod/checkout-7c9`) ou langage naturel (`le deployment api`, `pourquoi checkout plante`). Optionnel — la compétence demandera si omis.

**Options :** aucune. Limiter les logs, fenêtres temporelles ou ressources via le langage naturel dans le prompt ou les questions de suivi.

**Référence :** [kstack.sh/reference/skills/investigate](https://kstack.sh/reference/skills/investigate)

</dd>
<dt>

#### `/logs`

</dt>
<dd>

Un récupérateur de logs alimenté par IA. Décrivez ce que vous cherchez en langage naturel et l'agent trouve les bons pods, choisit la fenêtre temporelle et construit le filtre grep pour récupérer uniquement les lignes qui importent. Le stream s'exécute dans une fenêtre **tmux** à laquelle vous et l'agent êtes tous les deux connectés.

**Comment ça fonctionne :** l'agent traduit votre description en une requête Kubetail, démarre une session tmux détachée (p. ex., `kstack-logs-api-server`), essaie d'ouvrir une nouvelle fenêtre de terminal connectée à elle et imprime la commande `tmux attach` dans le chat en secours. Vous et l'agent partagez le même panneau — vous pouvez faire défiler, rechercher ou regarder le tail en direct ; l'agent lit de manière conservatrice pour économiser les tokens.

**Prérequis :** `tmux` dans le `$PATH` de l'agent et Kubetail installé dans le cluster (la compétence propose de l'installer via Helm si absent).

**Arguments :**
- `<target>` — description en langage naturel de ce qu'il faut récupérer (`api`, `erreurs de la dernière heure sur api`, `checkout pour "timeout" dans les 15 dernières minutes`). Optionnel — la compétence demandera si omis.

**Options :**
- `--attach` — connecter l'agent à une session tmux kstack existante plutôt qu'en démarrer une nouvelle
- `--detach` — démarrer une nouvelle session détachée (sans ouvrir de fenêtre de terminal, connecter manuellement)

**Référence :** [kstack.sh/reference/skills/logs](https://kstack.sh/reference/skills/logs)

</dd>
<dt>

#### `/metrics`

</dt>
<dd>

Un récupérateur de métriques alimenté par IA. Décrivez ce que vous voulez voir et l'agent résout la bonne cible, choisit une fenêtre temporelle sensée et retourne un résumé compact. En lecture seule et ne mute jamais l'état du cluster.

**Comment ça fonctionne :** l'agent traduit votre description en une requête contre la source appropriée (`metrics-server` ou Prometheus), rapporte des statistiques de résumé (p50, p95, max) plutôt que de canaliser la série complète à travers le modèle, et affiche la requête résolue avant de l'exécuter lorsque la portée semble plus large que prévu. Pour le *pourquoi* d'un mouvement de métrique, transfère vers [`/logs`](#logs) ; pour le contexte de cause profonde, [`/investigate`](#investigate) ; pour un balayage complet de dimensionnement, [`/audit-cost`](#audit-cost).

**Arguments :**
- `<target>` — description en langage naturel (`api`, `mémoire sur checkout dernière 1h`, `tops pods par CPU dans payments`). Optionnel — la compétence demandera si omis.

**Options :** aucune. Limiter la cible, la métrique et la fenêtre temporelle via le langage naturel dans le prompt ou les questions de suivi.

**Référence :** [kstack.sh/reference/skills/metrics](https://kstack.sh/reference/skills/metrics)

</dd>
<dt>

#### `/exec`

</dt>
<dd>

Une version de `kubectl exec` alimentée par IA. Décrivez la cible en langage naturel et l'agent choisit le bon mécanisme : un `exec` normal dans un conteneur en cours d'exécution, un conteneur de débogage éphémère lorsque la cible n'a pas de shell utilisable, ou un shell privilégié sur un nœud. La session s'exécute dans une fenêtre **tmux** à laquelle vous et l'agent êtes tous les deux connectés — l'un ou l'autre peut taper, les deux voient la sortie.

**Comment ça fonctionne :** l'agent démarre une session tmux détachée (p. ex., `kstack-exec-api-server`), essaie d'ouvrir une nouvelle fenêtre de terminal connectée à elle et imprime la commande `tmux attach` dans le chat en secours. L'agent lit depuis le panneau de manière conservatrice pour économiser les tokens. Dites-lui de démonter et il tue la session tmux et supprime tous les pods qu'il a créés.

**Prérequis :** `tmux` dans le `$PATH` de l'agent.

**Sécurité :** `/exec` est livré avec `disable-model-invocation: true` — l'agent ne démarre jamais un shell de lui-même. Il ne s'exécute que lorsque vous tapez `/exec`, délibérément, compte tenu des modes privilégiés ci-dessus.

**Arguments :**
- `<target>` — description en langage naturel (`api`, `api/sidecar`, `node worker-3`, `debug api`). Optionnel — la compétence demandera si omis.

**Options :**
- `--image <image>` — image à utiliser pour les modes nœud et conteneur de débogage (par défaut `netshoot`)
- `--attach` — connecter l'agent à une session tmux kstack existante plutôt qu'en démarrer une nouvelle
- `--detach` — démarrer une nouvelle session détachée (sans ouvrir de fenêtre de terminal, connecter manuellement)

**Référence :** [kstack.sh/reference/skills/exec](https://kstack.sh/reference/skills/exec)

</dd>
</dl>

---

### Audits

Toutes les compétences d'audit produisent une liste de résultats classée (sévérité + preuves + correction suggérée).

<dl>
<dt>

#### `/audit-security`

</dt>
<dd>

Revue RBAC, posture de sécurité des pods et recommandations de réduction des privilèges. Recherche les identités et charges de travail sur-privilégiées — `ServiceAccounts` avec plus d'accès qu'ils n'utilisent, pods s'exécutant en tant que root ou avec des échappements au niveau de l'hôte, et bindings accordant un pouvoir à l'échelle du cluster là où un rôle de namespace suffirait.

**Comment ça fonctionne :** interroge uniquement l'API Kubernetes ; pas d'exec, pas d'accès aux logs. Les résultats sont classés par rayon d'impact (wildcards de portée cluster au-dessus de la portée namespace, échappements d'hôte au-dessus des seccomp manquants). Les vérifications RBAC sont **statiques** — elles trouvent ce que les `Roles` accordent, pas ce que les sujets utilisent réellement ; détecter les permissions véritablement inutilisées nécessite une analyse des logs d'audit, que cette compétence ne fait pas. Les `Secrets` sont référencés uniquement par nom, namespace et type — le contenu n'est jamais lu.

**Arguments :**
- `<scope>` — portée en langage naturel (`rbac`, `pods dans kube-system`). Optionnel — omettre pour un balayage complet.

**Options :** aucune. Limiter la portée via le langage naturel dans le prompt ou les questions de suivi.

**Référence :** [kstack.sh/reference/skills/audit-security](https://kstack.sh/reference/skills/audit-security)

</dd>
<dt>

#### `/audit-network`

</dt>
<dd>

Vérifications de bon sens de NetworkPolicy, Service, Ingress, Gateway API, DNS et chiffrement. Recherche les pièces cassées ou manquantes dans le réseau du cluster comme les instances de `NetworkPolicy` qui ne correspondent à rien, les `Services` sans endpoints, les routes `Ingress` et Gateway API qui ne se résoudront pas, les problèmes DNS et les charges de travail communiquant en texte clair quand un mesh est disponible.

**Comment ça fonctionne :** interroge l'API Kubernetes plus les métriques CoreDNS et les CRDs de mesh quand présents. Les vérifications TLS distinguent "contenu de Secret non lisible en raison du RBAC" de "expiré" plutôt que de signaler des faux positifs. Les résultats sont regroupés par flux de travail et incluent les preuves (sélecteurs, endpoints, clés ConfigMap), pas seulement le verdict.

**Arguments :**
- `<scope>` — portée en langage naturel (`policies`, `ingress dans prod`). Optionnel — omettre pour un balayage complet.

**Options :** aucune. Limiter la portée via le langage naturel dans le prompt ou les questions de suivi.

**Référence :** [kstack.sh/reference/skills/audit-network](https://kstack.sh/reference/skills/audit-network)

</dd>
<dt>

#### `/audit-cost`

</dt>
<dd>

Gaspillage de ressources et recommandations de dimensionnement. Recherche les charges de travail sur-provisionnées, inactives ou maintenant du stockage et des équilibreurs de charge que personne n'utilise.

**Comment ça fonctionne :** exécute plusieurs flux de travail en parallèle, joignant les lectures de `metrics-server` et Prometheus à l'API Kubernetes pour le statut `Job`/`CronJob`, la liaison PV/PVC et les endpoints `LoadBalancer`. Les résultats sont classés par impact potentiel (grands écarts demandes vs. utilisation et charges de travail inactives au-dessus des PVCs non montés et des PVs `Released`), et seuls les écarts demandes vs. utilisation assez importants pour avoir de l'importance en pratique sont signalés — les petits deltas sont du bruit. L'en-tête indique toujours la source (`metrics-server` pour le direct, Prometheus pour l'historique) et le lookback effectif pour que le lecteur puisse juger quel poids donner aux recommandations.

**Arguments :**
- `<scope>` — portée en langage naturel (`requests`, `inactif dans staging`). Optionnel — omettre pour un balayage complet.

**Options :** aucune. Limiter la portée via le langage naturel dans le prompt ou les questions de suivi.

**Référence :** [kstack.sh/reference/skills/audit-cost](https://kstack.sh/reference/skills/audit-cost)

</dd>
<dt>

#### `/audit-outdated`

</dt>
<dd>

Composants de cluster obsolètes, CVEs connus et mises à jour de version disponibles. Recherche la dérive de version dans le plan de contrôle, les nœuds, les images de conteneur, les charts Helm, les CRDs, les opérateurs et la surface d'API que vos manifestes ciblent.

**Comment ça fonctionne :** exécute les flux de travail en parallèle contre l'API Kubernetes plus les index externes (calendriers de publication, registres, repos Helm, DB Trivy, flux CVE). Les résultats sont dédupliqués par digest d'image pour qu'une image obsolète partagée entre de nombreux pods ne domine pas le rapport. Les entrées CVE incluent la sévérité et le statut CISA KEV quand disponibles — les hits KEV sont classés au-dessus des résultats CVSS-high sans exploitation connue. "Dérive dans la fenêtre supportée" est rapporté distinctement de "EOL" — le premier est routinier, le second est urgent. Pour les registres en dehors de la liste supportée, la compétence le dit plutôt que de sauter silencieusement l'image.

**Arguments :**
- `<scope>` — portée en langage naturel (`images`, `cves dans kube-system`). Optionnel — omettre pour un balayage complet.

**Options :** aucune. Limiter la portée via le langage naturel dans le prompt ou les questions de suivi.

**Référence :** [kstack.sh/reference/skills/audit-outdated](https://kstack.sh/reference/skills/audit-outdated)

</dd>
</dl>

---

### Divers

<dl>
<dt>

#### `/cleanup`

</dt>
<dd>

Supprime chaque ressource que kstack a créée dans le cluster. Le pendant de [`/forget`](#forget), qui efface l'état local.

**Ce qu'il supprime :** tout ce qui est annoté avec `kstack.kubetail.com/owned-by=kstack` — conteneurs de débogage éphémères et pods de shell de nœud privilégiés de [`/exec`](#exec), pods de boîte à outils de courte durée et tout RBAC temporaire ou ConfigMaps créés pour les supporter. Les ressources sans l'annotation ne sont jamais touchées, même si elles vivent dans le même namespace.

**Comment ça fonctionne :** l'agent liste tout ce qu'il a trouvé, regroupé par namespace et type, et vous demande confirmation avant de supprimer. Vous pouvez approuver l'ensemble ou lui dire en langage naturel de sauter des éléments spécifiques. Si une suppression échoue — généralement un finaliseur ou un problème de permissions — l'agent signale quelles ressources restent et pourquoi, plutôt que de réessayer aveuglément.

**Sécurité :** `/cleanup` est livré avec `disable-model-invocation: true` — l'agent ne lance jamais un nettoyage de lui-même. Il ne s'exécute que lorsque vous tapez `/cleanup`, car il supprime des ressources du cluster.

**Options :** aucune. Utilisez le flag global `--context <ctx>` pour cibler un cluster différent.

**Référence :** [kstack.sh/reference/skills/cleanup](https://kstack.sh/reference/skills/cleanup)

</dd>
<dt>

#### `/forget`

</dt>
<dd>

Efface l'état local de kstack sur votre machine. Au fil du temps, kstack construit une mémoire de travail de vos clusters — résultats de requêtes récents, intégrations détectées, empreintes de ressources et bases de référence qu'il utilise pour détecter les anomalies. Cette compétence force un état vierge. Elle ne touche pas le cluster lui-même ; pour cela, voir [`/cleanup`](#cleanup).

**Ce qu'il efface :** l'état réside sous `~/.config/kstack/`, partitionné par contexte kubeconfig.
- **Cache** (`~/.config/kstack/cache/<context>/`) — résultats de requêtes récents, tampons de logs, tables de déduplication, état de watcher en cours. Bon marché à reconstruire ; effacé librement.
- **État appris** (`~/.config/kstack/state/<context>/`) — intégrations détectées, empreintes de ressources, bases de référence, préférences par cluster. Reconstruit à la prochaine utilisation, mais peut prendre quelques interactions pour se reformer complètement.

**Comment ça fonctionne :** par défaut efface à la fois le cache et l'état appris pour le contexte kubeconfig actuel — oublier `staging` n'affecte jamais `prod`. Utilisez le flag global `--context <ctx>` pour cibler un cluster différent. Exécutez-le après qu'un cluster soit reconstruit ou migré (pour que kstack arrête de faire confiance aux empreintes obsolètes), quand les bases de référence semblent périmées, quand une session précédente lui a appris quelque chose d'erroné, ou quand vous transmettez la machine et souhaitez ne laisser aucun état spécifique au cluster.

**Sécurité :** `/forget` est livré avec `disable-model-invocation: true` — l'agent n'efface jamais l'état local de lui-même. Il ne s'exécute que lorsque vous tapez `/forget`, pour que le contexte mis en cache ne soit pas perdu de manière inattendue.

**Options :**
- `--all` — Effacer le cache et l'état appris pour chaque contexte, pas seulement le courant.

**Référence :** [kstack.sh/reference/skills/forget](https://kstack.sh/reference/skills/forget)

</dd>
</dl>

## Mise à jour

Lorsque vous exécutez une compétence kstack, l'agent vérifie silencieusement si une version plus récente de kstack est disponible et affiche un avis d'une ligne en haut de sa réponse quand il en trouve une. Dites simplement **"upgrade kstack"** et l'agent exécutera le script de mise à jour kstack en votre nom ; dites **"dismiss"** pour masquer l'avis jusqu'à la prochaine version. Cela fonctionne de la même façon pour les installations globales et locales.

Vous pouvez aussi exécuter l'assistant directement :

```console
# Installation globale
~/.config/kstack/bin/upgrade

# Installation locale (depuis le répertoire du projet)
./.kstack/bin/upgrade
```

Les mises à jour sont idempotentes et sûres à exécuter à tout moment.

## Désinstallation

Exécutez l'assistant de désinstallation fourni avec votre installation :

```console
# Installation globale
~/.config/kstack/bin/uninstall

# Installation locale (depuis le répertoire du projet)
./.kstack/bin/uninstall
```

Les deux assistants demandent confirmation avant de supprimer. Ils effacent le répertoire racine d'installation (`~/.config/kstack` ou `<project>/.kstack`) et chaque emplacement de compétences appartenant à kstack, laissant intactes les compétences créées par l'utilisateur dans les mêmes répertoires d'agents.

## Développement

Le payload de l'installateur réside sous `src/` (compétences, assistants, lib, schémas). Les outils de développement — `Makefile`, `scripts/`, `tests/`, CI — se trouvent à la racine du dépôt. Si vous travaillez sur kstack, consultez `CONTRIBUTING.md` pour le guide complet du contributeur.

Commandes courantes des contributeurs, via le `Makefile` racine :

```console
make install      # installation en mode dev — rend les compétences dans <repo>/.<agent>/skills/
make test         # niveaux bats rapides (unité + intégration)
make test-e2e     # niveau soutenu par cluster (kind + docker)
make test-evals   # harnais d'évaluation (nécessite ANTHROPIC_API_KEY ou Claude CLI)
make lint         # shellcheck
make clean        # supprimer les artefacts en mode dev
```

Chaque cible fait appel à un script sous `scripts/` qui est aussi exécutable directement.

`make test` nécessite bats-core (`brew install bats-core` / `apt install bats`). Les tests résident dans `tests/unit/` (tests de fonctions sourcées) et `tests/integration/` (tests CLI de bout en bout contre `$HOME` isolé et repos git bare locaux). CI exécute la suite complète sur Ubuntu, macOS et Windows pour chaque PR — voir `.github/workflows/ci.yml`.

## S'impliquer

Chez Kubetail, nous construisons la plateforme de logging la plus **conviviale**, **rentable** et **sécurisée** pour Kubernetes et nous adorerions vos contributions ! Voici comment vous pouvez aider :

* Design UI/UX
* Développement frontend React
* Signaler des problèmes et suggérer des fonctionnalités

Voir [CONTRIBUTING.md](CONTRIBUTING.md) pour la configuration de développement et les directives. Contactez-nous à hello@kubetail.com, ou rejoignez notre [serveur Discord](https://discord.gg/CmsmWAVkvX) ou [canal Slack](https://join.slack.com/t/kubetail/shared_invite/zt-2cq01cbm8-e1kbLT3EmcLPpHSeoFYm1w).

## Notes

* Inspiré par le [gstack](https://github.com/garrytan/gstack) de Garry Tan

Fait avec 🧿 à Istanbul
