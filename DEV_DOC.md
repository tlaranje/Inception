# Developer Documentation

## Setting up the environment from scratch

Prerequisites:
- A Linux VM with Docker Engine and the Docker Compose plugin installed.
- Root/sudo access (for `/home/tlaranje/data` and `/etc/hosts`).

Steps:
1. Clone the repository.
2. Fill in real passwords in `secrets/db_password.txt`,
   `secrets/db_root_password.txt`, `secrets/wp_admin_password.txt`, and
   `secrets/wp_user_password.txt` (one plaintext value per file, no `KEY=`
   prefix — the entrypoint scripts read the file content directly with
   `cat`).
3. Check/adjust the non-sensitive values in `srcs/.env` (`DOMAIN_NAME`,
   `MYSQL_DATABASE`, `MYSQL_USER`, `WORDPRESS_ADMIN_USER`,
   `WORDPRESS_ADMIN_EMAIL`, `WORDPRESS_USER`, `WORDPRESS_USER_EMAIL`,
   `WORDPRESS_TITLE`). Note `WORDPRESS_ADMIN_USER` must not contain
   "admin"/"administrator".
4. Add `tlaranje.42.fr` to `/etc/hosts` pointing at the VM's IP.

## Building and launching with Makefile / Docker Compose

The Makefile only has four targets:

```bash
make        # mkdir -p the two data dirs, then docker compose up --build -d
make clean  # docker compose down
make fclean # clean + docker system prune -af --volumes + rm -rf host data dir
make re     # fclean then make (full rebuild from a clean state)
```

Under the hood, `make` runs:
```bash
mkdir -p /home/tlaranje/data/mariadb
mkdir -p /home/tlaranje/data/wordpress
docker compose -f srcs/docker-compose.yml up --build -d
```
which builds `nginx`, `wordpress`, and `mariadb` images from their respective
`Dockerfile`s in `srcs/requirements/`, then starts the three containers on the
`inception_network` bridge network.

## Managing containers and volumes

There are no dedicated `status`/`logs`/`stop`/`restart` Makefile targets;
use Docker Compose directly for day-to-day container management:

```bash
docker compose -f srcs/docker-compose.yml ps        # container state
docker compose -f srcs/docker-compose.yml logs -f   # follow logs, all services
docker compose -f srcs/docker-compose.yml stop      # stop containers, keep volumes
docker compose -f srcs/docker-compose.yml start     # restart stopped containers
```

Volume inspection:
```bash
docker volume ls | grep inception
docker volume inspect srcs_db_data
docker volume inspect srcs_wp_data
```

To tear everything down:
```bash
make clean   # stop + remove containers (volumes and images kept)
make fclean  # also prunes images/volumes and deletes /home/tlaranje/data
```

## Where project data is stored and how it persists

- WordPress files (core, themes, uploads, `wp-config.php`) live in the
  `wp_data` named volume, bound to `/home/tlaranje/data/wordpress`.
- The MariaDB data directory lives in the `db_data` named volume, bound
  to `/home/tlaranje/data/mariadb`.

Both are Docker **named volumes** (not raw bind mounts in the compose
service definitions) configured with the `local` driver and `driver_opts`
(`type: none, o: bind`) pointing at those host paths — this satisfies the
subject's requirement to use named volumes while still landing the data at
a predictable, inspectable location on the host. Because the data lives
outside the containers' writable layers, `make clean` / `make` cycles (and
even image rebuilds) do not lose WordPress content or the database — only
`make fclean` removes it, deliberately.

The MariaDB and WordPress entrypoint scripts (both named `tools/setup.sh`
in their respective service directories) detect an already-initialized data
directory before running first-time setup (WordPress checks for
`wp-config.php`), so re-running `make` against existing volumes does not
repeat the install/configuration steps.