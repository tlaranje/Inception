# User Documentation

## What services does the stack provide?

- A WordPress website, reachable at `https://<login>.42.fr`.
- A WordPress administration panel at `https://<login>.42.fr/wp-admin`.
- A MariaDB database, used internally by WordPress (not exposed to the host).

## Starting and stopping the project

From the project root:

```bash
make        # build images (if needed) and start every container
make stop   # stop the containers without removing them
make start  # start previously stopped containers
make down   # stop and remove the containers
```

## Accessing the website and admin panel

1. Make sure `<login>.42.fr` resolves to your VM's IP address (add it to
   `/etc/hosts` on the machine you're browsing from if needed).
2. Open `https://<login>.42.fr` — your browser will warn about the
   self-signed certificate; accept/continue to proceed.
3. Log in to the admin panel at `https://<login>.42.fr/wp-admin` using the
   administrator account (see below for where credentials live).

## Locating and managing credentials

- Non-sensitive settings (domain, DB name, usernames) are in `srcs/.env`.
- Passwords are in `secrets/`:
  - `secrets/db_root_password.txt` — MariaDB root password.
  - `secrets/db_password.txt` — MariaDB application user password.
  - `secrets/credentials.txt` — WordPress admin and regular user passwords.

These files are not committed to Git. Update them before the first
`make` if you want custom passwords.

## Checking that the services are running correctly

```bash
make status          # shows container state (Up/Exit/Restarting)
docker logs nginx
docker logs wordpress
docker logs mariadb
```

All three containers should show as `Up`. If one keeps restarting, check its
logs for the reason (commonly: wrong DB credentials or the DB not yet ready).
