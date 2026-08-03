# User Documentation

## What services does the stack provide?

- A WordPress website, reachable at `https://tlaranje.42.fr`.
- A WordPress administration panel at `https://tlaranje.42.fr/wp-admin`.
- A MariaDB database, used internally by WordPress (not exposed to the host).

## Starting and stopping the project

From the project root, the Makefile only exposes these targets:

```bash
make        # creates data dirs and runs docker compose up --build -d
make clean  # docker compose down (stops and removes the containers)
make fclean # clean + docker system prune -af --volumes + removes host data dir
make re     # fclean then make (full rebuild from a clean state)
```

There are no separate `stop`/`start`/`status` targets. To simply stop the
containers without deleting data, use the underlying compose command
directly:

```bash
docker compose -f srcs/docker-compose.yml stop
docker compose -f srcs/docker-compose.yml start
```

## Accessing the website and admin panel

1. Make sure `tlaranje.42.fr` resolves to your VM's IP address (add it to
   `/etc/hosts` on the machine you're browsing from if needed).
2. Open `https://tlaranje.42.fr` — your browser will warn about the
   self-signed certificate; accept/continue to proceed.
3. Log in to the admin panel at `https://tlaranje.42.fr/wp-admin` using the
   administrator account (see below for where credentials live).

## Locating and managing credentials

- Non-sensitive settings (domain, DB name, usernames) are in `srcs/.env`.
- Passwords are in `secrets/`, one file per password:
  - `secrets/db_root_password.txt` — MariaDB root password.
  - `secrets/db_password.txt` — MariaDB application user password.
  - `secrets/wp_admin_password.txt` — WordPress administrator password.
  - `secrets/wp_user_password.txt` — WordPress regular user password.

These files are not committed to Git. Update them before the first `make`
if you want custom passwords; the usernames themselves (`WORDPRESS_ADMIN_USER`,
`WORDPRESS_USER`) are set in `srcs/.env`.

## Checking that the services are running correctly

There's no `make status`/`make logs` target, so use Docker Compose directly:

```bash
docker compose -f srcs/docker-compose.yml ps      # container state (Up/Exit/Restarting)
docker logs nginx
docker logs wordpress
docker logs mariadb
```

All three containers should show as `Up`. If one keeps restarting, check its
logs for the reason (commonly: wrong DB credentials or the DB not yet ready).