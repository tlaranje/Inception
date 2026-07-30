# Developer Documentation

## Setting up the environment from scratch

Prerequisites:
- A Linux VM with Docker Engine and the Docker Compose plugin installed.
- Root/sudo access (for `/home/<login>/data` and `/etc/hosts`).

Steps:
1. Clone the repository.
2. Replace every `login` placeholder with your actual 42 login in:
   `Makefile`, `srcs/docker-compose.yml`, `srcs/.env`,
   `srcs/requirements/nginx/conf/nginx.conf`,
   `srcs/requirements/nginx/tools/gen_cert.sh`.
3. Fill in real passwords in `secrets/db_password.txt`,
   `secrets/db_root_password.txt`, and `secrets/credentials.txt`
   (format: `KEY=value`, one per line, as already scaffolded).
4. Add `<login>.42.fr` to `/etc/hosts` pointing at the VM's IP.

## Building and launching with Makefile / Docker Compose

```bash
make prepare   # creates /home/<login>/data/{wordpress,mariadb}
make up        # docker compose up --build -d
```
or simply `make`, which runs both.

Under the hood, `make up` runs:
```bash
docker compose -f srcs/docker-compose.yml up --build -d
```
which builds `nginx`, `wordpress`, and `mariadb` images from their respective
`Dockerfile`s in `srcs/requirements/`, then starts the three containers on the
`inception` bridge network.

## Managing containers and volumes

```bash
make status     # docker compose ps
make logs       # follow logs for all services
make stop       # stop containers, keep them (and volumes) around
make restart    # down then up
make clean      # down + docker system prune
make fclean     # clean + remove the host data dir + associated volumes
make re         # fclean + all (full rebuild from a clean state)
```

Volume inspection:
```bash
docker volume ls | grep inception
docker volume inspect srcs_wordpress_data
docker volume inspect srcs_mariadb_data
```

## Where project data is stored and how it persists

- WordPress files (core, themes, uploads, `wp-config.php`) live in the
  `wordpress_data` named volume, bind to `/home/<login>/data/wordpress`.
- The MariaDB data directory lives in the `mariadb_data` named volume, bind
  to `/home/<login>/data/mariadb`.

Both are Docker **named volumes** (not raw bind mounts) configured with the
`local` driver and `driver_opts` pointing at those host paths — this
satisfies the subject's requirement to use named volumes while still landing
the data at a predictable, inspectable location on the host. Because the
data lives outside the containers' writable layers, `make down` / `make up`
cycles (and even image rebuilds) do not lose WordPress content or the
database — only `make fclean` removes it, deliberately.

The WordPress and MariaDB entrypoint scripts (`setup_wp.sh`, `init_db.sh`)
detect an already-initialized data directory (`wp-config.php` /
`/var/lib/mysql/mysql`) and skip first-run setup on subsequent starts, so
re-running `make up` against existing volumes is idempotent.
