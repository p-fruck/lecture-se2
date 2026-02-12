---
title: "Software Engineering II: **(Docker/Podman) Compose**"
author: Philipp Fruck
theme:
  path: ../themes/dhbw_dark.yml
options:
  end_slide_shorthand: true
---

Podman Network Setup
===

# How does rootless networking work?
- Podman 5.X: `pasta` as default network driver
  - Behaves like application is running on the host
  - Host IP, correct source IP, but still isolated
    - Port forwarding is required compared to host networking
- Previous default: `bridge` driver
  - Still default when connecting containers via shared network
  - NAT is used -> Source IP is always the NAT IP
  - IPv6: Interesting... Sometimes broken
<!-- pause -->
Q: How can two pods access each other over the network?
<!-- pause -->
- Pod: Share network namespace, reach each other via localhost
<!-- pause -->
- Bridge: Connect containers to bridged network, both gain a NATed IP

---
Podman: Connecting Services
===

The following script spawn a Postgres client and server and connects them through a custom network

```file +exec +line_numbers +id:manual.sh
path: ../examples/compose/manual.sh
language: bash
```

---
Podman: Connecting Services
===

<!-- snippet_output: manual.sh -->

---
Podman: Connecting Services
===

<!-- column_layout: [1, 1] -->
<!-- column: 0 -->
# Shell Script Approach
Do you like the manual setup?
- Easy setup of two Postgres instances
  - Can communicate over network
  - Includes DNS resolution -> Nice!
<!-- pause -->
But:
- Verbose syntax
- Setup is error-prone
  - Lots of repeated custom logic
- What if one of the commands fails?

<!-- pause -->
<!-- column: 1 -->
## Goal
- Meta file containing setup instructions
  - More declarative than shell script
  - Better error handling
  - Cross platform
<!-- pause -->
- Lifecycle handling?
  - Autostart?
  - Restart after crash?
  - Automatic updates??

---
Declarative Definition
===

We can use `docker-compose` and Quadlets for declarative definition

This can be seen as a subset of Infrastructure as Code

<!-- column_layout: [1,8,1] -->
<!-- column: 1 -->
|                   | docker-compose                 | Quadlet              |
|-------------------|--------------------------------|----------------------|
| Requirements      | Docker/Podman + Compose Script | Podman + systemd     |
| Lifecycle Manager | Docker Daemon                  | systemd              |
| Recommended for   | Development (project-level)    | Servers (host-level) |
| File format       | Custom (compose)               | systemd / Kubernetes |

---
Docker vs Podman Compose
===

