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
   echo "StrongFtpPass!"     > secrets/ftp_password.txt
   ```

   `credentials.txt` format: line 1 = WP admin password, line 2 = WP editor password.

3. **Review `srcs/.env`** — all tunable settings live here (domain, service ports, DB name/user, WP usernames/emails, PHP/Redis memory). See [Tunable settings](#tunable-settings).

4. **Build and launch:**

   ```sh
   make
   ```

   This creates `/home/ngusev/data/{mariadb,wordpress}` on the host, then runs `docker compose up -d --build`.

## Build and management commands

| Command | Effect |
|---|---|
| `make` (`all`) | Create data dirs, build images, start the stack |
| `make up` | Start containers without rebuilding (all, or `S=<service>`) |
| `make down` | Stop and remove all containers (volumes intact) |
| `make stop` | Stop container(s) without removing (all, or `S=<service>`) |
| `make rebuild` | Rebuild + restart with `--no-deps` (all, or `S=<service>`) |
| `make re` | `fclean` then full build |
| `make clean` | `down` + `docker system prune -af` |
| `make fclean` | `down -v --remove-orphans`, prune images, delete host data dirs |
| `make logs` | Follow all container logs |
| `make ps` | Show container status |

The `up`, `stop`, and `rebuild` targets take an optional service selector `S=<service>`
to act on a single container instead of the whole stack — e.g. `make rebuild S=wordpress`,
`make stop S=nginx`, `make up S=flask`. Leave `S` empty to target all containers.

## Container management

```sh
docker compose -f srcs/docker-compose.yml ps
docker exec -it mariadb  mariadb -u root -p
docker exec -it -w /var/www/html wordpress wp --allow-root plugin list
docker exec -it redis    redis-cli info server
docker exec -it ftp      ls -la /var/www/html
docker exec -it netdata  netdata -v
```

Rebuild a single container (only when its Dockerfile/scripts/templates change):

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env up -d --build wordpress
```

## Tunable settings

```sh
# if edit srcs/.env, no --build is required:
docker compose -f srcs/docker-compose.yml --env-file srcs/.env up -d
```

| Variable | Default | |
|---|---|---|
| `DOMAIN_NAME` | `ngusev.42.fr` | TLS CN + site URL |
| `NGINX_PORT` | `443` | public HTTPS port |
| `MYSQL_DATABASE` † | `wordpress` | WordPress database name |
| `MYSQL_USER` † | `wpuser` | DB user (password in `secrets/db_password.txt`) |
| `MYSQL_PORT` | `3306` | mysqld port; WP connects here |
| `WP_ADMIN_USER` † | `ngusev_wp` | WP administrator login (must not contain `admin`) |
| `WP_ADMIN_EMAIL` † | `admin@ngusev.42.fr` | WP administrator email |
| `WP_USER` † | `ngusev_editor` | WP second user (author role) |
| `WP_USER_EMAIL` † | `editor@ngusev.42.fr` | WP second user email |
| `PHP_FPM_PORT` | `9000` | PHP-FPM port; nginx `fastcgi_pass` |
| `PHP_FPM_MAX_CHILDREN` | `5` | FPM worker cap |
| `PHP_MEMORY_LIMIT` / `PHP_UPLOAD_MAX_FILESIZE` / `PHP_POST_MAX_SIZE` | `512M` / `64M` / `64M` | PHP limits |
| `REDIS_PORT` | `6379` | Redis port; WP cache target |
| `REDIS_MAXMEMORY` / `REDIS_MAXMEMORY_POLICY` | `256mb` / `allkeys-lru` | Redis memory + eviction policy |
| `FTP_USER` | `ftpuser` | FTP login (password in `secrets/ftp_password.txt`) |
| `FTP_PORT` | `21` | FTP control port |
| `FTP_PASV_MIN` / `FTP_PASV_MAX` | `21000` / `21010` | passive data port range (published in compose) |
| `FTP_PASV_ADDRESS` | `127.0.0.1` | address advertised for passive mode; set to VM/host IP for remote access |
| `FLASK_PORT` | `8080` | Flask site port |
| `FLASK_WORKERS` | `2` | gunicorn worker processes for the Flask site |
| `ADMINER_PORT` | `8081` | Adminer port |
| `ADMINER_VERSION` | `5.4.2` | Adminer release downloaded at **build** time (compose `build.args` → Dockerfile `ARG`) |
| `NETDATA_PORT` | `19999` | Netdata dashboard port |

