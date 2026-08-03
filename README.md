*This project has been created as part of the 42 curriculum by tlaranje.*

# Inception

## Description

Inception is a system administration project whose goal is to build a small
containerized infrastructure using Docker Compose. It sets up three services,
each in its own container built from a custom Dockerfile:

- **NGINX** — reverse proxy, sole entrypoint to the infrastructure, TLSv1.2/1.3 only.
- **WordPress + php-fpm** — the CMS application logic, no web server bundled.
- **MariaDB** — the database engine backing WordPress.

Data persistence is handled through two Docker named volumes (database and
website files), both bind to `/home/tlaranje/data` on the host. All containers
communicate over a dedicated bridge network (`inception`).

## Instructions

```bash
# clone the repo, then from the project root:
make            # prepares data dirs and builds/starts all containers
make down       # stops and removes the containers
make re         # full rebuild from scratch
```

Before the first `make`, fill in real values in `secrets/*.txt` (see
`DEV_DOC.md`), and make sure `tlaranje.42.fr` resolves to your VM's IP
(e.g. via `/etc/hosts`).

Visit `https://tlaranje.42.fr` in your browser once the stack is up.

## Resources

- Docker official docs: https://docs.docker.com/
- Docker Compose file reference: https://docs.docker.com/compose/compose-file/
- WP-CLI documentation: https://wp-cli.org/
- MariaDB documentation: https://mariadb.com/kb/en/documentation/
- NGINX documentation: https://nginx.org/en/docs/

**AI usage:** AI assistance was used to draft the initial project
skeleton (Makefile, docker-compose.yml, Dockerfiles, entrypoint scripts, and
this documentation structure) and help with the bash scripts based on the subject requirements.

## Project description: technical choices

**Virtual Machines vs Docker**
A VM virtualizes an entire OS (its own kernel, drivers, boot process), which
is heavier and slower to start. Docker containers share the host kernel and
only isolate the userspace/process, making them much lighter and faster while
still providing process, network, and filesystem isolation — a good fit for
running several loosely-coupled services (nginx/wordpress/mariadb) on one
host. The project still runs inside a VM for isolation from the host
grading environment, but the services themselves are containerized rather
than each getting a full VM.

**Secrets vs Environment Variables**
Environment variables are convenient but are visible in `docker inspect`,
process environment listings, and can leak into logs or crash dumps. Docker
secrets are mounted as files under `/run/secrets/` inside the container,
readable only by the processes that need them, and are never persisted in
the image layers. In this project, non-sensitive configuration (domain name,
DB name, usernames) lives in `.env`, while all passwords live in
`secrets/*.txt`, read at container startup.

**Docker Network vs Host Network**
`network: host` would remove network isolation entirely, exposing every
container port directly on the host and making inter-container DNS
resolution by service name unavailable. A dedicated bridge network
(`inception`) keeps containers isolated from the host network, lets them
resolve each other by service name (`wordpress`, `mariadb`), and only exposes
the one port that must be public (443, on nginx).

**Docker Volumes vs Bind Mounts**
Named volumes are managed by Docker, have a lifecycle independent of any one
host path convention, and are the recommended way to persist container data.
Bind mounts tie a container directly to a specific host path with the host's
raw permissions model, which is more fragile and harder to reason about
across environments. The subject requires named volumes; here they are
configured with the `local` driver bound to `/home/tlaranje/data` via
`driver_opts`, satisfying both the "named volume" requirement and the "data
must live at that path" requirement.
