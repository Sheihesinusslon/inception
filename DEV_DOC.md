# Developer Documentation

## Prerequisites

- Docker Engine ≥ 24, Docker Compose plugin v2
- `make`, `openssl`, `sudo` (for data-dir cleanup)
- Add to `/etc/hosts`: `127.0.0.1 ngusev.42.fr`

## Environment setup from scratch

1. **Clone the repo.**

2. **Create secret files** (never commit these):

   ```sh
   echo "StrongDbPass!"      > secrets/db_password.txt
   echo "StrongRootPass!"    > secrets/db_root_password.txt
   printf "AdminPass!\nEditorPass!\n" > secrets/credentials.txt
   ```

   `credentials.txt` format: line 1 = WP admin password, line 2 = WP editor password.

3. **Review `srcs/.env`** — set `DOMAIN_NAME`, `MYSQL_DATABASE`, `MYSQL_USER`, WP usernames/emails if needed.

4. **Build and launch:**

   ```sh
   make
   ```

   This creates `/home/ngusev/data/mariadb` and `/home/ngusev/data/wordpress` on the host, then runs `docker compose up -d --build`.

## Build and management commands

| Command | Effect |
|---|---|
| `make` | Build images + start stack |
| `make down` | Stop containers (volumes intact) |
| `make clean` | Stop + `docker system prune -af` |
| `make fclean` | Clean + delete host data dirs |
| `make re` | `fclean` then `make` |
| `make logs` | Follow all container logs |
| `make ps` | Show container status |

## Container management

```sh
docker compose -f srcs/docker-compose.yml ps
docker exec -it mariadb  mariadb -u root -p
docker exec -it wordpress wp --allow-root plugin list
docker exec -it redis    redis-cli info server
```

## Data persistence

| Volume | Host path | Container path |
|---|---|---|
| `db_data` | `/home/ngusev/data/mariadb` | `/var/lib/mysql` |
| `wp_data` | `/home/ngusev/data/wordpress` | `/var/www/html` |

Named volumes use `driver: local` with `type: none / o: bind / device:` — data sits under `/home/ngusev/data` on the host but is managed by Docker as a named volume.

## Configuration files

| File | Purpose |
|---|---|
| `srcs/.env` | Non-sensitive env vars (domain, db name, WP usernames) |
| `srcs/docker-compose.yml` | Service, volume, network, secret definitions |
| `srcs/requirements/nginx/conf/nginx.conf.template` | NGINX config; `${DOMAIN_NAME}` substituted at startup |
| `srcs/requirements/mariadb/conf/mariadb-server.cnf` | MariaDB server config (overrides the distro default, which disables networking) |
| `srcs/requirements/wordpress/conf/www.conf` | PHP-FPM pool config |
| `srcs/requirements/bonus/redis/conf/redis.conf` | Redis config (maxmemory, policy) |

## Secrets

Secrets are mounted read-only at `/run/secrets/<name>` inside containers. They are defined in the top-level `secrets:` block of `docker-compose.yml` pointing to local text files. The files are gitignored.

## First-run initialisation logic

- **MariaDB** (`tools/init.sh`): creates `/run/mysqld` (socket dir, wiped each start). If `/var/lib/mysql/mysql` does not exist, runs `mysql_install_db`, starts mysqld without networking, creates database and user from secrets, then shuts down and re-launches with `exec mysqld` (PID 1).
- **WordPress** (`tools/setup.sh`): each phase is idempotent — downloads core if missing, creates config (`--skip-check`, reads DB password from secret) if missing, waits for MariaDB with `mariadb-admin ping`, then runs `wp core install` + editor user + Redis Object Cache plugin if the site is not yet installed, and finally `exec php-fpm83 -F` (PID 1).

## TLS verification

NGINX is the only entry point (port 443) and must accept **only TLSv1.2 / TLSv1.3**.

```sh
# Negotiated protocol + cipher
openssl s_client -connect ngusev.42.fr:443 -servername ngusev.42.fr </dev/null 2>/dev/null \
    | grep -E "Protocol|Cipher"

# TLSv1.2 and 1.3 must succeed (expect 200)
curl -sko /dev/null -w "1.2 -> %{http_code}\n" --tlsv1.2 --tls-max 1.2 https://ngusev.42.fr
curl -sko /dev/null -w "1.3 -> %{http_code}\n" --tlsv1.3            https://ngusev.42.fr

# TLSv1.1 must fail (handshake error / 000)
curl -sko /dev/null -w "1.1 -> %{http_code}\n" --tlsv1.1 --tls-max 1.1 https://ngusev.42.fr
```

Inspect the generated certificate inside the container:

```sh
docker exec nginx openssl x509 -in /etc/nginx/ssl/nginx.crt -noout -subject -dates
```

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `mkdir: /home/ngusev: Permission denied` | Host user isn't `ngusev`; `/home` not writable | `sudo mkdir -p /home/ngusev/data && sudo chown -R $USER /home/ngusev` |
| `docker: command not found` | Docker not installed | Install Docker Engine + Compose plugin |
| MariaDB: `Bind on unix socket: No such file` | `/run/mysqld` missing (fresh tmpfs) | Handled in `init.sh`; ensure it runs before `mysqld` |
| MariaDB up but `2002 Connection refused` | Distro default forces `skip-networking` | Our `mariadb-server.cnf` overrides it (`skip-networking = 0`) |
| WordPress: `Class "Phar" not found` | WP-CLI needs the PHP `phar` extension | `php83-phar` installed in the Dockerfile |
| WordPress: `Allowed memory size ... exhausted` | PHP default `memory_limit` too low for unzip | `conf/php.ini` raises it to 512M |
| WordPress restart loop, "files already present" | Non-idempotent setup after a crash | `setup.sh` guards each phase; uses `wp config create --skip-check` |
| WordPress stuck waiting for DB forever | `wp db check` needs `mysqlcheck` (absent) | Wait with `mariadb-admin ping` (`mariadb-client` installed) |
| Need a clean slate | Stale volume data | `make fclean && make` (removes host data dirs) |