There are two major implementation of the [compose spec](https://compose-spec.io)
<!-- column_layout: [1,1] -->
<!-- column: 0 -->
# Docker Compose

- Reference implementation (Docker 1st party)
  - Always supports full feature set
- Utilizes Docker socket ("REST" API)
- Allows parallel operation (image pulls etc.)

<!-- column: 1 -->
# Podman Compose
- Community implementation for Podman
- Translates compose file into `podman` CLI commands
- Sequential operation (last time I checked)

<!-- reset_layout -->
<!-- pause -->
<!-- column_layout: [1,1] -->
<!-- column: 0 -->
- v1: Standalone Script `docker-compose`
- v2: Plugin for Docker `docker compose`

<!-- column: 1 -->
- Standalone Script `podman-compose`
<!-- reset_layout -->

---
Docker Compose + Podman
===

We want to use Docker Compose with Podman

- v2 can still be used as standalone script
  - Many distros only ship v1.X though...
  - Ensure your distro ships `docker-compose` v2.X or install directly from GitHub Releases
    - `docker-compose --version`
<!-- pause -->
- We need to enable the Podman Socket for Docker API support
  - `systemctl --user enable --now podman.socket`
<!-- pause -->
- We need to tell `docker-compose` the path of our API socket!
  - `export DOCKER_HOST=unix://${XDG_RUNTIME_DIR}/podman/podman.sock`
  - Add this to your `~/.bashrc` or similar

<!-- reset_layout -->
<!-- pause -->
All slides in this lecture assume this `docker-compose` + `podman` setup. If you use another setup, you need to replace the `docker-compose` commands (officially legacy) with `docker compose` or `podman-compose`.

---
Compose: Simple Example
===
<!-- column_layout: [4,7] -->
<!-- column: 0 -->
# Compose Spec
- Simple YAML file (Minimal Syntax)
- All container under `services`
  - `web`: Implicit container name
- Declarative definition of CLI parameters
<!-- column: 1 -->
```file +line_numbers
path: ../examples/compose/compose.simple.yml
language: yaml
```
<!-- reset_layout -->
- Launching: `docker-compose -f examples/compose/compose.simple.yml up`
  - Relative paths are read from compose file
  - `compose.yml` and `docker-compose.yml` (and `.yaml`) are automatically detected --> no `-f`

---
Compose: Subcommands
===

<!-- column_layout: [8,7] -->
<!-- column: 0 -->
| Command   | Action                                   |
|-----------|------------------------------------------|
| `config`  | Parse and show the final config          |
| `pull`    | Pull service images                      |
| `build`   | Build or rebuild services if required    |
| `create`  | Creates the containers & networks        |
| `start`   | Start services (must be created first)   |
| `restart` | Restart services                         |
| `up`      | Shortcut for create and `start`          |
| `stop`    | Shutdown all services (keep containers)  |
| `down`    | Stop and remove containers & networks    |
| `logs`    | View output from containers              |
| `exec`    | Execute command in running container     |
| `run`     | Execute command in a new container       |
| `watch`   | Watch service, refresh when files change |

<!-- column: 1 -->
<!-- pause -->
Subcommands can be executed for all containers (default) or for a specific container
- `docker-compose [up/down/logs] myservice`
  - Use `up -d` to detach the logs
- Use `logs -f` to stream updated logs
- Use `up --build` for a `build` shortcut
- Use `run --rm` to prevent zombies

---
Compose: More Syntax
===
<!-- column_layout: [2,3] -->
<!-- column: 0 -->
```file +line_numbers +no_background
path: ../examples/compose/compose.syntax.yml
language: yaml
```
<!-- column: 1 -->
We can specify any container option in the compose file

- Build the service `app` from local `Containerfile` in directory `.`
- When using `Dockerfile` in same folder, `build .` is sufficient
  - Remember: No automatic rebuilds!

<!-- pause -->
## Naming

- COMPOSE_PROJECT_NAME: Parent folder of the compose file, e.g. `compose`
  - Can be overridden (environment or top-level `name:`)
- `container_name` sets explicit name `demo-app` instead of `compose-app-1`

---
Compose: Variables
===
<!-- column_layout: [3,4] -->
<!-- column: 0 -->

```file +line_numbers +no_background
path: ../examples/compose/compose.env.yml
language: yaml
```
<!-- column: 1 -->
# Variables
- Compose reads current environment and parses `.env` file relative to compose file
- Variable must be passed to containers explicitly
# Substitution

| Syntax          | Evaluates To                        |
|-----------------|-------------------------------------|
| `${VAR}`        | Value of `VAR`                      |
| ${VAR:-default} | Value of `VAR`, otherwise `default` |
| `${VAR:?error}` | Require VAR or throw error          |
<!-- pause -->
---
Compose: Variables
===
<!-- column_layout: [3,4] -->
<!-- column: 0 -->

```file +line_numbers +no_background
path: ../examples/compose/compose.env.yml
language: yaml
```

```bash +no_background
# ../examples/compose/.env
MYPASSWORD=s3cr3t
```

<!-- column: 1 -->
```bash +exec
file=../examples/compose/compose.env.yml
docker-compose -f $file config | grep -A2 environment
```

---
Compose: Network
===

<!-- column_layout: [3,4] -->
<!-- column: 0 -->

```file +line_numbers +no_background
path: ../examples/compose/compose.networks.yml
language: yaml
```
<!-- column: 1 -->

# Config

- Compose creates a default project network
  - Each container has implicit default network
- Custom networks can be created under `networks:`
  - Simple name is sufficient
  - Advanced options like subnet and network driver can be specified
<!-- pause -->
- Bridged networks support DNS for container names
  - E.g. `backend` can reach `db` via `db` hostname
  - Ensure Aardvark DNS plugin is installed!

---
Exercise
===

Remember the script from the beginning? Your task is to reproduce this using a compose file!

The script is located in the `git` repo under `../examples/compose/manual.sh`

<!-- column_layout: [1,1] -->
<!-- column: 0 -->
- Spawn two Postgres containers
  - `client` and `server`
  - `server` should keep running (daemon)
  - `client` should only execute the query and exit
<!-- column: 1 -->
Use a `.env` file like this to share variables between the two containers:
```bash
POSTGRES_VERSION=18-alpine
POSTGRES_PASSWORD=s3cr3t
```

---
Compose: Advanced Network
===
<!-- column_layout: [1,1] -->
<!-- column: 0 -->

```file +line_numbers +no_background
path: ../examples/compose/compose.network_mode.yml
language: yaml
```
<!-- column: 1 -->
As mentioned, source IP handling can be difficult with rootless networking
- Other network modes than `bridge` can be used
  - No support for DNS resolution!
- To get source IPs with bridge network:
  - Look into [socket activation](https://systemd.io/DAEMON_SOCKET_ACTIVATION)

---
Compose: Sidecars
===

<!-- column_layout: [1,1] -->
<!-- column: 0 -->
In K8s (or Pods in general) there is the "Sidecar" pattern:
- Shared network namespace between containers
- Can reach each other via localhost
- Problem: No native Docker support for Pods
<!-- pause -->
  - We can still share the network
  - Ports must be exposed from main service
  - Funny issues when starting/deleting containers
<!-- column: 1 -->
```file +line_numbers +no_background
path: ../examples/compose/compose.sidecar.yml
language: yaml
```

---
Compose: Anchors
===

<!-- column_layout: [3,4] -->
<!-- column: 0 -->
```file +line_numbers +no_background
path: ../examples/compose/compose.anchors.yml
language: yaml
```
<!-- column: 1 -->
- YAML anchors can be used to reuse config
- Can be placed anywhere in the file
  - Use top-level `x-` attributes for config snippets (no invalid syntax errors)
<!-- pause -->
- Advantage: Ensure consistent config
- Disadvantage: Harder to read

---
Compose: Healthcheck & Dependencies
===
<!-- column_layout: [3,4] -->
<!-- column: 0 -->
```file +line_numbers +no_background
path: ../examples/compose/compose.healthcheck.yml
language: yaml
```
<!-- column: 1 -->
- We can define a startup order between services
  - `depends_on` with multiple conditions
  - `service_running`: Wait for service to start
  - `service_healthy`: Wait for health check
<!-- pause -->
- Healthchecks...
  - can be specified on image level
  - can be overridden by compose
  - run inside the container
  - use `CMD` or `CMD-SHELL`
    - array or string notation

---
Compose: Profiles
===
<!-- column_layout: [3,4] -->
<!-- column: 0 -->
```file +line_numbers +no_background
path: ../examples/compose/compose.profiles.yml
language: yaml
```

<!-- column: 1 -->
# Separating larger applications

- Profiles can be used to divide complex setups
- Each service can be added to multiple profiles
- Use `docker-compose --profile db up` to spawn db
  - Use multiple --profile flags for `web` + `app`
  - Or: Use `COMPOSE_PROFILES=web,app` environment

---
Compose: File based separation
===
<!-- column_layout: [1,1] -->
<!-- column: 0 -->
# Include

- The `include` directive can be used to import content from other compose files
  - Simple, declarative way if files get too large

<!-- column: 1 -->
```file +line_numbers +no_background
path: ../examples/compose/compose.include.yml
language: yaml
```
<!-- reset_layout -->
<!-- column_layout: [1,1] -->
<!-- column: 0 -->
<!-- pause -->
# Multiple files via CLI
- We can also specify multiple files via CLI
- Useful if we use tooling around compose
  - E.g. conditionally include files
- `docker-compose -f file1 -f file2`
- Each file overrides contents of previous files
  - Objects (lists, dicts) get merged

<!-- column: 1 -->
```bash +exec
file=../examples/compose/compose.include.yml
docker-compose -f $file config --services
```

---
Thank you for your attention!

Don't forget the feedback
