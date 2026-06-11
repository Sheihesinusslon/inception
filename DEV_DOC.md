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
| `srcs/requirements/mariadb/conf/50-server.cnf` | MariaDB server config |
| `srcs/requirements/wordpress/conf/www.conf` | PHP-FPM pool config |
| `srcs/requirements/bonus/redis/conf/redis.conf` | Redis config (maxmemory, policy) |

## Secrets

Secrets are mounted read-only at `/run/secrets/<name>` inside containers. They are defined in the top-level `secrets:` block of `docker-compose.yml` pointing to local text files. The files are gitignored.

## First-run initialisation logic

- **MariaDB** (`tools/init.sh`): if `/var/lib/mysql/mysql` does not exist, runs `mysql_install_db`, starts mysqld without networking, creates database and user from secrets, then shuts down and re-launches with `exec mysqld` (PID 1).
- **WordPress** (`tools/setup.sh`): if `wp-config.php` does not exist, downloads WordPress core via WP-CLI, creates config (reads DB password from secret), waits for MariaDB, runs `wp core install`, creates the editor user, installs and enables the Redis Object Cache plugin, then `exec php-fpm83 -F` (PID 1).
