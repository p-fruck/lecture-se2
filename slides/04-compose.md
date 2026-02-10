---
title: "Software Engineering II: **IaC: Docker Compose & more**"
author: Philipp Fruck
theme:
  path: ../themes/dhbw_dark.yml
options:
  end_slide_shorthand: true
---

Podman Network Setup
===

TODO:

- Podman 5.X: default network: pasta
  - Host network, host IP, sees source IP
- Previous default: bridge
  - Still default when connecting containers via network
  - natting happens
  - IPv6: Interesting... Sometimes broken

How to share network
- Pod: Share network namespace, reach each pther via localhost
- Bridge: Connect bridged containers

---
Podman: Connecting Services
===

The following script spawn a postgres client and server and connects them through a custom network

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
- Easy setup of two postgres instances
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
| File format       | Custom (compose)               | systemd / kubernetes |

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
- Allows parallel operation (image pulls etc)

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
Compose: Environment
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
Compose: Network
===

TODO

- default network
- multiple network
- network mode
- sidecars

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
  - `client` should only exececute the query and exit
<!-- column: 1 -->
Use a `.env` file like this to share variables between the two containers:
```bash
POSTGRES_VERSION=18-alpine
POSTGRES_PASSWORD=s3cr3t
```

---
Compose: Lifecycle
===

---
Quadlets
===

TODO: Let's see if we get here...

---
Thank you for your attention!

Don't forget the feedback
