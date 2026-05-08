# kstack

*Paquete de habilidades para Claude Code que te ayuda a monitorear tus clústeres de K8s de forma superinteligente*

<a href="https://discord.gg/CmsmWAVkvX"><img src="https://img.shields.io/discord/1212031524216770650?logo=Discord&style=flat-square&logoColor=FFFFFF&labelColor=5B65F0&label=Discord&color=64B73A"></a>
[![Slack](https://img.shields.io/badge/Slack-kubetail-364954?logo=slack&labelColor=4D1C51)](https://kubernetes.slack.com/archives/C08SHG1GR37)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)
[![Contributor Resources](https://img.shields.io/badge/Contributor%20Resources-purple?style=flat-square)](https://github.com/kubetail-org)

[English](../README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | Español | [Português](README.pt-BR.md) | [Français](README.fr.md)

## Introducción

<img width="350" alt="kstack" src="https://github.com/user-attachments/assets/cfe998de-a85a-44bb-8eb2-5f5efe7449ea" />
<br>
<br>

**Kstack** es un paquete de habilidades para Claude Code que te ayuda a realizar tareas de monitoreo, resolución de problemas y auditoría en tus clústeres de K8s de forma inteligente y eficiente. Además de usar herramientas estándar como kubectl, delega el trabajo de shell a herramientas como [Kubetail](https://github.com/kubetail-org/kubetail), [Helm](https://helm.sh), [Trivy](https://github.com/aquasecurity/trivy), [Pluto](https://github.com/FairwindsOps/pluto) antes de enviar los resultados a Claude, manteniendo las respuestas rápidas y eficientes en tokens. Kstack también detecta los servicios que se ejecutan en tu clúster y usa sus herramientas especializadas cuando es necesario (p. ej., [Cilium](https://cilium.io), [Istio](https://istio.io)).

Una vez que instales kstack, tendrás acceso a estas habilidades dentro de Claude Code:

**Monitoreo**
* `/cluster-status` — Instantánea de salud del clúster (reinicios de Pod, condiciones de nodos, presión de recursos)
* `/events` — Eventos recientes, ordenados por severidad

**Resolución de problemas**
* `/investigate` — Análisis de causa raíz a través de eventos, logs y recursos relacionados
* `/logs` — Sesión tmux compartida que traduce lenguaje natural en búsquedas y análisis de logs (via [Kubetail](https://github.com/kubetail-org/kubetail))
* `/metrics` — Obtener métricas de CPU, memoria y otros recursos para pods, nodos y cargas de trabajo
* `/exec` — Shell tmux compartido en un pod, nodo o contenedor de depuración efímero

**Auditorías**
* `/audit-security` — RBAC, postura de seguridad de pods, reducción de privilegios
* `/audit-network` — NetworkPolicy, Service, Ingress, GatewayAPI, DNS y verificaciones de cifrado
* `/audit-cost` — Solicitudes vs. uso, sobreaprovisionamiento, capacidad inactiva
* `/audit-outdated` — Servicios obsoletos, CVEs conocidos, actualizaciones de versión disponibles

**Miscelánea**
* `/cleanup` — Eliminar todos los recursos propiedad de kstack del clúster (contenedores de depuración, clones de pods, trabajos watcher)
* `/forget` — Limpiar la caché local de kstack y descartar lo que aprendió sobre tus clústeres

Nuestro objetivo es llevar el poder de la IA a la monitorización de K8s de una manera amigable y rentable que te mantenga en control. Si notas un error o tienes una sugerencia, ¡crea un Issue de GitHub o envíanos un correo electrónico (hello@kubetail.com)!

## Inicio rápido

Para instalar las habilidades de kstack globalmente, ejecuta este comando:

```console
curl -sS https://kstack.sh/install | bash
```

Alternativamente, puedes instalarlas localmente dentro de un directorio de proyecto específico:

```console
curl -sS https://kstack.sh/install | bash -s -- --local
```

Una vez instaladas, las habilidades estarán disponibles dentro de tus sesiones de agente:

```
───────────────────────────────────
❯ /kstack-cluster-status
───────────────────────────────────
```

De forma predeterminada, el script instalará las habilidades con un prefijo de espacio de nombres kstack-*, pero puedes deshabilitarlo con el flag --no-prefix. También instalará las habilidades para todos los agentes disponibles (p. ej., Claude, Codex, OpenCode), pero puedes elegir agentes individuales con el flag --agent (ver [Instalación](https://kstack.sh/concepts/installation)).

Kstack usa tu archivo `kubeconfig` local para autenticación, por lo que podrá usar tus permisos RBAC para realizar acciones en tu nombre. Si encuentra problemas de permisos, te lo hará saber.

## Otros agentes de IA

Kstack funciona con cualquier agente de IA que soporte habilidades, no solo Claude. El bootstrap de curl detecta automáticamente qué CLIs de agentes están en tu `PATH` e instala para cada uno. Puedes apuntar a un agente específico con `--agent <name>`:

| Agente           | Flag               | Ruta de instalación global     |
|------------------|--------------------|--------------------------------|
| OpenAI Codex CLI | `--agent codex`    | `~/.codex/skills/`             |
| OpenCode         | `--agent opencode` | `~/.config/opencode/skills/`   |
| Cursor           | `--agent cursor`   | `~/.cursor/skills/`            |
| Factory Droid    | `--agent factory`  | `~/.factory/skills/`           |
| Slate            | `--agent slate`    | `~/.slate/skills/`             |
| Kiro             | `--agent kiro`     | `~/.kiro/skills/`              |
| Hermes           | `--agent hermes`   | `~/.hermes/skills/`            |
| Pi               | `--agent pi`       | `~/.pi/agent/skills/`          |

Las instalaciones locales reflejan esta estructura bajo el directorio del proyecto (p. ej., `<project>/.codex/skills/`) y solo se detectan cuando el agente se ejecuta desde dentro de ese directorio. Pi es la única excepción: su directorio local de skills es `<project>/.pi/skills/` (sin el segmento `agent/`).

## Referencia de habilidades

Cada habilidad se invoca con `/<name>` dentro de una sesión de agente. Todas las habilidades son de solo lectura por defecto — cualquier acción que mute el estado del clúster requiere confirmación explícita. Las habilidades respetan tu contexto local de `kubeconfig` y el RBAC.

**Flags globales** (soportados por cada habilidad):

| Flag              | Descripción                                                              |
|-------------------|--------------------------------------------------------------------------|
| `--context <ctx>` | Anular el contexto actual de kubeconfig                                  |
| `--namespace <n>` | Limitar la ejecución a un solo namespace (por defecto todos los accesibles) |
| `--json`          | Emitir salida estructurada para canalizar a otras herramientas           |
| `--help`          | Abrir la documentación de referencia de la habilidad en tu navegador     |

---

### Monitoreo

<dl>
<dt>

#### `/cluster-status`

</dt>
<dd>

Una instantánea densa de la salud del clúster — condiciones de nodos, agregados de pods y una lista ordenada de los problemas que realmente importan.

**Qué verifica:** identidad del clúster (contexto, versión de Kubernetes, plataforma), condiciones `Ready`/`MemoryPressure`/`DiskPressure`/`PIDPressure` de los nodos y `SchedulingDisabled`, división del plano de control vs. worker, fase de pod y `Ready` en todos los namespaces, pods con conteos de reinicios no nulos y una lista de principales problemas ordenados (top 5 por severidad).

**Cómo funciona:** despliega `kubectl version`, `kubectl get nodes -o json` y `kubectl get pods -A -o json` en paralelo, escribiendo cada uno en una caché por contexto (`cluster.json`, `nodes.json`, `pods.json`). La agregación y el ranking de severidad ocurren del lado del cliente. Las preguntas de seguimiento ("listar pods", "pods en <nodo>", "qué nodos tienen taints") se responden leyendo la caché con `jq` en lugar de volver a invocar la habilidad.

**Opciones:**
- `--refresh` — obtener los datos más recientes, omitiendo y actualizando la caché (por defecto: `false`)
- `--ttl <duration>` — solo actualizar la caché si es más antigua que `<duration>` (por defecto: `15m`)

**Referencia:** [kstack.sh/reference/skills/cluster-status](https://kstack.sh/reference/skills/cluster-status)

</dd>
<dt>

#### `/events`

</dt>
<dd>

Eventos recientes del clúster, agrupados por razón y ordenados por severidad para que la señal no se ahogue en el ruido de `Pulled`/`Created`/`Started`.

**Qué verifica:** eventos `Warning` en todos los namespaces, agrupados por `(reason, involvedObject.kind, namespace)`; eventos `Normal` notables (`Killing`, `Preempting`, `NodeNotReady`, `Rebooted`, `FailedScheduling`) con razones locuaces (`Pulled`, `Created`, `Started`, `Scheduled`, `SuccessfulCreate`) colapsadas en una línea de cola. Cada grupo incluye conteo, primera/última marca de tiempo, el mensaje más reciente y los objetos involucrados.

**Cómo funciona:** una sola llamada `kubectl get events --all-namespaces` (contra `events.k8s.io/v1`, ordenada del lado del servidor por `lastTimestamp`), escrita en la caché por contexto como `events.json`. La agregación y el ranking ocurren del lado del cliente. Las preguntas de seguimiento ("solo payments", "eventos en pod/checkout-7c9", "mostrar suprimidos") se responden leyendo la caché con `jq` — y recorren los propietarios un nivel hacia arriba (`Pod` → `ReplicaSet` → `Deployment`) para no perder los eventos disparados por controladores.

**Opciones:**
- `--refresh` — obtener los datos más recientes, omitiendo y actualizando la caché (por defecto: `false`)
- `--ttl <duration>` — solo actualizar la caché si es más antigua que `<duration>` (por defecto: `5m`)

**Referencia:** [kstack.sh/reference/skills/events](https://kstack.sh/reference/skills/events)

</dd>

---

### Resolución de problemas

<dl>
<dt>

#### `/investigate`

</dt>
<dd>

Inicia una investigación de causa raíz en un recurso que falla o es sospechoso. Cuando se invoca la habilidad, ejecuta un script para recopilar un paquete de datos inicial y hace un briefing al agente. Desde allí, puedes hacer preguntas de seguimiento en lenguaje natural y el agente decide si responder desde lo que tiene, obtener algo nuevo o usar otra herramienta.

**Qué recopila:** spec y status de los recursos problemáticos; eventos en esos recursos y sus propietarios (el `ReplicaSet` y `Deployment` de un `Pod`, el `CronJob` de un `Job`, etc.); logs de contenedores actuales y anteriores, truncados a las líneas que probablemente contienen el fallo; recursos relacionados obvios (`Service` de respaldo, nombres de `ConfigMap`/`Secret` montados, `PVC`s vinculados, `ServiceAccount` referenciado); y el nodo en el que están programados los pods cuando es relevante.

**Cómo funciona:** la habilidad carga el paquete desde la API de Kubernetes y hace un briefing al agente sobre cómo leerlo (códigos de salida, razones de eventos, combinaciones de estado comunes), cuándo las preguntas de seguimiento deben volver a obtener datos en lugar de razonar desde el paquete obsoleto, y cuándo transferir a [`/logs`](#logs), [`/exec`](#exec) o [`/metrics`](#metrics).

**Argumentos:**
- `<target>` — `<kind>/<name>` (p. ej., `pod/checkout-7c9`) o lenguaje natural (`el deployment de api`, `por qué checkout está fallando`). Opcional — la habilidad preguntará si se omite.

**Opciones:** ninguna. Limita logs, ventanas de tiempo o recursos mediante lenguaje natural en el prompt o en las preguntas de seguimiento.

**Referencia:** [kstack.sh/reference/skills/investigate](https://kstack.sh/reference/skills/investigate)

</dd>
<dt>

#### `/logs`

</dt>
<dd>

Un recuperador de logs impulsado por IA. Describe lo que estás buscando en lenguaje natural y el agente encuentra los pods correctos, elige la ventana de tiempo y construye el filtro grep para obtener solo las líneas que importan. El stream se ejecuta dentro de una ventana **tmux** a la que tú y el agente están ambos conectados.

**Cómo funciona:** el agente traduce tu descripción en una consulta de Kubetail, inicia una sesión tmux desconectada (p. ej., `kstack-logs-api-server`), intenta abrir una nueva ventana de terminal conectada a ella e imprime el comando `tmux attach` en el chat como respaldo. Tú y el agente comparten el mismo panel — puedes desplazarte, buscar o ver el tail en vivo; el agente lee de forma conservadora para ahorrar tokens.

**Requisitos:** `tmux` en el `$PATH` del agente y Kubetail instalado en el clúster (la habilidad ofrece instalarlo via Helm si falta).

**Argumentos:**
- `<target>` — descripción en lenguaje natural de qué obtener (`api`, `errores de la última hora en api`, `checkout por "timeout" en los últimos 15m`). Opcional — la habilidad preguntará si se omite.

**Opciones:**
- `--attach` — conectar el agente a una sesión tmux de kstack existente en lugar de iniciar una nueva
- `--detach` — iniciar una nueva sesión desconectada (sin abrir ventana de terminal, conectar manualmente)

**Referencia:** [kstack.sh/reference/skills/logs](https://kstack.sh/reference/skills/logs)

</dd>
<dt>

#### `/metrics`

</dt>
<dd>

Un recuperador de métricas impulsado por IA. Describe lo que quieres ver y el agente resuelve el objetivo correcto, elige una ventana de tiempo sensata y devuelve un resumen compacto. Solo lectura y nunca muta el estado del clúster.

**Cómo funciona:** el agente traduce tu descripción en una consulta contra la fuente adecuada (`metrics-server` o Prometheus), reporta estadísticas de resumen (p50, p95, máx) en lugar de canalizar la serie completa a través del modelo, y muestra la consulta resuelta antes de ejecutarla cuando el alcance parece más amplio de lo previsto. Para el *por qué* se movió una métrica, transfiere a [`/logs`](#logs); para contexto de causa raíz, [`/investigate`](#investigate); para un barrido completo de ajuste de tamaño, [`/audit-cost`](#audit-cost).

**Argumentos:**
- `<target>` — descripción en lenguaje natural (`api`, `memoria en checkout última 1h`, `pods principales por CPU en payments`). Opcional — la habilidad preguntará si se omite.

**Opciones:** ninguna. Limita el objetivo, la métrica y la ventana de tiempo mediante lenguaje natural en el prompt o en las preguntas de seguimiento.

**Referencia:** [kstack.sh/reference/skills/metrics](https://kstack.sh/reference/skills/metrics)

</dd>
<dt>

#### `/exec`

</dt>
<dd>

Una versión de `kubectl exec` impulsada por IA. Describe el objetivo en lenguaje natural y el agente elige el mecanismo correcto: un `exec` normal en un contenedor en ejecución, un contenedor de depuración efímero cuando el objetivo no tiene shell utilizable, o un shell privilegiado en un nodo. La sesión se ejecuta dentro de una ventana **tmux** a la que tú y el agente están ambos conectados — cualquiera puede escribir, ambos ven la salida.

**Cómo funciona:** el agente inicia una sesión tmux desconectada (p. ej., `kstack-exec-api-server`), intenta abrir una nueva ventana de terminal conectada a ella e imprime el comando `tmux attach` en el chat como respaldo. El agente lee del panel de forma conservadora para ahorrar tokens. Dile que lo desmonte y matará la sesión tmux y eliminará cualquier pod que haya creado.

**Requisitos:** `tmux` en el `$PATH` del agente.

**Seguridad:** `/exec` viene con `disable-model-invocation: true` — el agente nunca inicia un shell por sí mismo. Solo se ejecuta cuando escribes `/exec`, deliberadamente, dados los modos privilegiados anteriores.

**Argumentos:**
- `<target>` — descripción en lenguaje natural (`api`, `api/sidecar`, `node worker-3`, `debug api`). Opcional — la habilidad preguntará si se omite.

**Opciones:**
- `--image <image>` — imagen para los modos de nodo y contenedor de depuración (por defecto `netshoot`)
- `--attach` — conectar el agente a una sesión tmux de kstack existente en lugar de iniciar una nueva
- `--detach` — iniciar una nueva sesión desconectada (sin abrir ventana de terminal, conectar manualmente)

**Referencia:** [kstack.sh/reference/skills/exec](https://kstack.sh/reference/skills/exec)

</dd>
</dl>

---

### Auditorías

Todas las habilidades de auditoría producen una lista de hallazgos ordenados (severidad + evidencia + corrección sugerida).

<dl>
<dt>

#### `/audit-security`

</dt>
<dd>

Revisión de RBAC, postura de seguridad de pods y recomendaciones de reducción de privilegios. Busca identidades y cargas de trabajo con exceso de privilegios — `ServiceAccounts` con más acceso del que usan, pods que se ejecutan como root o con escapes a nivel de host, y bindings que otorgan poder a nivel de clúster donde una función de namespace sería suficiente.

**Cómo funciona:** consulta solo la API de Kubernetes; sin exec, sin acceso a logs. Los hallazgos se ordenan por radio de explosión (comodines de alcance de clúster por encima de los de namespace, escapes de host por encima de la falta de seccomp). Las verificaciones de RBAC son **estáticas** — encuentran lo que otorgan los `Roles`, no lo que los sujetos realmente usan; detectar permisos verdaderamente no utilizados requiere análisis de registros de auditoría, que esta habilidad no hace. Los `Secrets` se referencian solo por nombre, namespace y tipo — el contenido nunca se lee.

**Argumentos:**
- `<scope>` — alcance en lenguaje natural (`rbac`, `pods en kube-system`). Opcional — omitir para un barrido completo.

**Opciones:** ninguna. Limita el alcance mediante lenguaje natural en el prompt o en las preguntas de seguimiento.

**Referencia:** [kstack.sh/reference/skills/audit-security](https://kstack.sh/reference/skills/audit-security)

</dd>
<dt>

#### `/audit-network`

</dt>
<dd>

Verificaciones de sanidad de NetworkPolicy, Service, Ingress, Gateway API, DNS y cifrado. Busca piezas rotas o faltantes en la red del clúster como instancias de `NetworkPolicy` que no coinciden con nada, `Services` sin endpoints, rutas de `Ingress` y Gateway API que no se resolverán, problemas de DNS y cargas de trabajo que hablan en texto plano cuando hay una malla disponible.

**Cómo funciona:** consulta la API de Kubernetes más métricas de CoreDNS y CRDs de malla cuando están presentes. Las verificaciones TLS distinguen "contenido de Secret no legible debido a RBAC" de "caducado" en lugar de reportar falsos positivos. Los hallazgos están agrupados por flujo de trabajo e incluyen la evidencia (selectores, endpoints, claves de ConfigMap), no solo el veredicto.

**Argumentos:**
- `<scope>` — alcance en lenguaje natural (`policies`, `ingress en prod`). Opcional — omitir para un barrido completo.

**Opciones:** ninguna. Limita el alcance mediante lenguaje natural en el prompt o en las preguntas de seguimiento.

**Referencia:** [kstack.sh/reference/skills/audit-network](https://kstack.sh/reference/skills/audit-network)

</dd>
<dt>

#### `/audit-cost`

</dt>
<dd>

Desperdicio de recursos y recomendaciones de ajuste de tamaño. Busca cargas de trabajo que están sobreaprovisionadas, inactivas o que mantienen almacenamiento y balanceadores de carga que nadie está usando.

**Cómo funciona:** ejecuta varios flujos de trabajo en paralelo, uniendo lecturas de `metrics-server` y Prometheus con la API de Kubernetes para el estado de `Job`/`CronJob`, vinculación de PV/PVC y endpoints de `LoadBalancer`. Los hallazgos se ordenan por impacto potencial (grandes brechas de solicitudes vs. uso y cargas de trabajo inactivas por encima de PVCs no montados y PVs `Released`), y solo se marcan brechas de solicitudes vs. uso lo suficientemente grandes como para importar en la práctica — los pequeños deltas son ruido. El encabezado siempre indica la fuente (`metrics-server` para en vivo, Prometheus para historial) y el lookback efectivo para que el lector pueda juzgar cuánto peso dar a las recomendaciones.

**Argumentos:**
- `<scope>` — alcance en lenguaje natural (`requests`, `inactivo en staging`). Opcional — omitir para un barrido completo.

**Opciones:** ninguna. Limita el alcance mediante lenguaje natural en el prompt o en las preguntas de seguimiento.

**Referencia:** [kstack.sh/reference/skills/audit-cost](https://kstack.sh/reference/skills/audit-cost)

</dd>
<dt>

#### `/audit-outdated`

</dt>
<dd>

Componentes de clúster obsoletos, CVEs conocidos y actualizaciones de versión disponibles. Busca deriva de versión en el plano de control, nodos, imágenes de contenedor, charts de Helm, CRDs, operadores y la superficie de API que apuntan tus manifiestos.

**Cómo funciona:** ejecuta los flujos de trabajo en paralelo contra la API de Kubernetes más índices externos (calendarios de lanzamiento, registros, repos de Helm, DB de Trivy, feeds de CVE). Los hallazgos se deduplicarán por digest de imagen para que una imagen obsoleta compartida entre muchos pods no domine el informe. Las entradas de CVE incluyen severidad y estado CISA KEV cuando están disponibles — los hits de KEV se clasifican por encima de los hallazgos CVSS-high sin explotación conocida. La "deriva dentro de la ventana compatible" se reporta de manera diferente de "EOL" — la primera es rutinaria, la segunda es urgente. Para los registros fuera de la lista compatible, la habilidad lo dice en lugar de omitir silenciosamente la imagen.

**Argumentos:**
- `<scope>` — alcance en lenguaje natural (`images`, `cves en kube-system`). Opcional — omitir para un barrido completo.

**Opciones:** ninguna. Limita el alcance mediante lenguaje natural en el prompt o en las preguntas de seguimiento.

**Referencia:** [kstack.sh/reference/skills/audit-outdated](https://kstack.sh/reference/skills/audit-outdated)

</dd>
</dl>

---

### Miscelánea

<dl>
<dt>

#### `/cleanup`

</dt>
<dd>

Elimina cada recurso que kstack ha creado en el clúster. El complemento de [`/forget`](#forget), que borra el estado local.

**Qué elimina:** cualquier cosa anotada con `kstack.kubetail.com/owned-by=kstack` — contenedores de depuración efímeros y pods de shell de nodo privilegiado de [`/exec`](#exec), pods de caja de herramientas de corta duración y cualquier RBAC temporal o ConfigMaps creados para apoyarlos. Los recursos sin la anotación nunca se tocan, incluso si viven en el mismo namespace.

**Cómo funciona:** el agente lista todo lo que encontró, agrupado por namespace y tipo, y te pide confirmación antes de eliminar. Puedes aprobar todo el conjunto o decirle en lenguaje natural que omita elementos específicos. Si una eliminación falla — generalmente un finalizador o un problema de permisos — el agente reporta qué recursos quedan y por qué, en lugar de reintentar ciegamente.

**Seguridad:** `/cleanup` viene con `disable-model-invocation: true` — el agente nunca inicia una limpieza por sí mismo. Solo se ejecuta cuando escribes `/cleanup`, ya que elimina recursos del clúster.

**Opciones:** ninguna. Usa el flag global `--context <ctx>` para apuntar a un clúster diferente.

**Referencia:** [kstack.sh/reference/skills/cleanup](https://kstack.sh/reference/skills/cleanup)

</dd>
<dt>

#### `/forget`

</dt>
<dd>

Borra el estado local de kstack en tu máquina. Con el tiempo, kstack construye una memoria de trabajo de tus clústeres — resultados de consultas recientes, integraciones detectadas, huellas de recursos y líneas base que usa para detectar anomalías. Esta habilidad fuerza un inicio limpio. No toca el clúster en sí; para eso, consulta [`/cleanup`](#cleanup).

**Qué borra:** el estado vive bajo `~/.config/kstack/`, particionado por contexto de kubeconfig.
- **Caché** (`~/.config/kstack/cache/<context>/`) — resultados de consultas recientes, buffers de log, tablas de deduplicación, estado de watcher en vuelo. Barato de reconstruir; se borra libremente.
- **Estado aprendido** (`~/.config/kstack/state/<context>/`) — integraciones detectadas, huellas de recursos, líneas base, preferencias por clúster. Se reconstruye en el siguiente uso, pero puede tomar algunas interacciones para reformarse completamente.

**Cómo funciona:** por defecto borra tanto la caché como el estado aprendido para el contexto de kubeconfig actual — olvidar `staging` nunca afecta a `prod`. Usa el flag global `--context <ctx>` para apuntar a un clúster diferente. Ejecútalo después de que un clúster se reconstruya o migre (para que kstack deje de confiar en huellas obsoletas), cuando las líneas base se sientan obsoletas, cuando una sesión anterior le enseñó algo incorrecto, o cuando estás pasando la máquina y quieres que no quede ningún estado específico del clúster.

**Seguridad:** `/forget` viene con `disable-model-invocation: true` — el agente nunca borra el estado local por sí mismo. Solo se ejecuta cuando escribes `/forget`, para que el contexto en caché no se pierda inesperadamente.

**Opciones:**
- `--all` — Borrar caché y estado aprendido para cada contexto, no solo el actual.

**Referencia:** [kstack.sh/reference/skills/forget](https://kstack.sh/reference/skills/forget)

</dd>
</dl>

## Actualización

Cuando ejecutas una habilidad de kstack, el agente verifica silenciosamente si hay una versión más nueva de kstack disponible y muestra un aviso de una línea en la parte superior de su respuesta cuando la encuentra. Solo di **"upgrade kstack"** y el agente ejecutará el script de actualización de kstack en tu nombre; di **"dismiss"** para ocultar el aviso hasta la próxima versión. Esto funciona igual tanto para instalaciones globales como locales.

También puedes ejecutar el helper directamente:

```console
# Instalación global
~/.config/kstack/bin/upgrade

# Instalación local (desde el directorio del proyecto)
./.kstack/bin/upgrade
```

Las actualizaciones son idempotentes y seguras para ejecutar en cualquier momento.

## Desinstalación

Ejecuta el helper de desinstalación incluido con tu instalación:

```console
# Instalación global
~/.config/kstack/bin/uninstall

# Instalación local (desde el directorio del proyecto)
./.kstack/bin/uninstall
```

Ambos helpers preguntan antes de eliminar. Limpian el directorio raíz de instalación (`~/.config/kstack` o `<project>/.kstack`) y cada ranura de habilidades propiedad de kstack, dejando las habilidades creadas por el usuario en los mismos directorios de agente sin tocar.

## Desarrollo

El payload del instalador vive bajo `src/` (habilidades, helpers, lib, esquemas). Las herramientas de desarrollo — `Makefile`, `scripts/`, `tests/`, CI — están en la raíz del repositorio. Si estás modificando kstack, consulta `CONTRIBUTING.md` para la guía completa de colaboradores.

Comandos comunes de colaboradores, a través del `Makefile` raíz:

```console
make install      # instalación en modo dev — renderiza habilidades en <repo>/.<agent>/skills/
make test         # niveles bats rápidos (unidad + integración)
make test-e2e     # nivel respaldado por clúster (kind + docker)
make test-evals   # harness de evaluación (requiere ANTHROPIC_API_KEY o Claude CLI)
make lint         # shellcheck
make clean        # eliminar artefactos en modo dev
```

Cada objetivo hace shell a un script bajo `scripts/` que también es ejecutable directamente.

`make test` requiere bats-core (`brew install bats-core` / `apt install bats`). Las pruebas viven en `tests/unit/` (pruebas de funciones de origen) y `tests/integration/` (pruebas CLI de extremo a extremo contra `$HOME` aislado y repos git bare locales). CI ejecuta la suite completa en Ubuntu, macOS y Windows para cada PR — ver `.github/workflows/ci.yml`.

## Participar

En Kubetail, estamos construyendo la plataforma de logging más **amigable**, **rentable** y **segura** para Kubernetes y nos encantaría tu contribución. Cómo puedes ayudar:

* Diseño UI/UX
* Desarrollo frontend con React
* Reportar problemas y sugerir funciones

Consulta [CONTRIBUTING.md](CONTRIBUTING.md) para la configuración de desarrollo y las directrices. Contáctanos en hello@kubetail.com, o únete a nuestro [servidor de Discord](https://discord.gg/CmsmWAVkvX) o [canal de Slack](https://join.slack.com/t/kubetail/shared_invite/zt-2cq01cbm8-e1kbLT3EmcLPpHSeoFYm1w).

## Notas

* Inspirado en el [gstack](https://github.com/garrytan/gstack) de Garry Tan

Hecho con 🧿 en Estambul