**† First-init only.** These are baked into the persistent volumes during the very first
`make` (DB name/user into `db_data`; WP usernames/emails into `wp_data` at `wp core install`).
Changing them afterwards has no effect until you wipe state with `make fclean && make`.

`ADMINER_VERSION` is consumed at image build, so a change needs a rebuild
(`make rebuild S=adminer`), not just a restart. Every other variable above changes live —
re-run `docker compose ... up -d` (no `--build`) to apply.

## Data persistence

| Volume | Host path | Container path |
|---|---|---|
| `db_data` | `/home/ngusev/data/mariadb` | `/var/lib/mysql` |
| `wp_data` | `/home/ngusev/data/wordpress` | `/var/www/html` (shared with `ftp`) |

Named volumes use `driver: local` with `type: none / o: bind / device:` — data sits under `/home/ngusev/data` on the host but is managed by Docker as a named volume.

## Configuration files

Config files ending in `.template` hold `${VAR}` placeholders filled from `.env`
by the container entrypoint at startup.

| File | Purpose |
|---|---|
| `srcs/.env` | All tunable settings (see [Tunable settings](#tunable-settings)) |
| `srcs/docker-compose.yml` | Service, volume, network, secret definitions |
| `srcs/requirements/nginx/conf/nginx.conf.template` | NGINX; `${DOMAIN_NAME} ${NGINX_PORT} ${PHP_FPM_PORT}` substituted |
| `srcs/requirements/mariadb/conf/mariadb-server.cnf` | MariaDB config (overrides distro default; port set via `--port` flag in `init.sh`) |
| `srcs/requirements/wordpress/conf/www.conf.template`, `php.ini.template` | PHP-FPM pool + PHP limits |
| `srcs/requirements/bonus/redis/conf/redis.conf.template` | Redis (port, maxmemory, policy) |
| `srcs/requirements/bonus/ftp/conf/vsftpd.conf.template` | vsftpd (passive range + `pasv_address`) |
| `srcs/requirements/bonus/flask/app/` | Flask app (`app.py`, templates, static, entrypoint) |

## Secrets

Secrets are mounted read-only at `/run/secrets/<name>` inside containers. They are defined in the top-level `secrets:` block of `docker-compose.yml` pointing to local text files. The files are gitignored.

## First-run initialisation logic

- **MariaDB** (`tools/init.sh`): creates `/run/mysqld` (socket dir, wiped each start). If `/var/lib/mysql/mysql` does not exist, runs `mysql_install_db`, starts mysqld without networking, creates database and user from secrets, then shuts down and re-launches with `exec mysqld --port=${MYSQL_PORT}`.
- **WordPress** (`tools/setup.sh`): renders `www.conf`/`php.ini` from env, downloads core + creates `wp-config.php` if missing, then **reconciles `DB_HOST` and Redis host/port on every start** (so port changes apply without wiping the volume), waits for MariaDB with `mariadb-admin ping -P ${MYSQL_PORT}`, runs `wp core install` + author user + Redis cache plugin if not yet installed, and finally `exec php-fpm83 -F`.
- **FTP** (`tools/entrypoint.sh`): renders `vsftpd.conf` from env, creates `${FTP_USER}` (home = `/var/www/html`) and sets its password from the `ftp_password` secret, then `chown -R ${FTP_USER}:nobody` + `chmod -R g+rwX` the shared volume so both FTP and PHP-FPM (group `nobody`) can write, and `exec vsftpd` (PID 1, `background=NO`).
- **Flask** (`app/entrypoint.sh`): `exec gunicorn --bind 0.0.0.0:${FLASK_PORT} app:app`.
- **Adminer** (`tools/entrypoint.sh`): `exec php -S 0.0.0.0:${ADMINER_PORT} -t /var/www`; `index.php` is the Adminer single-file release baked into the image.
- **Netdata** (`tools/entrypoint.sh`): installed from the Alpine `netdata` package; `exec netdata -D -p ${NETDATA_PORT}`. No persistent volume: the live dashboard needs no stored state.

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
